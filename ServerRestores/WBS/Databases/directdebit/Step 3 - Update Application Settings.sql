
/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 3 - Update Application Settings .sql"

--- */
Print 'Step 3 - Update Application Settings - directdebit'

USE [master]
GO
ALTER DATABASE [directdebit] SET  RESTRICTED_USER WITH NO_WAIT
GO

Alter database directdebit set New_broker no_wait
GO   

-- Enable Broker for the DirectDebit REST service to start
ALTER DATABASE directdebit SET ENABLE_BROKER WITH no_wait
GO

USE [master]
GO
ALTER DATABASE [directdebit] SET MULTI_USER WITH NO_WAIT
GO

USE [directdebit]
GO

--Application Settings
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


-- Update System Config
UPDATE [dbo].[SystemConfig]
SET [Value] = 'thisisadummyemail@notstepchange.co.na',
[DefaultValue] = 'thisisadummyemail@notstepchange.co.na'
WHERE [Name] = 'Support Email'

-- Update AppContacts
UPDATE [dbo].[AppContacts]
SET [Email] = 'thisisadummyemail@notstepchange.co.na'
WHERE [Email] IS NULL OR REPLACE(Email,' ','') = ''

-- Update all PCO jobs to disabled
UPDATE dbo.PCO
SET XMLDATA = REPLACE(XMLDATA, @ProdServerFolderPath,@DevServerName)

UPDATE dbo.PCO
SET XMLDATA = REPLACE(XMLDATA, '<Enabled>true</Enabled>','<Enabled>false</Enabled>')

/*
[dbo].[Machines]
[dbo].[SystemConfig]
*/