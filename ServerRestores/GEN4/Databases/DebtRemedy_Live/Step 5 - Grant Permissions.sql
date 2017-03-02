/* ---- Grant Permissions ----
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\GENPRO1DBA01\DebtRemedy_Live\Step 5 - Grant Permissions.sql"
*/

:on error exit
SET NOCOUNT ON
Print 'Step 5 - Grant Permissions - DebtRemedy_Live'

-- Re-establish multi-user access
ALTER DATABASE [DebtRemedy_Live] SET MULTI_USER;

USE DebtRemedy_Live
GO

--exec sp_change_users_login  'Auto_Fix', 'CCCSVALink'
exec sp_change_users_login  'Auto_Fix', 'VCUser'
exec sp_change_users_login  'Auto_Fix', 'ERE_User'
exec sp_change_users_login  'Auto_Fix', 'DR_IVATRANSFER_WB_USER'
exec sp_change_users_login  'Auto_Fix', 'ReportingServices'
--exec sp_change_users_login  'Auto_Fix', 'upd'
if exists (select * from sys.server_principals where name = N'DROUser')
BEGIN
	exec sp_change_users_login 'Auto_Fix', 'DROUser'
END
if exists (select * from sys.server_principals where name = N'shoretelUser')
BEGIN
	exec sp_change_users_login 'Auto_Fix', 'shoretelUser'
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


---------------------------------------------------------------------
-- CREATED BY PAULB													-
-- CREATED ON 15/01/2010											-
-- Ensures all Systems Testers are created as counsellors in		-
-- a Debt Remedy database.											-
---------------------------------------------------------------------	
DECLARE @CURRENTDATE DATETIME
DECLARE @ENDDATE DATETIME
DECLARE @PASSWORD VARCHAR (30)
DECLARE @PASSWORDSALT VARCHAR (30)

SET		@CURRENTDATE = GETDATE()
SET		@ENDDATE = DATEADD (YY, 2, @CURRENTDATE)
-- Password default is 'ChangeMe'
SET		@PASSWORD = 'WvflpK9w+zjfqpC0GjxVPw==' 
SET		@PASSWORDSALT = '8357756770098897637'

-- Creates table and loads it with the login names of the systems 
-- tester team.
CREATE TABLE #TesterCounsellors
			 (
			 LoginName VARCHAR (25)
			 )

--	IF @@SERVERNAME IN ('VM10GENPRODBA01', 'VM11GENPRODBA01')
	if exists (select * from sys.server_principals where name = 'CCCSNT\IT Testing Team')
	BEGIN
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('AmitM')			
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('ArdeshirD')
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('BarryW')			
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('BenF')
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('CorinneJ')			
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('SarahBa')
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('HanuK')			
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('KirstyR')
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('ArronC')			
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('SimonB')
	END

-- For any testers that already exist, reset all their
-- login details and password.
UPDATE	dbo.Counsellors
SET		password = @PASSWORD
		,passwordSalt = @PASSWORDSALT 
		,Start = @CURRENTDATE
		,Finish = @ENDDATE
		,LastPasswordChange = @CURRENTDATE
		,LoginAttemptCount = 0
		,ForcePasswordChange = 0		
		,Deleted = 0
WHERE	LoginName IN (
					 SELECT LoginName
					 FROM	#TesterCounsellors 
					 )

-- For any testers that don't exist, insert them and 
-- assign default values for login details.					 
INSERT INTO dbo.Counsellors
			(			
			LoginName
			,Password
			,PasswordSalt
			,Forename
			,Surname			
			,Start
			,Finish
			,LastPasswordChange
			,LoginAttemptCount
			,ForcePasswordChange
			,Deleted			
			)
SELECT		LoginName
			,password = @PASSWORD
			,passwordSalt = @PASSWORDSALT 
			,LoginName AS Forename
			,LoginName AS Surname		
			,Start = @CURRENTDATE
			,Finish = @ENDDATE
			,LastPasswordChange = @CURRENTDATE
			,LoginAttemptCount = 0
			,ForcePasswordChange = 0			
			,Deleted = 0
FROM		#TesterCounsellors
WHERE		LoginName NOT IN (
							 SELECT LoginName
							 FROM	dbo.Counsellors
							 )
							 
							 
IF EXISTS (SELECT TOP 1 1 FROM tempdb.dbo.sysobjects WHERE name LIKE '#TesterCounsellors%')
	BEGIN	
		DROP TABLE #TesterCounsellors
	END 
