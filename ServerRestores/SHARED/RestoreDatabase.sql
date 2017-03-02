/* MASTER DATABASE RESTORE SCRIPT - AS, DBA, JUN 2016

  * TAKES THE DATABASE NAME AND RESTORE TYPE (LIVE/DAILY/CUT/LOCAL) AS PARAMETERS VIA SQLCMD
  * TO ADD A DATABASE NAME AND RESTORE TYPE, CREATE A 'WHEN' CLAUSE IN THE 'CONFIGURATION' SECTION BELOW AND SPECIFY THE BACKUP PATH,
      E.G. WHEN N'DMS, Live' THEN N'\\ldssqlbproapp02\SQLBackup\LDSDMSPRO1DBA01\DMS\'
  * THE SCRIPT WILL THEN:
    1. LOCATE THE LATEST FULL BACKUP AND DIFFERENTIAL
    2. WORK OUT THE BASE LSNs OF THE BACKUP AND DATABASE; FOR DAILY RESTORE TYPE, IF THE BACKUP IS EARLIER, SKIP STEPS 3 TO 8
    3. DROP ANY DATABASE SNAPSHOTS
    4. IF THE DATABASE IS JOINED TO AN AVAILABILITY GROUP, REMOVE IT
    5. KILL CONNECTIONS AND PUT THE DATABASE IN SINGLE USER MODE
    6. RESTORE THE FULL BACKUP WITH NORECOVERY
    7. RESTORE THE DIFFERENTIAL, IF THERE IS ONE, WITH NORECOVERY
    8. RESTORE WITH RECOVERY AND RESTRICTED USER ACCESS
    9. BACKUP THE LOG WITH TRUNCATE ONLY (SQL 2005)
    10. SWITCH TO SIMPLE RECOVERY MODEL
    11. SHRINK THE LOG FILE TO 10% FREE SPACE

*/

SET NOCOUNT ON

BEGIN TRY

-- DECLARATIONS AND TEMP TABLES
DECLARE @DbName SYSNAME, @RestoreType NVARCHAR(10), @RestoreDir NVARCHAR(260), @DestDirDbFiles NVARCHAR(260), @DestDirLogFiles NVARCHAR(260),
	@DirFile NVARCHAR(260), @DirFileDiff NVARCHAR(260), @FileToRestore NVARCHAR(260), @FileToRestoreDiff NVARCHAR(260), @LogLogical NVARCHAR(128),
	@LogicalName NVARCHAR(128), @PhysicalName NVARCHAR(260), @Type CHAR(1), @Sql NVARCHAR(4000), @BackupDifferentialBaseLSN NUMERIC(25, 0), @DatabaseDifferentialBaseLSN NUMERIC(25, 0),
	@AvailabilityGroupName SYSNAME, @TargetSize INT, @MBRequiredDbFiles INT, @MBRequiredLogFiles INT, @MBFreeDbFiles INT, @MBFreeLogFiles INT;
IF OBJECT_ID(N'tempdb..#DbFiles', 'U') IS NOT NULL DROP TABLE #DbFiles;
CREATE TABLE #DbFiles (LogicalName NVARCHAR(128), PhysicalName NVARCHAR(260), Type CHAR(1), FileGroupName NVARCHAR(128),
	Size NUMERIC(20, 0), MaxSize NUMERIC(20, 0), FileID BIGINT, CreateLSN NUMERIC(25, 0), DropLSN NUMERIC(25, 0),
	UniqueID UNIQUEIDENTIFIER, ReadOnlyLSN NUMERIC(25, 0), ReadWriteLSN NUMERIC(25, 0), BackupSizeInBytes BIGINT,
	SourceBlockSize INT, FileGroupID INT, LogGroupGUID UNIQUEIDENTIFIER, DifferentialBaseLSN NUMERIC(25, 0),
	DifferentialBaseGUID UNIQUEIDENTIFIER, IsReadOnly BIT, IsPresent BIT);
IF (@@microsoftversion / 0x01000000) >= 10
	ALTER TABLE #DbFiles ADD TDEThumbprint VARBINARY(32);
IF OBJECT_ID(N'tempdb..#DirList', 'U') IS NOT NULL DROP TABLE #DirList;
CREATE TABLE #DirList ([Filename] NVARCHAR(260) NULL, [Depth] INT NULL, [File] INT NULL);
IF OBJECT_ID(N'tempdb..#LogSpace', 'U') IS NOT NULL DROP TABLE #LogSpace;
CREATE TABLE #LogSpace (DatabaseName SYSNAME, LogSizeMB FLOAT, LogSpaceUsedPercent FLOAT, Status INT);
IF OBJECT_ID(N'tempdb..#DriveSpace', 'U') IS NOT NULL DROP TABLE #DriveSpace;
CREATE TABLE #DriveSpace (Drive CHAR(1), MBFree INT);

