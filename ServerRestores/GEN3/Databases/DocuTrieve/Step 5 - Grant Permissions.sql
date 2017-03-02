/* ---- Grant Permissions ----
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 5 - Grant Permissions.sql"
*/

:on error exit
SET NOCOUNT ON
Print 'Step 5 - Grant Permissions - DocuTrieve'

USE [master]
GO
ALTER DATABASE [DocuTrieve] SET  MULTI_USER WITH ROLLBACK IMMEDIATE
GO

-- Apply UAT Users --
USE DocuTrieve
GO

--Logins added to database if on server
if exists (select * from Sys.Server_Principals where name = 'CCCSNT\DocuTrieve UAT')
BEGIN
	if exists (select * from sysusers where name = 'CCCSNT\DocuTrieve UAT')
		EXEC sp_revokedbaccess 'CCCSNT\DocuTrieve UAT'
	if exists (select * from sysusers where name = 'DocuTrieve UAT')
		EXEC sp_revokedbaccess 'DocuTrieve UAT'
	EXEC sp_grantdbaccess 'CCCSNT\DocuTrieve UAT', 'CCCSNT\DocuTrieve UAT'
	exec sp_addrolemember  'DocuTrieve User', 'CCCSNT\DocuTrieve UAT'
END

--Logins added to database if on server
if exists (select * from Sys.Server_Principals where name = 'CCCSNT\DocuTrieve DSM UAT')
BEGIN
	if exists (select * from sysusers where name = 'CCCSNT\DocuTrieve DSM UAT')
		EXEC sp_revokedbaccess 'CCCSNT\DocuTrieve DSM UAT'
	if exists (select * from sysusers where name = 'DocuTrieve DSM UAT')
		EXEC sp_revokedbaccess 'DocuTrieve DSM UAT'
	EXEC sp_grantdbaccess 'CCCSNT\DocuTrieve DSM UAT', 'CCCSNT\DocuTrieve DSM UAT'
	exec sp_addrolemember  'DocuTrieve User', 'CCCSNT\DocuTrieve DSM UAT'
	exec sp_addrolemember  'DSM User', 'CCCSNT\DocuTrieve DSM UAT'
	--exec sp_addrolemember  'db_backupoperator', 'CCCSNT\DocuTrieve DSM UAT'
END

--NEW PERMISSIONS PROCESS
-----------------------------------------------------------------------------------------
DECLARE @EnvironmentType VARCHAR(50)
DECLARE @sql NVARCHAR(1000)
DECLARE	@LoginName VARCHAR(50)
DECLARE @AssociatedDatabase VARCHAR(30) --TestPermDB
DECLARE @Environment VARCHAR(10) --TEST
--DECLARE @DBRole VARCHAR(30)
DECLARE @RunDate AS DATETIME
DECLARE @SQLLogin AS BIT
DECLARE @SysAdmin AS BIT
DECLARE @ViewDefinition AS BIT
DECLARE @DBOwner AS BIT
DECLARE @DataReader AS BIT
DECLARE @DataWriter AS BIT
DECLARE @AppRoleLevel AS TINYINT


SET @RunDate = GETDATE()
SET @AssociatedDatabase = $(DBName)
SET @Environment = $(Environment)

--First Retrieve the environment type
SELECT @EnvironmentType = Es.EnvironmentType FROM EnviroDataLinkedServer.EnvironmentAccess.dbo.Environments Es
WHERE Es.Environment = @Environment


DECLARE dbfiles CURSOR FOR
SELECT EA.LoginName, EA.SQLLogin --, EA.DatabaseName
, EA.SysAdmin, EA.ViewDefinition, EA.DBOwner, EA.DataReader, EA.DataWriter, EA.AppRoleLevel
FROM 
EnviroDataLinkedServer.EnvironmentAccess.dbo.LoginPermissions EA
--LEFT JOIN
--dbo.DatabaseRoles DbR
--ON EA.Permission = DbR.Permission
--AND EA.DatabaseName = DbR.DatabaseName

WHERE 
	(
		--Retrieve permissions if just the environment type set (i.e. apply to all databases/servers in the environment group)
		((EA.EnvironmentType = @EnvironmentType) AND (EA.DatabaseName IS NULL) AND (EA.Environment IS NULL))
		OR --Retrieve permissions if just the environment set (i.e. apply to all databases/servers in the environment)
		((EA.EnvironmentType IS NULL) AND (EA.DatabaseName IS NULL) AND (EA.Environment = @Environment))
		OR --Retrieve permissions if just the database set (i.e. apply to all database servers everywhere for the specified database - used for _MI access)
		((EA.EnvironmentType  IS NULL) AND (EA.DatabaseName = @AssociatedDatabase) AND (EA.Environment IS NULL))
		OR --Retrieve permissions if database and environment type set
		((EA.EnvironmentType = @EnvironmentType) AND (EA.DatabaseName = @AssociatedDatabase) AND (EA.Environment IS NULL))
		OR --Retrieve permissions if database and environment set
		((EA.EnvironmentType IS NULL) AND (EA.DatabaseName = @AssociatedDatabase) AND (EA.Environment = @Environment))
	)
AND 
	(
		(EA.StartDate < @RunDate) OR (EA.StartDate IS NULL)
	)
AND
	(
		(EA.EndDate > @RunDate) OR (EA.EndDate IS NULL)
	)

