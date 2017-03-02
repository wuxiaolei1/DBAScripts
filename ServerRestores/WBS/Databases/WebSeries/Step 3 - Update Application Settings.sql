
/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 3 - Update Application Settings .sql"

--- */
PRINT 'Step 3 - Update Application Settings - WebSeries'

USE WebSeries

DECLARE @ProdServerFolderPath VARCHAR(55) = '\\VMWBSPRO1APP01\WebSeries Live\'
DECLARE @DailyServerFolderPath VARCHAR(55) = '\\VM01WBSPROAPP01\WebSeries VM01\'
DECLARE @DevServerFolderPath VARCHAR(55) = '\\VMWBSDEV1APP01\WebSeries Dev\'
DECLARE @DevServerName VARCHAR(55)

DECLARE @ProdServerName VARCHAR(55) = 'VMWBSPRO1DBA01'


IF @@SERVERNAME = 'VM01WBSPRODBA01'
    BEGIN
        SET @DevServerName = @DailyServerFolderPath
	
    END

IF @@SERVERNAME = 'VMWBSDEV1DBA01'
    BEGIN
        SET @DevServerName = @DevServerFolderPath
    END

-- WebSeries Event Manager
--UPDATE WEBSYSTEM.EVENTS
--SET SCHEDULED = 0

-- Update Application Server Folder Paths

UPDATE  WEBSYSTEM.BACSAPPLICATION
SET     [SOURCEFOLDERPATH] = REPLACE(SOURCEFOLDERPATH, @ProdServerFolderPath,
                                     @DevServerName)

UPDATE  [WEBSYSTEM].[INPUTOUTPUTCODE]
SET     [PATH] = REPLACE([PATH], @ProdServerFolderPath, @DevServerName)

-- Update Database Folder Paths for Crystal Reports

UPDATE  [ADMSYSTEM].[REPORTLOGONS]
SET     [DBCONNURL] = REPLACE([DBCONNURL], @ProdServerName, @@SERVERNAME)

UPDATE  [ADMSYSTEM].[REPORTLOGONS]
SET     [PASSWORD] = 'eec5862e1eaa320f6a2e2bf87110f0ee'
WHERE   [USERID] IN ( 'CFLADMSYSTEM', 'CFLARCHIVE', 'CFLWEBSYSTEM' )

UPDATE  [ADMSYSTEM].[REPORTLOGONS]
SET     [PASSWORD] = '5400e413d8fe6d0c93e53270519d3311'
WHERE   [USERID] = 'PAYBASE'

UPDATE  [WEBSYSTEM].[REPORTLOGONS]
SET     [DBCONNURL] = REPLACE([DBCONNURL], @ProdServerName, @@SERVERNAME)

UPDATE  [WEBSYSTEM].[REPORTLOGONS]
SET     [PASSWORD] = 'eec5862e1eaa320f6a2e2bf87110f0ee'
WHERE   [USERID] IN ( 'CFLADMSYSTEM', 'CFLARCHIVE', 'CFLWEBSYSTEM' )

UPDATE  [WEBSYSTEM].[REPORTLOGONS]
SET     [PASSWORD] = '5400e413d8fe6d0c93e53270519d3311'
WHERE   [USERID] = 'PAYBASE'

-- Set BACS to test mode
/*
-- Feedback from BottomLine
1 (FULL Test) or 2 (Structural TEST) are both OK for Standard BACS Payments
(i.e. they are not Live, which is the important thing)
 
Structural Test confirms Test Payments are "structurally sound" when submitted to BACS
FULL Test allows additional detail/reports to be retrieved from BACS
 
Key Point is They are both Test (not Live) submission methods
 
Note: For Faster Payments there is no Full Test option as these go via Vocalink (not BACS)
 
So, if you need to change this for Faster Payments as well as BACS Payments (and/or want to "keep it simple")
Use Structural Test (2) for all.

*/
UPDATE  WEBSYSTEM.BACSAPPLICATION
SET     TRANSMISSIONTYPE_ID = 2


-- Required for Crystal Reports to run correctly
--enable trustworthy 
DECLARE @dbname NVARCHAR(255)
DECLARE @sql NVARCHAR(255)
SET @dbname = DB_NAME()
SET @sql = 'ALTER DATABASE ' + @dbname + ' SET TRUSTWORTHY ON'
EXEC sp_executesql @sql
SET @sql = 'ALTER AUTHORIZATION ON DATABASE::' + @dbname + ' TO sa'
EXEC sp_executesql @sql
EXEC sp_executesql N'sp_configure ''show advanced options'', 1'
RECONFIGURE
EXEC sp_configure 'clr enabled', 1 
RECONFIGURE
GO


-- This is to set the Hub Event Monitor tasks with those IDs to unscheduled – so that if the Windows service behind it starts 
-- (which will be needed for some testing), Live processes aren’t interfered with.

USE WebSeries

UPDATE  websystem.events
SET     scheduled = 0
WHERE   id IN ( 144, 142, 143, 152 )