-- CONFIGURATION
SET @DbName = N'$(DbName)';
SET @RestoreType = N'$(RestoreType)';
SET @RestoreDir = CASE @DbName + N', ' + @RestoreType

WHEN N'Appointments, Live' THEN                            N'\\ldssqlbproapp01\SQLBackup\LDSQMTPRO1DBA01\'
WHEN N'AssetLiability, Live' THEN                          N'\\ldssqlbproapp01\SQLBackup\VMCLUPRO0DBA01\AssetLiability\'
WHEN N'Budget, Live' THEN                                  N'\\ldssqlbproapp01\SQLBackup\VMCLUPRO0DBA01\Budget\'
WHEN N'CallTracking, Live' THEN                            N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA03\CallTracking\'
WHEN N'CallTracking_Archive, Live' THEN                    N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA03\CallTracking_Archive\'
WHEN N'CCCSIFACE, Live' THEN                               N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA02\CCCSIFACE\'
WHEN N'Client, Live' THEN                                  N'\\ldssqlbproapp01\SQLBackup\VMCLUPRO0DBA01\Client\'
WHEN N'ClientHistoryAudit, Live' THEN                      N'\\ldssqlbproapp01\SQLBackup\VMCLUPRO0DBA01\ClientHistoryAudit\'
WHEN N'ClientRetention, Live' THEN                         N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA02\ClientRetention\'
WHEN N'ClientRetention_MI, Live' THEN                      N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA02\ClientRetention_MI\'
WHEN N'ClientSolution, Live' THEN                          N'\\ldssqlbproapp01\SQLBackup\VMCLUPRO0DBA01\ClientSolution\'
WHEN N'Communications, Live' THEN                          N'\\ldssqlbproapp01\SQLBackup\VMCLUPRO0DBA01\Communications\'
WHEN N'Complaints, Live' THEN                              N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA04\Complaints\'
WHEN N'CPD, Live' THEN                                     N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA02\CPD\'
WHEN N'CPF_BACS, Live' THEN                                N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA03\CPF_BACS\'
WHEN N'CPFVABACS, Live' THEN                               N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA02\CPFVABACS\'
WHEN N'CreditReportsAudit, Live' THEN                      N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA03\CreditReportsAudit\'
WHEN N'CWS, Live' THEN                                     N'\\ldssqlbproapp01\SQLBackup\VMWEBPRO1DBA02\CWS\'
WHEN N'DCSLive, Cut' THEN                                  N'\\ldscutpro1dba01\Cutbacks\'
WHEN N'DCSLive, Daily' THEN                                N'\\ldssqlbproapp02\SQLBackup\LDSDCSPRO1DBA01\DCSLive\'
WHEN N'DCSLive, Live' THEN                                 N'\\ldssqlbproapp02\SQLBackup\LDSDCSPRO1DBA01\DCSLive\'
WHEN N'DCSLive_MI, Live' THEN                              N'\\ldssqlbproapp01\SQLBackup\LDSGENDSR1DBA01\'
WHEN N'DDValidationLogger, Live' THEN                      N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA02\DDValidationLogger\'
WHEN N'DebtRemedy_Live, Cut' THEN                          N'\\ldscutpro1dba01\Cutbacks\SQL2008\'
WHEN N'DebtRemedy_Live, Live' THEN                         N'\\ldssqlbproapp01\SQLBackup\VMWEBPRO1DBA03\DebtRemedy_Live\'
WHEN N'directdebit, Live' THEN                             N'\\ldssqlbproapp01\SQLBackup\VMWBSPRO1DBA01\directdebit\'
WHEN N'DIStaging, Daily' THEN                              N'\\ldssqlbproapp02\SQLBackup\LDSDCSPRO1DBA01\DCSLive\'
WHEN N'DIStaging, Live' THEN                               N'\\ldssqlbproapp02\SQLBackup\LDSDCSPRO1DBA01\DCSLive\'
WHEN N'DMS, Cut' THEN                                      N'\\ldscutpro1dba01\Cutbacks\'
WHEN N'DMS, Daily' THEN                                    N'\\ldssqlbproapp02\SQLBackup\LDSDMSPRO1DBA01\DMS\'
WHEN N'DMS, Live' THEN                                     N'\\ldssqlbproapp02\SQLBackup\LDSDMSPRO1DBA01\DMS\'
WHEN N'DMS_MI, Live' THEN                                  N'\\ldssqlbproapp01\SQLBackup\LDSGENDSR1DBA01\'
WHEN N'DMSArchive, Daily' THEN                             N'\\ldssqlbproapp02\SQLBackup\LDSDMSPRO1DBA01\DMS\'
WHEN N'DMSArchive, Live' THEN                              N'\\ldssqlbproapp02\SQLBackup\LDSDMSPRO1DBA01\DMS\'
WHEN N'DocuTrieve, Live' THEN                              N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA03\DocuTrieve\'
WHEN N'DotNetNuke, Live' THEN                              N'\\ldssqlbproapp01\SQLBackup\VMWEBPRO1DBA02\DotNetNuke\'
WHEN N'DROFS, Live' THEN                                   N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA03\DROFS\'
WHEN N'Erik, Live' THEN                                    N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA03\Erik\'
WHEN N'Imaging, Live' THEN                                 N'\\ldssqlbproapp01\SQLBackup\VMCLUPRO0DBA01\Imaging\'
WHEN N'ITOperations, Live' THEN                            N'\\ldssqlbproapp01\SQLBackup\VMCLUPRO0DBA01\ITOperations\'
WHEN N'IVATransfer, Live' THEN                             N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA03\IVATransfer\'
WHEN N'JUTHelpdesk, Live' THEN                             N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA03\JUTHelpdesk\'
WHEN N'Note, Live' THEN                                    N'\\ldssqlbproapp01\SQLBackup\VMCLUPRO0DBA01\Note\'
WHEN N'NoteHistoryAudit, Live' THEN                        N'\\ldssqlbproapp01\SQLBackup\VMCLUPRO0DBA01\NoteHistoryAudit\'
WHEN N'NSB.Assets.Subscriptions, Live' THEN                N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Assets.Subscriptions\'
WHEN N'NSB.Assets.Timeouts, Live' THEN                     N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Assets.Timeouts\'
WHEN N'NSB.Assets.Writer.Sagas, Live' THEN                 N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Assets.Writer.Sagas\'
WHEN N'NSB.Assets.Writer.Timeouts, Live' THEN              N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Assets.Writer.Timeouts\'
WHEN N'NSB.Bus2DCS.Timeouts, Live' THEN                    N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Bus2DCS.Timeouts\'
WHEN N'NSB.Bus2DMS.Timeouts, Live' THEN                    N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Bus2DMS.Timeouts\'
WHEN N'NSB.Client.Subscriptions, Live' THEN                N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Client.Subscriptions\'
WHEN N'NSB.Client.Timeouts, Live' THEN                     N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Client.Timeouts\'
WHEN N'NSB.Client.Writer.Sagas, Live' THEN                 N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Client.Writer.Sagas\'
WHEN N'NSB.Client.Writer.Timeouts, Live' THEN              N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Client.Writer.Timeouts\'
WHEN N'NSB.ClientSolution.Subscriptions, Live' THEN        N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.ClientSolution.Subscriptions\'
WHEN N'NSB.ClientSolution.Timeouts, Live' THEN             N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.ClientSolution.Timeouts\'
WHEN N'NSB.ClientSolution.Writer.Sagas, Live' THEN         N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.ClientSolution.Writer.Sagas\'
WHEN N'NSB.ClientSolution.Writer.Timeouts, Live' THEN      N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.ClientSolution.Writer.Timeouts\'
WHEN N'NSB.Colleague.Writer.Subscriptions, Live' THEN      N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Colleague.Writer.Subscriptions\'
WHEN N'NSB.Colleague.Writer.Timeouts, Live' THEN           N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Colleague.Writer.Timeouts\'
WHEN N'NSB.Communications.Subscriptions, Live' THEN        N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Communications.Subscriptions\'
WHEN N'NSB.Communications.Timeouts, Live' THEN             N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Communications.Timeouts\'
WHEN N'NSB.Communications.Writer.Sagas, Live' THEN         N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Communications.Writer.Sagas\'
WHEN N'NSB.Communications.Writer.Timeouts, Live' THEN      N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Communications.Writer.Timeouts\'
WHEN N'NSB.DCS.Sagas, Live' THEN                           N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.DCS.Sagas\'
WHEN N'NSB.DCS.Timeouts, Live' THEN                        N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.DCS.Timeouts\'
WHEN N'NSB.DCSBudget.Subscriptions, Live' THEN             N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.DCSBudget.Subscriptions\'
WHEN N'NSB.DCSBudget.Timeouts, Live' THEN                  N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.DCSBudget.Timeouts\'
WHEN N'NSB.DCSBudget.Writer.Sagas, Live' THEN              N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.DCSBudget.Writer.Sagas\'
WHEN N'NSB.DCSBudget.Writer.Timeouts, Live' THEN           N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.DCSBudget.Writer.Timeouts\'
WHEN N'NSB.DirectDebit.Timeouts, Live' THEN                N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.DirectDebit.Timeouts\'
WHEN N'NSB.DMS.Sagas, Live' THEN                           N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.DMS.Sagas\'
WHEN N'NSB.DMS.Timeouts, Live' THEN                        N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.DMS.Timeouts\'
WHEN N'NSB.Imaging.Subscriptions, Live' THEN               N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Imaging.Subscriptions\'
WHEN N'NSB.Imaging.Timeouts, Live' THEN                    N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Imaging.Timeouts\'
WHEN N'NSB.Imaging.Writer.Sagas, Live' THEN                N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Imaging.Writer.Sagas\'
WHEN N'NSB.Imaging.Writer.Timeouts, Live' THEN             N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Imaging.Writer.Timeouts\'
WHEN N'NSB.Notes.Bulk.Writer.Sagas, Live' THEN             N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Notes.Bulk.Writer.Sagas\'
WHEN N'NSB.Notes.Bulk.Writer.Timeouts, Live' THEN          N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Notes.Bulk.Writer.Timeouts\'
WHEN N'NSB.Notes.Subscriptions, Live' THEN                 N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Notes.Subscriptions\'
WHEN N'NSB.Notes.Timeouts, Live' THEN                      N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Notes.Timeouts\'
WHEN N'NSB.Notes.Writer.Sagas, Live' THEN                  N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Notes.Writer.Sagas\'
WHEN N'NSB.Notes.Writer.Timeouts, Live' THEN               N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Notes.Writer.Timeouts\'
WHEN N'NSB.TaskReminders.Subscriptions, Live' THEN         N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.TaskReminders.Subscriptions\'
WHEN N'NSB.TaskReminders.Timeouts, Live' THEN              N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.TaskReminders.Timeouts\'
WHEN N'NSB.TaskReminders.Writer.Sagas, Live' THEN          N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.TaskReminders.Writer.Sagas\'
WHEN N'NSB.TaskReminders.Writer.Timeouts, Live' THEN       N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.TaskReminders.Writer.Timeouts\'
WHEN N'NSB.Transport, Live' THEN                           N'\\ldssqlbproapp01\SQLBackup\VMNSBPRO0DBA01\NSB.Transport\'
WHEN N'NSB.Transport, Local' THEN                          N'\\ldssqlbdevapp01\devsqlbackup\VM01 DAILY\VM01NSBPRODBA01\NSB.Transport\'
WHEN N'PDD, Live' THEN                                     N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA02\PDD\'
WHEN N'qms, Live' THEN                                     N'\\ldssqlbproapp01\SQLBackup\LDSQMTPRO1DBA01\'
WHEN N'Reconciliation, Live' THEN                          N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA04\Reconciliation\'
WHEN N'ReportServer, Live' THEN                            N'\\ldssqlbproapp01\SQLBackup\VMRPTPRO1DBA01\ReportServer\'
WHEN N'ReportServerTempDB, Live' THEN                      N'\\ldssqlbproapp01\SQLBackup\VMRPTPRO1DBA01\ReportServerTempDB\'
WHEN N'ShoreTelECC, Live' THEN                             N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA04\ShoreTelECC\'
WHEN N'SignalR, Live' THEN                                 N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA04\SignalR\'
WHEN N'TaskReminders, Live' THEN                           N'\\ldssqlbproapp01\SQLBackup\VMCLUPRO0DBA01\TaskReminders\'
WHEN N'TCS, Daily' THEN                                    N'\\ldssqlbproapp02\SQLBackup\LDSTCSPRO1DBA01\TCS\'
WHEN N'TCS, Live' THEN
	CASE WHEN @@SERVERNAME LIKE N'%RAR%' THEN              N'\\ldssqlbproapp01\SQLBackup\VMRARPRO1DBA01\TCS\' -- RAR VERSION
	WHEN @@SERVERNAME LIKE N'%TCS%' THEN                   N'\\ldssqlbproapp02\SQLBackup\LDSTCSPRO1DBA01\TCS\'
	END
