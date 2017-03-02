/* ---- Grant Permissions ----
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 5 - Grant Permissions.sql"
*/

:on error exit
SET NOCOUNT ON
Print 'Step 5 - Grant Permissions - DotNetNuke'

-- Re-establish multi-user access
ALTER DATABASE [DotNetNuke] SET MULTI_USER;

USE DotNetNuke
GO

--Rematch the SQL Logins
exec sp_change_users_login  'Auto_Fix', 'DotNetNukeApp'
if exists (select * from sys.server_principals where name = N'DNNServiceUser')
begin
	exec sp_change_users_login  'Auto_Fix', 'DNNServiceUser'
end

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
AND ( 
		EA.LoginName NOT LIKE '%CCCSNT%'
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


/* --------------------------------- */
--Permissions for SYSTEST/DEV
--Environments: VM02; VM04; VM06; VM07; VM08; VM10
IF LEFT(@@SERVERNAME, 4) IN ('VM02', 'VM04', 'VM06', 'VM07', 'VM08', 'VM10')
BEGIN
	/* Automation Test Permissions */
	IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'AutomationTest')
	BEGIN
		IF  NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'AutomationTest')
		BEGIN
			CREATE USER [AutomationTest] FOR LOGIN [AutomationTest]
			EXEC sp_addrolemember N'db_datareader', N'AutomationTest'
			EXEC sp_addrolemember N'db_datawriter', N'AutomationTest'
			GRANT VIEW DEFINITION TO [AutomationTest]
		END
		ELSE
		BEGIN
			EXEC sp_change_users_login 'Auto_Fix', 'AutomationTest'
		END
	END
END
----Permissions for UAT/Analysis/PEF
----Environments: VM03, VM11, VM12, & PEF
--IF LEFT(@@SERVERNAME, 4) IN ('VM03', 'VM11', 'VM12') --OR SUBSTRING(@@SERVERNAME, 4, 3) = 'PEF'
--BEGIN
--	SELECT @@SERVERNAME
--END
----Permissions for Support/Release Environments
----Environments: VM01, VM05
--IF LEFT(@@SERVERNAME, 4) IN ('VM01', 'VM05')
--BEGIN
--	SELECT @@SERVERNAME
--END

---------------
-- *** DotNetNukeApp Permissions *** --
USE DotNetNuke
--GO
--
--DECLARE @spname NVARCHAR (255)
--DECLARE @cmd NVARCHAR (255)
--
--DECLARE spgrant_cursor CURSOR FOR 
--
--	SELECT	[name] 
--	FROM	dbo.[SYSOBJECTS] 
--	WHERE	type = 'P' 
--			AND OBJECTPROPERTY(ID,N'IsMSShipped') = 0
--
--	OPEN	spgrant_cursor
--
--		FETCH NEXT FROM spgrant_cursor INTO @spname
--
--			WHILE (@@fetch_status = 0)
--				BEGIN
--					SET @cmd = 'GRANT EXECUTE ON '+ @spname+ ' to DotNetNukeApp'
--					EXEC SP_EXECUTESQL @cmd
--					PRINT @cmd
--					
--					FETCH NEXT FROM spgrant_cursor INTO @spname
--				END
--
--	CLOSE	spgrant_cursor
--	
--DEALLOCATE	spgrant_cursor
--GO 
--
--
---- Grant table permissions
--IF EXISTS (SELECT 1 FROM dbo.[SYSOBJECTS] WHERE NAME = 'CccsFaq')
--	BEGIN
--		GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.CccsFaq TO DotNetNukeApp
--	END
--GO 
--
--	
--IF EXISTS (SELECT 1 FROM dbo.[SYSOBJECTS] WHERE NAME = 'CccsFaqCategory')
--	BEGIN
--		GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.CccsFaqCategory TO DotNetNukeApp
--	END
--GO 
--
--IF EXISTS (SELECT 1 FROM dbo.[SYSOBJECTS] WHERE NAME = 'CccsCustomFaq')
--	BEGIN
--		GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.CccsCustomFaq TO DotNetNukeApp
--	END
--GO
--
--IF EXISTS (SELECT 1 FROM dbo.[SYSOBJECTS] WHERE NAME = 'vCccsFaqCustom')
--	BEGIN
--		GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.vCccsFaqCustom TO DotNetNukeApp
--	END
--GO
--
--IF EXISTS (SELECT 1 FROM dbo.[SYSOBJECTS] WHERE NAME = 'vCccsFaqModule')
--	BEGIN
--		GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.vCccsFaqModule TO DotNetNukeApp
--	END
--GO
--
--IF EXISTS (SELECT 1 FROM dbo.[SYSOBJECTS] WHERE NAME = 'CccsPickListFaq')
--	BEGIN
--		GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.CccsPickListFaq TO DotNetNukeApp
--	END
--GO
--
--IF EXISTS (SELECT 1 FROM dbo.[SYSOBJECTS] WHERE NAME = 'vCccsPickListFaq')
--	BEGIN
--		GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.vCccsPickListFaq TO DotNetNukeApp
--	END
--GO
--
--IF EXISTS (SELECT 1 FROM dbo.[SYSOBJECTS] WHERE NAME = 'CccsEnquiryTypes')
--	BEGIN
--		GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.CccsEnquiryTypes TO DotNetNukeApp
--	END
--GO
--
--IF EXISTS (SELECT 1 FROM dbo.[SYSOBJECTS] WHERE NAME = 'CccsJobRoles')
--	BEGIN
--		GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.CccsJobRoles TO DotNetNukeApp
--	END
--GO
--
--IF EXISTS (SELECT 1 FROM dbo.[SYSOBJECTS] WHERE NAME = 'CccsJobVacancies')
--	BEGIN
--		GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.CccsJobVacancies TO DotNetNukeApp
--	END
--GO
--
--IF EXISTS (SELECT 1 FROM dbo.[SYSOBJECTS] WHERE NAME = 'CCCSEditWarningModule')
--	BEGIN
--		GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.CCCSEditWarningModule TO DotNetNukeApp
--	END
--GO
--
--IF EXISTS (SELECT 1 FROM dbo.[SYSOBJECTS] WHERE NAME = 'CCCSEditWarningPage')
--	BEGIN
--		GRANT SELECT, UPDATE, INSERT, DELETE ON dbo.CCCSEditWarningPage TO DotNetNukeApp
--	END
--GO
