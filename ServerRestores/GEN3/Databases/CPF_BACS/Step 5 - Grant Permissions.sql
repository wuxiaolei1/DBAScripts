/* ---- Grant Permissions ----
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 5 - Grant Permissions.sql"
*/
SET NOCOUNT ON
Print 'Step 5 - Grant Permissions - CPF_BACS'

-- Re-establish multi-user access
ALTER DATABASE [CPF_BACS] SET MULTI_USER;

USE CPF_BACS
GO

--exec sp_change_users_login 'Auto_Fix', 'pdduser'
exec sp_change_users_login 'Auto_Fix', 'CPFReportUser'
exec sp_change_users_login 'Auto_Fix', 'CPFB_BMI_DWExtract'
exec sp_change_users_login 'Auto_Fix', 'DMSSQLServerLink'

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

IF @EnvironmentType IS NULL
BEGIN
	SELECT @EnvironmentType = Es.EnvironmentType 
		FROM EnviroDataLinkedServer.EnvironmentAccess.dbo.Environments Es
		INNER JOIN EnviroDataLinkedServer.EnvironmentAccess.dbo.EnvironmentServers ESs
		ON Es.Environment = ESs.Environment
		WHERE ESs.EnvironmentServer = @@SERVERNAME
END	

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


--Add the Non-Live CPF BACS account
if exists (select * from sys.server_principals where name = 'CCCSNT\CFPBACsNonlive')
BEGIN

	IF  EXISTS (SELECT * FROM dbo.sysusers WHERE name = N'CCCSNT\CFPBACsNonlive')
		DROP USER [CCCSNT\CFPBACsNonlive]
	CREATE USER [CCCSNT\CFPBACsNonlive] FOR LOGIN [CCCSNT\CFPBACsNonlive]
	EXEC sp_addrolemember N'CPFBACS_Service', N'CCCSNT\CFPBACsNonlive'
	EXEC sp_addrolemember N'CPFBACS_User', N'CCCSNT\CFPBACsNonlive'

END

--Add the non-live BACS Search account----------------------------
USE master
GO

IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name =  N'CCCSNT\nonlivebacssearch')
	CREATE LOGIN [CCCSNT\nonlivebacssearch] FROM WINDOWS WITH DEFAULT_DATABASE=[CPF_BACS]

USE [CPF_BACS]
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'CCCSNT\nonlivebacssearch')
	CREATE USER [CCCSNT\nonlivebacssearch] FOR LOGIN [CCCSNT\nonlivebacssearch]

--Permissions
EXEC sp_addrolemember N'CPFBACS_User', N'CCCSNT\nonlivebacssearch'
GO
------------------------------------------------------------------

--Add the non-live BACS Config account----------------------------
USE master
GO

/* Environment dependant logins */
IF @@SERVERNAME = 'LDSGENPRO1DBA03'
BEGIN		
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\bacsconfig')
		CREATE LOGIN [CCCSNT\bacsconfig] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
END
ELSE 
BEGIN
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivebacsconfig')
		CREATE LOGIN [CCCSNT\nonlivebacsconfig] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
END
GO

/* Needs adding to msdb for database mail */
USE [msdb]
GO
-- DROP User
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'bacsconfig')
	DROP USER [bacsconfig]
GO

-- Create user
IF @@SERVERNAME = 'LDSGENPRO1DBA03'
BEGIN
	CREATE USER [bacsconfig] FOR LOGIN [CCCSNT\bacsconfig];
END 	
ELSE
BEGIN
	CREATE USER [bacsconfig] FOR LOGIN [CCCSNT\nonlivebacsconfig];
END;
GO

-- Add to role
EXEC sp_addrolemember N'DatabaseMailUserRole', N'bacsconfig'
GO

USE [CPF_BACS]
GO
	
-- DROP Users
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'bacsconfig')
	DROP USER [bacsconfig]
GO

-- Create user
IF @@SERVERNAME = 'LDSGENPRO1DBA03'
BEGIN
	CREATE USER [bacsconfig] FOR LOGIN [CCCSNT\bacsconfig] WITH DEFAULT_SCHEMA=[dbo];
END 	
ELSE
BEGIN
	CREATE USER [bacsconfig] FOR LOGIN [CCCSNT\nonlivebacsconfig] WITH DEFAULT_SCHEMA=[dbo];
END;
GO 

/* Assign Roles */
IF EXISTS (	SELECT * FROM sys.database_principals WHERE name = 'CPFBACS_ConfigUser' AND type = 'R' )
BEGIN
	EXEC sp_addrolemember N'CPFBACS_ConfigUser', N'bacsconfig';
END;
------------------------------------------------------------------

if exists (select * from sys.database_principals where name = 'CCCSNT\IT Application Support')
	exec sp_addrolemember  'CPFBACS_User', 'CCCSNT\IT Application Support'

if exists (select * from sys.database_principals where name = 'CCCSNT\IT Testers')
	exec sp_addrolemember  'CPFBACS_User', 'CCCSNT\IT Testers'

if exists (select * from sys.database_principals where name = 'CCCSNT\IT Developers')
	exec sp_addrolemember  'CPFBACS_User', 'CCCSNT\IT Developers'

if exists (select * from sys.database_principals where name = 'CCCSNT\IT Analysis')
	exec sp_addrolemember  'CPFBACS_User', 'CCCSNT\IT Analysis'

/*--- Apply UAT Permissions ---*/
--Logins added to database if on server
if exists (select * from sys.server_principals where name = 'CCCSNT\CPF BACS UAT')
BEGIN
	if exists (select * from sysusers where name = 'CCCSNT\CPF BACS UAT')
		EXEC sp_revokedbaccess 'CCCSNT\CPF BACS UAT'
	if exists (select * from sysusers where name = 'CPF BACS UAT')
		EXEC sp_revokedbaccess 'CPF BACS UAT'
	EXEC sp_grantdbaccess 'CCCSNT\CPF BACS UAT', 'CCCSNT\CPF BACS UAT'
	exec sp_addrolemember  'CPFBACS_User', 'CCCSNT\CPF BACS UAT'
END
