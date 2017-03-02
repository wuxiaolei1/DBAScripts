/*
Custom Restore Script to Rename Production VisionBlue_Production Database
*/

:on error exit
SET NOCOUNT ON;
PRINT 'Step 1 - Restore Database - Live - VisionBlue_Restore';


SET NOCOUNT ON;

--Local Variables to set according to database being restored:
DECLARE @CCCS_DB sysname ,
    @NEW_DB sysname ,
    @RestoreDir VARCHAR(100) ,
    @Suffix VARCHAR(20) ,
    @Prefix VARCHAR(20) ,
    @DestDirDbFiles NVARCHAR(200) ,
    @DestDirLogFiles NVARCHAR(200); 

SET @CCCS_DB = N'$(DbName)';
SET @NEW_DB = N'$(NEWDBNAME)';
SET @Suffix = '';
SET @Prefix = '';
SET @RestoreDir = '\\ldssqlbproapp01\SQLBackup\VMVBLPRO1DBA01\VisionBlue_Production\';
SET @DestDirDbFiles = N'$(DestDirDbFiles)';
SET @DestDirLogFiles = N'$(DestDirLogFiles)';

--Local Variables used in the process
DECLARE @dirfile VARCHAR(300) ,
    @cmd VARCHAR(600) ,
    @FileToRestore VARCHAR(100) ,
    @LogLogical VARCHAR(255) ,
    @FileListCmd VARCHAR(600) ,
    @LogicalName NVARCHAR(128) ,
    @PhysicalName NVARCHAR(260) ,
    @type CHAR(1) ,
    @sql NVARCHAR(1000);

SET @NEW_DB = @Prefix + @NEW_DB + @Suffix;

--Local Table Variables
-- Table for Directory Listing
DECLARE @DirList TABLE ( filename VARCHAR(100) );
-- Table for RESTORE FILELIST results
DECLARE @dbfiles TABLE
    (
      LogicalName NVARCHAR(128) ,
      PhysicalName NVARCHAR(260) ,
      Type CHAR(1) ,
      FileGroupName NVARCHAR(128) ,
      Size NUMERIC(20, 0) ,
      MaxSize NUMERIC(20, 0) ,
      FileId INT ,
      CreateLSN NUMERIC(25, 0) ,
      DropLSN NUMERIC(25, 0) ,
      UniqueId UNIQUEIDENTIFIER ,
      ReadOnlyLSN NUMERIC(25, 0) ,
      ReadWriteLSN NUMERIC(25, 0) ,
      BackupSizeInBytes BIGINT ,
      SourceBlockSize INT ,
      FilegroupId INT ,
      LogGroupGUID CHAR(100) --Should be UNIQUEIDENTIFIER (NULL in result set not handled by RedGate DLL, implicit conversion to Char is ok)
      ,
      DifferentialBaseLSN NUMERIC(25) ,
      DifferentialBaseGUID UNIQUEIDENTIFIER ,
      IsReadOnly INT ,
      IsPresent INT ,
      TDEThumbprint VARBINARY(32)
    ); 

--Enable xp_cmdshell
EXEC [sys].[sp_configure] 'show advanced options', 1;
RECONFIGURE;
EXEC [sys].[sp_configure] 'xp_cmdshell', 1;
RECONFIGURE;

-- Read filesystem to retrieve most recent backup
SET @cmd = 'dir /b /o-d /o-g "' + @RestoreDir + '"';
INSERT  @DirList
        EXEC master..xp_cmdshell @cmd;  
-- Reads Top Record and Stores filename in a variable
SELECT TOP 1
        @FileToRestore = filename
FROM    @DirList
WHERE   filename LIKE '%' + @CCCS_DB + '_backup%'
        AND filename LIKE '%.bak%';

-- Disable the feature.
EXEC [sys].[sp_configure] 'xp_cmdshell', 0;
RECONFIGURE;
EXEC [sys].[sp_configure] 'show advanced options', 0;
RECONFIGURE;

SET @dirfile = @RestoreDir + @FileToRestore; 
--SELECT @dirfile