WHEN N'TCS, Local' THEN                                    N'\\ldssqlbdevapp01\devsqlbackup\VM01 DAILY\VM01TCSPRODBA01\'
WHEN N'TCS_MI, Daily' THEN                                 N'\\ldssqlbproapp02\SQLBackup\LDSTCSPRO1DBA01\TCS\'
WHEN N'TCS_MI, Live' THEN                                  N'\\ldssqlbproapp02\SQLBackup\LDSTCSPRO1DBA01\TCS\'
WHEN N'VisionBlue_Production, Live' THEN                   N'\\ldssqlbproapp01\SQLBackup\VMVBLPRO1DBA01\VisionBlue_Production\'
WHEN N'WebSeries, Live' THEN                               N'\\ldssqlbproapp01\SQLBackup\VMWBSPRO1DBA01\WebSeries\'
WHEN N'WebsiteServices, Cut' THEN                          N'\\ldscutpro1dba01\Cutbacks\SQL2008\'
WHEN N'WebsiteServices, Live' THEN
	CASE WHEN @@SERVERNAME LIKE N'%GEN%' THEN              N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA04\WebsiteServices\' -- SUBSCRIBER (INTERNAL)
	WHEN @@SERVERNAME LIKE N'%CUT%' THEN                   N'\\ldssqlbproapp01\SQLBackup\LDSGENPRO1DBA04\WebsiteServices\' -- SUBSCRIBER (INTERNAL)
	WHEN @@SERVERNAME LIKE N'%WEB%' THEN                   N'\\ldssqlbproapp01\SQLBackup\VMWEBPRO1DBA01\WebsiteServices\' -- PUBLISHER (EXTERNAL)
	END