OPEN dbfiles
FETCH NEXT FROM dbfiles INTO @LoginName, @SQLLogin, @SysAdmin, @ViewDefinition, @DBOwner, @DataReader, @DataWriter, @AppRoleLevel
--For each database file...
WHILE @@FETCH_STATUS = 0
BEGIN
	--CREATE THE LOGIN (CHECK FIRST IF IT ALREADY EXISTS)
	IF @SQLLogin = 1
	BEGIN
		--NB Currently only handles SQL Logins with password same as the login name
		SET @sql = 'IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name =  N''' + @LoginName + ''') CREATE LOGIN [' + @LoginName + '] WITH PASSWORD=N''' + @LoginName + ''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF'
		EXEC(@sql)
	END
	ELSE
	BEGIN
		SET @sql = 'IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name =  N''' + @LoginName + ''') CREATE LOGIN [' + @LoginName + '] FROM WINDOWS WITH DEFAULT_DATABASE=[master]'
		EXEC(@sql)
	END
	--CREATE THE USER
	SET @sql = 'USE ' + @AssociatedDatabase + ' IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name =  N''' + @LoginName + ''') CREATE USER [' + @LoginName + '] FOR LOGIN [' + @LoginName + ']'
	EXEC(@sql)

	IF @SysAdmin = 1
	BEGIN
		SET @sql = 'EXEC master..sp_addsrvrolemember @loginame = N''' + @LoginName + ''', @rolename = N''sysadmin'''
		EXEC(@sql)
	END
	IF @DBOwner = 1
	BEGIN
		SET @sql = 'USE ' + @AssociatedDatabase + ' EXEC sp_addrolemember N''db_owner'', N''' + @LoginName + ''''
		EXEC(@sql)
	END
	IF @DataReader = 1
	BEGIN
		SET @sql = 'USE ' + @AssociatedDatabase + ' EXEC sp_addrolemember N''db_datareader'', N''' + @LoginName + ''''
		EXEC(@sql)
	END
	IF @DataWriter = 1
	BEGIN
		SET @sql = 'USE ' + @AssociatedDatabase + ' EXEC sp_addrolemember N''db_datawriter'', N''' + @LoginName + ''''
		EXEC(@sql)
	END
	IF @ViewDefinition = 1
	BEGIN
		SET @sql = 'USE ' + @AssociatedDatabase + ' GRANT VIEW DEFINITION TO [' + @LoginName + ']'
		EXEC(@sql)
	END
	

	FETCH NEXT FROM dbfiles INTO @LoginName, @SQLLogin, @SysAdmin, @ViewDefinition, @DBOwner, @DataReader, @DataWriter, @AppRoleLevel
END
CLOSE dbfiles 
DEALLOCATE dbfiles 
-----------------------------------------------------------------------------------------

-- Group membership changes for Dennis P
USE DocuTrieve

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\Non-Live Docutrieve Users')
BEGIN
	CREATE USER [CCCSNT\Non-Live Docutrieve Users] FOR LOGIN [CCCSNT\Non-Live Docutrieve Users]
	exec sp_addrolemember  'DocuTrieve User', 'CCCSNT\Non-Live Docutrieve Users'
END

/* Create users for COP - taken from $/DocuTrieve/Database/features/PROJ41_COP2_SEP2014/Redgate Setup */
/* create logins */
USE [master]
GO
/**********************************************
*	Expected Logins are:
*		CCCSNT\nonliveimagingrest		- non live imaging rest service
*		CCCSNT\imagingrest                      - live imaging rest service
*		CCCSNT\CIUser					- continuous integration (TeamCity)
*		CCCSNT\RedgateAdmin				- Redgate admin account used for audit reports
**********************************************/

/* Environment dependant logins */
IF @@SERVERNAME = 'LDSGENPRO1DBA03'
BEGIN		
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\imagingrest')
		CREATE LOGIN [CCCSNT\imagingrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
END
ELSE 
BEGIN
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveimagingrest')
		CREATE LOGIN [CCCSNT\nonliveimagingrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
END
GO

/* All remaining logins */
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\CIUser')
	CREATE LOGIN [CCCSNT\CIUser] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english];

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\RedgateAdmin')
		CREATE LOGIN [CCCSNT\RedgateAdmin] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO
/* Create users */
USE [DocuTrieve]
GO

/* Drop schemas if they exist */
IF  EXISTS (SELECT * FROM sys.schemas WHERE name = N'ImagingRest')
	DROP SCHEMA [ImagingRest]
GO

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonliveimagingrest')
	DROP USER [CCCSNT\nonliveimagingrest];
	
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\imagingrest')
	DROP USER [CCCSNT\imagingrest];		
	
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'ImagingRest')
	DROP USER [ImagingRest];

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\RedgateAdmin')
	DROP USER [CCCSNT\RedgateAdmin]
GO

IF @@SERVERNAME = 'LDSGENPRO1DBA03'
BEGIN
	CREATE USER [ImagingRest] FOR LOGIN [CCCSNT\imagingrest] WITH DEFAULT_SCHEMA=[dbo];
	
END 	
ELSE
BEGIN
	CREATE USER [ImagingRest] FOR LOGIN [CCCSNT\nonliveimagingrest] WITH DEFAULT_SCHEMA=[dbo];
END;
GO 

CREATE USER [CCCSNT\RedgateAdmin] FOR LOGIN [CCCSNT\RedgateAdmin];

/* Assign Roles */
IF EXISTS (	SELECT * FROM sys.database_principals WHERE name = 'WebServiceRole' AND type = 'R' )
BEGIN
	EXEC sp_addrolemember N'WebServiceRole', N'ImagingRest';
END;

EXEC sp_addrolemember N'db_datareader', N'CCCSNT\RedgateAdmin';
GO

-- CommunicationService user
USE DocuTrieve
GO 
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\NonLiveCommunication')
BEGIN
	IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CommunicationService')
	BEGIN
		ALTER  USER [CommunicationService]
		WITH LOGIN = [CCCSNT\NonLiveCommunication], NAME = [CommunicationService];
	END
END
GO 