INSERT  @dbfiles
        EXEC ( 'RESTORE FILELISTONLY FROM disk = ''' + @dirfile + ''''
            );

DECLARE dbfiles CURSOR
FOR
    SELECT  LogicalName ,
            PhysicalName ,
            Type
    FROM    @dbfiles; 

--Construct the RESTORE Command
SET @sql = 'RESTORE DATABASE ' + @NEW_DB + ' FROM DISK = ''' + @dirfile
    + ''' WITH RESTRICTED_USER, MOVE ';

OPEN dbfiles;
FETCH NEXT FROM dbfiles INTO @LogicalName, @PhysicalName, @type;
--For each database file that the database uses
WHILE @@FETCH_STATUS = 0
    BEGIN
	--Include the prefixes:
        IF @type = 'D'
            SET @sql = @sql + '''' + @LogicalName + ''' TO '''
                + @DestDirDbFiles + @Prefix + @LogicalName + @Suffix
                + RIGHT(@PhysicalName, 4) + ''', MOVE ';
        ELSE
            IF @type = 'L'
                BEGIN
                    SET @sql = @sql + '''' + @LogicalName + ''' TO '''
                        + @DestDirLogFiles + @Prefix + @LogicalName + @Suffix
                        + RIGHT(@PhysicalName, 4) + '''';
                    SET @LogLogical = @LogicalName;
                END;
        FETCH NEXT FROM dbfiles INTO @LogicalName, @PhysicalName, @type;
    END;
CLOSE dbfiles; 
DEALLOCATE dbfiles; 

SET @sql = @sql + ', REPLACE';

-- View the full restore command
--select @sql

EXEC [SystemsHelpDesk].[dbo].[sp_killconnections] @NEW_DB, '', '';

EXEC(@sql);

EXEC (' USE ' + @NEW_DB + ' ALTER DATABASE ' + @NEW_DB + ' SET RECOVERY SIMPLE');

EXEC (' USE ' + @NEW_DB + ' dbcc shrinkfile([' + @LogLogical + '], 1000)');

/*Shrink the Database */
DECLARE @GroupID SMALLINT;
DECLARE @DBLogicalName NCHAR(128);
DECLARE @SizeofFileGroup INT;
DECLARE @filename NCHAR(260);

DECLARE dbfiles CURSOR
FOR
    SELECT  name DBLogicalName ,
            groupid ,
            filename
    FROM    [sys].[sysfiles];

OPEN dbfiles;
FETCH NEXT FROM dbfiles INTO @DBLogicalName, @GroupID, @filename;
--For each database file that the database uses
WHILE @@FETCH_STATUS = 0
    BEGIN
	--IF RIGHT(RTRIM(@filename), 3) = 'ldf'
        IF FILEPROPERTY(@DBLogicalName, 'IsLogFile') = 1
            BEGIN
                SET @SizeofFileGroup = 1000;
                SELECT  @DBLogicalName ,
                        @SizeofFileGroup;
		--exec ('dbcc shrinkfile(' + @DBLogicalName + ', ' + @SizeofFileGroup + ')')
            END;
        ELSE
            BEGIN
		--SET @SizeofFileGroup = 1.1 * ((select sum(dpages * 8) from sysindexes where groupid = @GroupID) / 1024)
                SET @SizeofFileGroup = 1.1 * ( FILEPROPERTY(@DBLogicalName,
                                                            'SpaceUsed') ) * 8
                    / 1024;
		--select @DBLogicalName, @SizeofFileGroup
		--exec ('dbcc shrinkfile(' + @DBLogicalName + ', ' + @SizeofFileGroup + ')')
            END;

        FETCH NEXT FROM dbfiles INTO @DBLogicalName, @GroupID, @filename;
    END;
CLOSE dbfiles; 
DEALLOCATE dbfiles;
GO


GO
[sys].[sp_configure] 'show advanced options', 1;
GO
RECONFIGURE;
GO
[sys].[sp_configure] 'Database Mail XPs', 0;
GO
RECONFIGURE;
GO