WHEN N'Wellbeing, Live' THEN                               N'\\ldssqlbproapp01\SQLBackup\VMWEBPRO1DBA02\Wellbeing\'

END;
IF @RestoreDir IS NULL
	RAISERROR (N'''%s, %s'' is not a recognised combination of database name and restore type', 11, 1, @DbName, @RestoreType);
PRINT N'Database name is ''' + @DbName + N''', restore type is ''' + @RestoreType + N'''';
SET @DestDirDbFiles = N'$(DestDirDbFiles)';
SET @DestDirLogFiles = N'$(DestDirLogFiles)';

-- LOCATE THE LATEST FULL AND DIFFERENTIAL BACKUPS
INSERT #DirList EXEC xp_dirtree @RestoreDir, 1, 1;
SELECT TOP 1 @FileToRestore = [Filename] FROM #DirList
WHERE [File] = 1 AND LOWER([Filename]) LIKE REPLACE(LOWER(@DbName), N'_', N'/_') + N'/_backup/_%.bak' ESCAPE N'/' ORDER BY [Filename] DESC;
SELECT TOP 1 @FileToRestoreDiff = [Filename] FROM #DirList
WHERE [File] = 1 AND LOWER([Filename]) LIKE REPLACE(LOWER(@DbName), N'_', N'/_') + N'/_diff/_%.bak' ESCAPE N'/' ORDER BY [Filename] DESC;
DROP TABLE #DirList;

IF @FileToRestore IS NULL
	RAISERROR (N'Could not locate the latest full backup', 11, 1);

SET @DirFile = @RestoreDir + @FileToRestore;
SET @DirFileDiff = @RestoreDir + @FileToRestoreDiff;

INSERT #DbFiles EXEC (N'RESTORE FILELISTONLY FROM DISK = N''' + @DirFile + N'''');
SELECT @MBRequiredDbFiles = CEILING(SUM(Size) / 1048576.0) FROM #DbFiles WHERE Type = 'D';
SELECT @MBRequiredLogFiles = CEILING(SUM(Size) / 1048576.0) FROM #DbFiles WHERE Type = 'L';

-- GET THE DIFFERENTIAL BASE LSNs
SELECT @BackupDifferentialBaseLSN = DifferentialBaseLSN FROM #DbFiles WHERE FileID = 1;
SET @Sql = N'IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N''' + @DbName + N''')
	SELECT @lsn = differential_base_lsn FROM [' + @DbName + N'].sys.database_files WHERE file_id = 1';
EXEC sp_executesql @Sql, N'@lsn NUMERIC(25, 0) OUTPUT', @lsn = @DatabaseDifferentialBaseLSN OUTPUT;

SET @Sql = N'';

-- DROP DATABASE SNAPSHOTS
SELECT @Sql = @Sql + N'DROP DATABASE [' + s.name + N']
' FROM sys.databases s INNER JOIN sys.databases d ON s.source_database_id = d.database_id
WHERE d.name = @DbName
ORDER BY s.create_date DESC;

-- REMOVE FROM AVAILABILITY GROUP (SQL 2012+)
IF (@@microsoftversion / 0x01000000) >= 11
	EXEC sp_executesql N'SELECT @ag = ag.name FROM sys.dm_hadr_database_replica_states drs
INNER JOIN sys.availability_groups ag ON drs.group_id = ag.group_id
WHERE drs.database_id = DB_ID(@db)', N'@db SYSNAME, @ag SYSNAME OUTPUT', @db = @DbName, @ag = @AvailabilityGroupName OUTPUT;
IF @AvailabilityGroupName IS NOT NULL
	SET @Sql = @Sql + N'ALTER AVAILABILITY GROUP [' + @AvailabilityGroupName + N'] REMOVE DATABASE [' + @DbName + N']
';

-- COMMANDEER THE DATABASE
SET @Sql = @Sql + N'USE [master]
';
SELECT @Sql = @Sql + N'KILL ' + CAST(spid AS NVARCHAR(5)) + N'
' FROM (SELECT DISTINCT spid, dbid FROM master..sysprocesses WITH (NOLOCK)) s
WHERE dbid = DB_ID(@DbName) AND spid <> @@SPID AND EXISTS (SELECT 1 FROM sys.dm_exec_sessions WHERE spid = s.spid AND is_user_process = 1);
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @DbName)
	SET @Sql = @Sql + N'ALTER DATABASE [' + @DbName + N'] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
';

-- RESTORE THE FULL BACKUP WITH NORECOVERY
SET @Sql = @Sql + N'RESTORE DATABASE [' + @DbName + N'] FROM DISK = N''' + @DirFile + N''' WITH NORECOVERY, MOVE N';

DECLARE DbFiles CURSOR FOR SELECT LogicalName, PhysicalName, Type FROM #DbFiles;
OPEN DbFiles FETCH NEXT FROM DbFiles INTO @LogicalName, @PhysicalName, @Type;
WHILE @@FETCH_STATUS = 0
BEGIN
	IF @Type = 'D'
		SET @Sql = @Sql + N'''' + @LogicalName + N''' TO N''' + @DestDirDbFiles + @LogicalName + RIGHT(@PhysicalName, 4) + N''', MOVE N';
	ELSE IF @Type = 'L'
	BEGIN
		SET @Sql = @Sql + N'''' + @LogicalName + N''' TO N''' + @DestDirLogFiles + @LogicalName + RIGHT(@PhysicalName, 4) + N'''';
		SET @LogLogical = @LogicalName;
	END
	FETCH NEXT FROM DbFiles INTO @LogicalName, @PhysicalName, @Type;
END
CLOSE DbFiles;
DEALLOCATE DbFiles;
DELETE FROM #DbFiles;
SET @Sql = @Sql + N', REPLACE
';

-- RESTORE THE DIFFERENTIAL BACKUP (IF APPLICABLE) WITH NORECOVERY
IF @DirFileDiff IS NOT NULL AND RIGHT(@DirFileDiff, 21) > RIGHT(@DirFile, 21)
BEGIN

INSERT #DbFiles EXEC (N'RESTORE FILELISTONLY FROM DISK = N''' + @DirFileDiff + N'''');
SELECT @MBRequiredDbFiles = CASE WHEN CEILING(SUM(Size) / 1048576.0) > @MBRequiredDbFiles THEN CEILING(SUM(Size) / 1048576.0) ELSE @MBRequiredDbFiles END FROM #DbFiles WHERE Type = 'D';
SELECT @MBRequiredLogFiles = CASE WHEN CEILING(SUM(Size) / 1048576.0) > @MBRequiredLogFiles THEN CEILING(SUM(Size) / 1048576.0) ELSE @MBRequiredLogFiles END FROM #DbFiles WHERE Type = 'L';

SET @Sql = @Sql + N'RESTORE DATABASE [' + @DbName + N'] FROM DISK = N''' + @DirFileDiff + N''' WITH NORECOVERY, MOVE N';

DECLARE DbFiles CURSOR FOR SELECT LogicalName, PhysicalName, Type FROM #DbFiles;
OPEN DbFiles FETCH NEXT FROM DbFiles INTO @LogicalName, @PhysicalName, @Type;
WHILE @@FETCH_STATUS = 0
BEGIN
	IF @Type = 'D'
		SET @Sql = @Sql + N'''' + @LogicalName + N''' TO N''' + @DestDirDbFiles + @LogicalName + RIGHT(@PhysicalName, 4) + N''', MOVE N';
	ELSE IF @Type = 'L'
	BEGIN
		SET @Sql = @Sql + N'''' + @LogicalName + N''' TO N''' + @DestDirLogFiles + @LogicalName + RIGHT(@PhysicalName, 4) + N'''';
	END
	FETCH NEXT FROM DbFiles INTO @LogicalName, @PhysicalName, @Type;
END
CLOSE DbFiles;
DEALLOCATE DbFiles;
DELETE FROM #DbFiles;
SET @Sql = @Sql + N'
';

END

-- RESTORE THE DATABASE WITH RECOVERY AND RESTRICTED USER ACCESS
SET @Sql = @Sql + N'RESTORE DATABASE [' + @DbName + N'] WITH RESTRICTED_USER, RECOVERY
';

PRINT N'Full backup path is ''' + @DirFile + N'''';
IF @DirFileDiff IS NOT NULL AND RIGHT(@DirFileDiff, 21) > RIGHT(@DirFile, 21)
	PRINT N'Differential backup path is ''' + @DirFileDiff + N'''';
IF @RestoreType = N'Daily'
BEGIN
	PRINT N'Backup differential base LSN is ' + CAST(@BackupDifferentialBaseLSN AS NVARCHAR(30));
	IF @DatabaseDifferentialBaseLSN IS NOT NULL
		PRINT N'Database differential base LSN is ' + CAST(@DatabaseDifferentialBaseLSN AS NVARCHAR(30));
END

-- EXECUTE IF:
--   * THE RESTORE TYPE IS NOT DAILY, OR
--   * THE BACKUP'S DIFFERENTIAL BASE LSN IS GREATER THAN OR EQUAL TO THAT OF THE DATABASE, OR
--   * THE DATABASE DOESN'T EXIST
-- THE DIFFERENTIAL BASE LSN OF THE DATABASE REMAINS THE SAME FROM THE POINT OF RESTORE WHEN IN SIMPLE RECOVERY MODEL
-- A SUCCESSFUL SAN SNAPSHOT WILL HAVE A DIFFERENTIAL BASE LSN THAT IS GREATER THAN THAT OF THE BACKUP
IF @RestoreType != N'Daily' OR @BackupDifferentialBaseLSN >= @DatabaseDifferentialBaseLSN OR @DatabaseDifferentialBaseLSN IS NULL
BEGIN
	-- THE RESTORE STATEMENT'S ERROR MESSAGES CONTAIN USEFUL INFORMATION WHEN IT FAILS DUE TO INSUFFICIENT DISK SPACE,
	-- HOWEVER IT'S NOT POSSIBLE TO 'THROW' ALL THE MESSAGES INTO THE CATCH BLOCK BEFORE SQL 2012, SO WE'LL HANDLE THIS OURSELVES
	INSERT #DriveSpace EXEC master..xp_fixeddrives;
	SELECT @MBFreeDbFiles = MBFree FROM #DriveSpace WHERE Drive = LEFT(@DestDirDbFiles, 1);
	SELECT @MBFreeLogFiles = MBFree FROM #DriveSpace WHERE Drive = LEFT(@DestDirLogFiles, 1);
	SELECT @MBFreeDbFiles = @MBFreeDbFiles + ISNULL(SUM(CAST(size AS BIGINT) * 8 / 1024), 0)
	FROM sys.master_files WHERE database_id = DB_ID(@DbName) AND LEFT(physical_name, 1) = LEFT(@DestDirDbFiles, 1);
	SELECT @MBFreeLogFiles = @MBFreeLogFiles + ISNULL(SUM(CAST(size AS BIGINT) * 8 / 1024), 0)
	FROM sys.master_files WHERE database_id = DB_ID(@DbName) AND LEFT(physical_name, 1) = LEFT(@DestDirLogFiles, 1);
	IF LEFT(@DestDirDbFiles, 1) = LEFT(@DestDirLogFiles, 1)
	BEGIN
		PRINT N'Required space on disk volume ' + LEFT(@DestDirDbFiles, 3) + N' is ' + CAST((@MBRequiredDbFiles + @MBRequiredLogFiles) AS NVARCHAR(10)) + N' MB (' + CAST(CAST((@MBRequiredDbFiles + @MBRequiredLogFiles) / 1024.0 AS NUMERIC(5, 2)) AS NVARCHAR(10)) + N' GB)';
		PRINT N'Available space on disk volume ' + LEFT(@DestDirDbFiles, 3) + N' is ' + CAST(@MBFreeDbFiles AS NVARCHAR(10)) + N' MB (' + CAST(CAST(@MBFreeDbFiles / 1024.0 AS NUMERIC(5, 2)) AS NVARCHAR(10)) + N' GB)';
	END
	ELSE
	BEGIN
		PRINT N'Required space on disk volume ' + LEFT(@DestDirDbFiles, 3) + N' is ' + CAST(@MBRequiredDbFiles AS NVARCHAR(10)) + N' MB (' + CAST(CAST(@MBRequiredDbFiles / 1024.0 AS NUMERIC(5, 2)) AS NVARCHAR(10)) + N' GB)';
		PRINT N'Available space on disk volume ' + LEFT(@DestDirDbFiles, 3) + N' is ' + CAST(@MBFreeDbFiles AS NVARCHAR(10)) + N' MB (' + CAST(CAST(@MBFreeDbFiles / 1024.0 AS NUMERIC(5, 2)) AS NVARCHAR(10)) + N' GB)';
		PRINT N'Required space on disk volume ' + LEFT(@DestDirLogFiles, 3) + N' is ' + CAST(@MBRequiredLogFiles AS NVARCHAR(10)) + N' MB (' + CAST(CAST(@MBRequiredLogFiles / 1024.0 AS NUMERIC(5, 2)) AS NVARCHAR(10)) + N' GB)';
		PRINT N'Available space on disk volume ' + LEFT(@DestDirLogFiles, 3) + N' is ' + CAST(@MBFreeLogFiles AS NVARCHAR(10)) + N' MB (' + CAST(CAST(@MBFreeLogFiles / 1024.0 AS NUMERIC(5, 2)) AS NVARCHAR(10)) + N' GB)';
	END
	IF (@MBRequiredDbFiles > @MBFreeDbFiles OR @MBRequiredLogFiles > @MBFreeLogFiles OR (LEFT(@DestDirDbFiles, 1) = LEFT(@DestDirLogFiles, 1) AND (@MBRequiredDbFiles + @MBRequiredLogFiles) > @MBFreeDbFiles))
		RAISERROR (N'There is insufficient free space to restore the database', 11, 1);
	PRINT N'Executing...
' + @Sql;
	EXEC (@Sql);
END
ELSE
	PRINT N'The backup differential base LSN is earlier than that of the database';

SET @Sql = N'';

-- BACKUP THE LOG WITH TRUNCATE_ONLY (SQL 2005)
IF (@@microsoftversion / 0x01000000) = 9
SET @Sql = @Sql + N'USE [' + @DbName + N']
BACKUP LOG [' + @DbName + N'] WITH TRUNCATE_ONLY
';

-- SET THE RECOVERY MODEL TO SIMPLE
SET @Sql = @Sql + N'USE [' + @DbName + N']
ALTER DATABASE [' + @DbName + N'] SET RECOVERY SIMPLE
';

-- SHRINK THE LOG FILE TO 10% FREE SPACE
INSERT #LogSpace (DatabaseName, LogSizeMB, LogSpaceUsedPercent, Status)
EXEC (N'DBCC SQLPERF(LOGSPACE)');
SELECT @TargetSize = CEILING(1.1 * LogSpaceUsedPercent / 100 * LogSizeMB) FROM #LogSpace
WHERE DatabaseName = @DbName;
SET @Sql = @Sql + N'USE [' + @DbName + N']
DBCC SHRINKFILE([' + @LogLogical + N'], ' + CAST(ISNULL(@TargetSize, 100) AS NVARCHAR(10)) + N')
';

-- EXECUTE
PRINT N'Executing...
' + @Sql;
EXEC (@Sql);

END TRY

BEGIN CATCH

	DECLARE @ErrMsg NVARCHAR(2048);
	SET @ErrMsg = N'Restore database process failed: ' + ERROR_MESSAGE();
	RAISERROR (@ErrMsg, 11, 1);
	IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'$(DbName)')
		EXEC (N'ALTER DATABASE [$(DbName)] SET MULTI_USER WITH ROLLBACK IMMEDIATE');

END CATCH
