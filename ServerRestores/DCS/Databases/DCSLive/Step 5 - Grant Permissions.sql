/* ---- Apply Permissions ----
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\vmprtpro1app01\systems\Tech support shared data\SQL Server\ServerRestores\DCSSERVER\DCSLive\Step 5 - Grant Permissions.sql"
*/

:on error exit
SET NOCOUNT ON
Print 'Step 5 - Grant Permissions DCS'

-- Re-establish multi-user access
ALTER DATABASE [DCSLive] SET MULTI_USER;

Use DCSLive
GO

--Rematch SQLLogins
exec sp_change_users_login 'Auto_Fix', 'CCCSVALink'
exec sp_change_users_login 'Auto_Fix', 'CWSRefreshUser'
exec sp_change_users_login 'Auto_Fix', 'CallRoutingUser'
if exists (select * from sys.server_principals where name = N'DCS_BMI_DWExtract')
BEGIN
	exec sp_change_users_login 'auto_fix', 'DCS_BMI_DWExtract'
END
if exists (select * from sys.server_principals where name = N'DMSSQLServerLink')
BEGIN
	exec sp_change_users_login 'auto_fix', 'DMSSQLServerLink'
END
if exists (select * from sys.server_principals where name = N'DRWriteback')
BEGIN
	exec sp_change_users_login 'Auto_Fix', 'DRWriteback'
END
if exists (select * from sys.server_principals where name = N'iFACE_DCSUser')
BEGIN
	exec sp_change_users_login 'Auto_Fix', 'iFACE_DCSUser'
END
if exists (select * from sys.server_principals where name = N'CommsWebServiceUser')
BEGIN
	exec sp_change_users_login 'Auto_Fix', 'CommsWebServiceUser'
END
if exists (select * from sys.server_principals where name = N'DROUser')
BEGIN
	exec sp_change_users_login 'Auto_Fix', 'DROUser'
END
exec sp_change_users_login 'Auto_Fix', 'ReportingServices'
exec sp_change_users_login 'Auto_Fix', 'sqlserverlink'
exec sp_change_users_login 'Auto_Fix', 'TCS_USER'
exec sp_change_users_login 'Auto_Fix', 'wsDCSUser'
GO 

--ADD Permissions for CCCSNT\SUPPRO3_SQLAGENT
if exists (select * from sys.server_principals where name = N'CCCSNT\SUPPRO3_SQLAGENT')
BEGIN
	IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'CCCSNT\SUPPRO3_SQLAGENT')
	begin
		CREATE USER [CCCSNT\SUPPRO3_SQLAGENT] FOR LOGIN [CCCSNT\SUPPRO3_SQLAGENT]
		EXEC sp_addrolemember  N'WSS_DCSWriteback', N'CCCSNT\SUPPRO3_SQLAGENT'
		EXEC sp_addrolemember  N'KeyIVRRole', N'CCCSNT\SUPPRO3_SQLAGENT'
	end
END

--Create NON_LIVE ISI Data User...
USE [master]
GO
IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name =  N'CCCSNT\nonliveISIDataServic')
	CREATE LOGIN [CCCSNT\nonliveISIDataServic] FROM WINDOWS WITH DEFAULT_DATABASE=[master]

USE [DCSLive]
GO
IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'CCCSNT\nonliveISIDataServic')
	CREATE USER [CCCSNT\nonliveISIDataServic] FOR LOGIN [CCCSNT\nonliveISIDataServic]

USE [DCSLive]
GO
EXEC sp_addrolemember N'ISIUser', N'CCCSNT\nonliveISIDataServic'
GO

-- Rematch iFACE Proxy user
USE DCSLive
GO 
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\VMDCSiFACE_SSISProxy')
BEGIN
	IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'DCSiFACE_SSISProxy')
	BEGIN
		ALTER  USER [DCSiFACE_SSISProxy]
		WITH LOGIN = [CCCSNT\VMDCSiFACE_SSISProxy], NAME = [DCSiFACE_SSISProxy];
	END
END
GO 

--SQLLogin Permissions
IF  not EXISTS (SELECT * FROM sys.database_principals WHERE name = N'DCSReader') begin
CREATE USER [DCSReader] FOR LOGIN [DCSReader]
--EXEC dbo.sp_grantdbaccess @loginame = N'DCSReader', @name_in_db = N'DCSReader'
EXEC sp_addrolemember N'db_datareader', N'DCSReader'
end

--Application Logins
IF  not EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\DCSServiceLayer') begin
CREATE USER [CCCSNT\DCSServiceLayer] FOR LOGIN [CCCSNT\DCSServiceLayer] WITH DEFAULT_SCHEMA=[dbo]

EXEC sp_addrolemember N'servicelayerrole', N'CCCSNT\DCSServiceLayer'
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
		--SET @sql = 'USE ' + @AssociatedDatabase + ' CREATE USER [' + @LoginName + '] FOR LOGIN [' + @LoginName + ']'
	SET @sql = 'USE ' + @AssociatedDatabase + ' IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name =  N''' + @LoginName + ''') CREATE USER [' + @LoginName + '] FOR LOGIN [' + @LoginName + ']'
	EXEC(@sql)

	IF @SysAdmin = 1
	BEGIN
		SET @sql = 'EXEC master..sp_addsrvrolemember @loginame = N''' + @LoginName + ''', @rolename = N''sysadmin'''
		EXEC(@sql)
	END
	IF @DBOwner = 1
	BEGIN
		--SET @sql = 'USE ' + @AssociatedDatabase + ' EXEC sp_addrolemember N''' + @DBRole + ''', N''' + @LoginName + ''''
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

----Add logins if on server
--if exists (select * from sys.server_principals where name = N'CCCSNT\IT Application Support')
--BEGIN
--	IF @@SERVERNAME IN ('VM01DCSSERVER', 'VM04DCSSERVER')
--	BEGIN
--		CREATE USER [CCCSNT\IT Application Support] FOR LOGIN [CCCSNT\IT Application Support]
--		exec sp_addrolemember  'DCSUser', 'CCCSNT\IT Application Support'
--		exec sp_addrolemember  'DCEditor', 'CCCSNT\IT Application Support'
--		exec sp_addrolemember  'db_owner', 'CCCSNT\IT Application Support'
--		CREATE USER [CCCSNT\Systems DBA Team] FOR LOGIN [CCCSNT\Systems DBA Team]
--		exec sp_addrolemember  'DCSUser', 'CCCSNT\Systems DBA Team'
--		exec sp_addrolemember  'DCEditor', 'CCCSNT\Systems DBA Team'
--		exec sp_addrolemember  'db_owner', 'CCCSNT\Systems DBA Team'
--		EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'stefanos', @OrgCentre = 355487
--	END
--	ELSE
--	BEGIN
--		CREATE USER [CCCSNT\IT Application Support] FOR LOGIN [CCCSNT\IT Application Support]
--		exec sp_addrolemember  'DCSUser', 'CCCSNT\IT Application Support'
--		exec sp_addrolemember  'DCEditor', 'CCCSNT\IT Application Support'
--		exec sp_addrolemember  'DocuSpam', 'CCCSNT\IT Application Support'
--		exec sp_addrolemember  'db_datareader', 'CCCSNT\IT Application Support'
--	END
--END
--
--if exists (select * from sys.server_principals where name = N'CCCSNT\IT Testing Team')
--BEGIN
--	IF  not EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\IT Testing Team') begin
--
--		CREATE USER [CCCSNT\IT Testing Team] FOR LOGIN [CCCSNT\IT Testing Team]
--	end
--	exec sp_addrolemember  'DCSUser', 'CCCSNT\IT Testing Team'
--	exec sp_addrolemember  'DCUser', 'CCCSNT\IT Testing Team'
--	exec sp_addrolemember  'DCEditor', 'CCCSNT\IT Testing Team'
--	exec sp_addrolemember  'DocuSpam', 'CCCSNT\IT Testing Team'
--	exec sp_addrolemember  'PDD', 'CCCSNT\IT Testing Team'
--END
--
--if exists (select * from sys.server_principals where name = N'CCCSNT\Systems Integration Team')
--BEGIN
--	IF  not EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\Systems Integration Team') begin
--		CREATE USER [CCCSNT\Systems Integration Team] FOR LOGIN [CCCSNT\Systems Integration Team]
--	end
--	exec sp_addrolemember  'DCSUser', 'CCCSNT\Systems Integration Team'
--	exec sp_addrolemember  'DCUser', 'CCCSNT\Systems Integration Team'
--	exec sp_addrolemember  'DCEditor', 'CCCSNT\Systems Integration Team'
--	exec sp_addrolemember  'DocuSpam', 'CCCSNT\Systems Integration Team'
--	exec sp_addrolemember  'PDD', 'CCCSNT\Systems Integration Team'
--END
--
--if exists (select * from sys.server_principals where name = N'CCCSNT\IT Development Team')
--BEGIN
--	CREATE USER [Systems Developers] FOR LOGIN [CCCSNT\IT Development Team]
--	exec sp_addrolemember  'DCSUser', 'Systems Developers'
--	exec sp_addrolemember  'db_datareader', 'Systems Developers'
--END
--
--if exists (select * from sys.server_principals where name = N'CCCSNT\IT Analysis')
--BEGIN
--	IF  not EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\IT Analysis') begin
--	
--	CREATE USER [CCCSNT\IT Analysis] FOR LOGIN [CCCSNT\IT Analysis]
--	
--	end
--	exec sp_addrolemember  'DCSUser', 'CCCSNT\IT Analysis'
--	exec sp_addrolemember  'DCUser', 'CCCSNT\IT Analysis'
--	exec sp_addrolemember  'DCEditor', 'CCCSNT\IT Analysis'
--	exec sp_addrolemember  'DocuSpam', 'CCCSNT\IT Analysis'
--	exec sp_addrolemember  'PDD', 'CCCSNT\IT Analysis'
--	exec sp_addrolemember  'db_datareader', 'CCCSNT\IT Analysis'
--END
--
--if exists (select * from sys.server_principals where name = N'CCCSNT\BI Development Team')
--BEGIN
--	CREATE USER [CCCSNT\BI Development Team] FOR LOGIN [CCCSNT\BI Development Team]
--	exec sp_addrolemember  'db_datareader', 'CCCSNT\BI Development Team'
--END

/* --------------------------------- */
/* ---- UAT Users ---- */

Use DCSLive
GO

--Add UAT if present on server
if exists (select * from sys.server_principals where name = N'CCCSNT\DCS UAT')
BEGIN
	IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\DCS UAT')
	if exists (select * from sysusers where name = 'CCCSNT\DCS UAT')
		EXEC sp_revokedbaccess 'CCCSNT\DCS UAT'
	CREATE USER [CCCSNT\DCS UAT] FOR LOGIN [CCCSNT\DCS UAT]
	exec sp_addrolemember  'DCSUser', 'CCCSNT\DCS UAT'
	exec sp_addrolemember  'DCUser', 'CCCSNT\DCS UAT'
END

if exists (select * from sys.server_principals where name = N'CCCSNT\DCS Editors UAT')
BEGIN
	IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\DCS Editors UAT')
		EXEC sp_revokedbaccess 'CCCSNT\DCS Editors UAT'
	CREATE USER [CCCSNT\DCS Editors UAT] FOR LOGIN [CCCSNT\DCS Editors UAT]
	exec sp_addrolemember  'DCSUser', 'CCCSNT\DCS Editors UAT'
	exec sp_addrolemember  'DCUser', 'CCCSNT\DCS Editors UAT'
	exec sp_addrolemember  'DCEditor', 'CCCSNT\DCS Editors UAT'
	exec sp_addrolemember  'DocuSpam', 'CCCSNT\DCS Editors UAT'
END

if exists (select * from sys.server_principals where name = N'CCCSNT\DDE UAT')
BEGIN
	IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\DDE UAT')
		EXEC sp_revokedbaccess 'CCCSNT\DDE UAT'
	CREATE USER [CCCSNT\DDE UAT] FOR LOGIN [CCCSNT\DDE UAT]
	exec sp_addrolemember  'DCSUser', 'CCCSNT\DDE UAT'
	exec sp_addrolemember  'DCEditor', 'CCCSNT\DDE UAT'
	exec sp_addrolemember  'PDD', 'CCCSNT\DDE UAT'
END
/* --------------------------------- */
/* SQL Compare Permissions */
IF  NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'SQLCompare')
BEGIN
	CREATE USER [SQLCompare] FOR LOGIN [SQLCompare]
	EXEC sp_addrolemember N'db_datareader', N'SQLCompare'
	GRANT VIEW DEFINITION TO SQLCompare
END

/* --------------------------------- */
----Permissions for SYSTEST/DEV
----Environments: VM02; VM04; VM06; VM07; VM08; VM10
--IF LEFT(@@SERVERNAME, 4) IN ('VM02', 'VM04', 'VM06', 'VM07', 'VM08', 'VM10')
--BEGIN
--	/* Automation Test Permissions */
--	IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'AutomationTest')
--	BEGIN
--		IF  NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'AutomationTest')
--		BEGIN
--			CREATE USER [AutomationTest] FOR LOGIN [AutomationTest]
--			EXEC sp_addrolemember N'db_datareader', N'AutomationTest'
--			EXEC sp_addrolemember N'db_datawriter', N'AutomationTest'
--			GRANT VIEW DEFINITION TO [AutomationTest]
--		END
--		ELSE
--		BEGIN
--			EXEC sp_change_users_login 'Auto_Fix', 'AutomationTest'
--		END
--	END
--END
--

/* --------------------------------- */
/* ---- Add test users to Colleague Editor ---- */

--DCSColleagueEditor adds users to Organisation Centres:
--355467 'Leeds Office'
--375526 'Counselling Support'
--355488 'Customer Services'
--355469 'Client Support'
--355487 'Administration'
--355470 'Leeds Counselling Office'

USE [tempdb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[tempdb].[dbo].[AddDCSColleague]', 'P') IS NOT NULL
	SET NOEXEC ON;
GO
-- STUB
CREATE PROCEDURE [dbo].[AddDCSColleague] (@DCSUser VARCHAR(20), @OrgCentre INT ) AS BEGIN SELECT 1; END;
GO
SET NOEXEC OFF;
GO
-- DEFINITION
ALTER PROCEDURE [dbo].[AddDCSColleague] (@DCSUser VARCHAR(20), @OrgCentre INT ) AS

DECLARE @tblAssociateID INT
DECLARE @tblAssociateID2 INT
DECLARE @Colleague_Identifier INT

IF NOT EXISTS (SELECT * FROM [DCSLive].[dbo].[tblCOLLEAGUE] WHERE 
Colleague_NT_Logon_Id = @DCSUser
)
BEGIN
--	EXEC DMS_GetNextKeyOnlyOutput 'USER', @NewKey OUTPUT 
--	SELECT @UserID = 'USER' + CAST(@NewKey AS varchar(5))

	--(ID, TypeID) from dbo.tblAssociateType
	--TypeID = 5 = Colleague (SubTypeID = 1)
	EXEC @tblAssociateID = DCSLive.dbo.DCS_w_ASSOCIATE_v4 0, 5

	EXEC @Colleague_Identifier = DCSLive.dbo.DCS_w_COLLEAGUE_v4 @tblAssociateID, 1, @DCSUser, @DCSUser, 'NA', '', NULL, 0, 0, @DCSUser, 0, 0

	--(ID, TypeID) from dbo.tblAssociateType
	--TypeID = 14 = Colleague Role
	EXEC @tblAssociateID2 = DCSLive.dbo.DCS_w_ASSOCIATE_v4 0, 14

	--  @DMS_User_ID Integer = 81 (This figure now arbitray as only relevant for DMS Core)
	EXEC DCSLive.dbo.DCS_w_ColleagueRole_v4 @tblAssociateID2, '', 0, 0, 81

	-- select * from dbo.tblAssociateRelationshipType
	-- gives ID = 8 = Colleague to Colleague Role
	EXEC DCSLive.dbo.DCS_w_AssociateRelationship_v4 0, @tblAssociateID, @tblAssociateID2, 8, 'Jul 21 2009  8:30:24:000AM', 'Dec 31 9999 12:00:00:000AM'

	-- select * from dbo.tblAssociateRelationshipType
	-- gives ID = 9 = Colleague Role to Org Centre
	EXEC DCSLive.dbo.DCS_w_AssociateRelationship_v4 0, @tblAssociateID2, @OrgCentre, 9, 'Jul 21 2009  8:30:24:000AM', 'Dec 31 9999 12:00:00:000AM'

	EXEC DCSLive.dbo.DCS_w_COLLEAGUE_USER_PROFILE_v4 0, 'Jul 21 2009  8:30:24:000AM', 'Dec 31 9999 12:00:00:000AM', @tblAssociateID2, 2

END
ELSE
BEGIN
	--Throw an error??
	-- User Already Exists
	PRINT 'User ' + @DCSUser + ' Already Exists'
END




GO


USE tempdb
GO

if exists (select * from sys.server_principals where name = N'CCCSNT\DCS UAT')
BEGIN
            EXEC dbo.AddDCSColleague @DCSUser = 'uatadmin', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatappoints', @OrgCentre = 355467
            EXEC dbo.AddDCSColleague @DCSUser = 'uatbusinessdev', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatbusinfo', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatcorrestmldr', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatcounsellor', @OrgCentre = 355470
----TCS Stage 3 TL:
            EXEC dbo.AddDCSColleague @DCSUser = 'uatcounseltl', @OrgCentre = 355470
            EXEC dbo.AddDCSColleague @DCSUser = 'uatcscorrespon', @OrgCentre = 355488
            EXEC dbo.AddDCSColleague @DCSUser = 'uatcspadmin', @OrgCentre = 355469
            EXEC dbo.AddDCSColleague @DCSUser = 'uatcspcounsel', @OrgCentre = 355469
            EXEC dbo.AddDCSColleague @DCSUser = 'uatcspteamlead', @OrgCentre = 355469
            EXEC dbo.AddDCSColleague @DCSUser = 'uatcsteamcoord', @OrgCentre = 355488
            EXEC dbo.AddDCSColleague @DCSUser = 'uatcsteamlead', @OrgCentre = 355488
            EXEC dbo.AddDCSColleague @DCSUser = 'uatdmpprocess', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatdmsteamlead', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatfinance', @OrgCentre = 355487
----TCSStage1:
            EXEC dbo.AddDCSColleague @DCSUser = 'UATHelpline', @OrgCentre = 355467
            EXEC dbo.AddDCSColleague @DCSUser = 'uathelplinetl', @OrgCentre = 355467
            EXEC dbo.AddDCSColleague @DCSUser = 'uatopsmanager', @OrgCentre = 355467
            EXEC dbo.AddDCSColleague @DCSUser = 'uatpayments', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatpaymentsb', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatphonecsa', @OrgCentre = 355467
            EXEC dbo.AddDCSColleague @DCSUser = 'uatsupcounsel', @OrgCentre = 375526
            EXEC dbo.AddDCSColleague @DCSUser = 'uatcounsupptl', @OrgCentre = 375526
            EXEC dbo.AddDCSColleague @DCSUser = 'uattpteamcoord', @OrgCentre = 355487
----Extra user requested by Darren Farley:
			EXEC dbo.AddDCSColleague @DCSUser = 'uatapoints', @OrgCentre = 355469;
            EXEC dbo.AddDCSColleague @DCSUser = 'uathelpline1', @OrgCentre = 355469;
			EXEC dbo.AddDCSColleague @DCSUser = 'uathelpline2', @OrgCentre = 355469;
			EXEC dbo.AddDCSColleague @DCSUser = 'uatappoints1', @OrgCentre = 355469;
			EXEC dbo.AddDCSColleague @DCSUser = 'uatcounsellor1', @OrgCentre = 355469;
			EXEC dbo.AddDCSColleague @DCSUser = 'uatcounsellor2', @OrgCentre = 355469;
			EXEC dbo.AddDCSColleague @DCSUser = 'uatcounsellor3', @OrgCentre = 355469;
			EXEC dbo.AddDCSColleague @DCSUser = 'uatcounsellor4', @OrgCentre = 355469;
			EXEC dbo.AddDCSColleague @DCSUser = 'uatcounsellor5', @OrgCentre = 355469;

END

--DCS Editors...
if exists (select * from sys.server_principals where name = N'CCCSNT\DCS Editors UAT')
BEGIN
            EXEC dbo.AddDCSColleague @DCSUser = 'uatbusinessdev', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatbusinfo', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatcspadmin', @OrgCentre = 355469
            EXEC dbo.AddDCSColleague @DCSUser = 'uatcspcounsel', @OrgCentre = 355469
            EXEC dbo.AddDCSColleague @DCSUser = 'uatcspteamlead', @OrgCentre = 355469
            EXEC dbo.AddDCSColleague @DCSUser = 'uatdmpprocess', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatdmsteamlead', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatfinance', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatpayments', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uatpaymentsb', @OrgCentre = 355487
            EXEC dbo.AddDCSColleague @DCSUser = 'uattpteamcoord', @OrgCentre = 355487
END
GO 
/* --------------------------------- */

--- New performance test users requested by Barry
-- DCS performance users	
-- = "	EXEC dbo.AddDCSColleague @DCSUser = '" & A1 & "', @OrgCentre = 355469;"
USE tempdb
GO

IF @@SERVERNAME = 'LDSGENPEF1DBA01'
BEGIN
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2a', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2aa', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ab', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ac', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ad', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ae', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2af', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ag', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ah', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ai', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2aj', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ak', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2al', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2am', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2an', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ao', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ap', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2b', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2c', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2d', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2e', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2f', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2g', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2h', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2i', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2j', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2k', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2l', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2m', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2n', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2o', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2p', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2q', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2r', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2s', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2t', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2u', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2v', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2w', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2x', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2y', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2z', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2aq', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ar', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2as', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2at', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2au', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2av', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2aw', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ax', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ay', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2az', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ba', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bb', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bc', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bd', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2be', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bf', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bg', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bh', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bi', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bj', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bk', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bl', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bm', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bn', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bo', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bp', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bq', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2br', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bs', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bt', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bu', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bv', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bw', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bx', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2by', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2bz', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ca', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cb', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cc', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cd', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ce', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cf', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cg', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ch', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ci', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cj', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ck', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cl', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cm', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cn', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2co', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cp', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cq', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cr', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cs', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ct', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cu', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cv', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cw', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cx', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cy', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2cz', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2da', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2db', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dc', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dd', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2de', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2df', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dg', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dh', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2di', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dj', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dk', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dl', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dm', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dn', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2do', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dp', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dq', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dr', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ds', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dt', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2du', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dv', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dw', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dx', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dy', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2dz', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ea', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2eb', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ec', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ed', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ee', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ef', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2eg', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2eh', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ei', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ej', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ek', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2el', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2em', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2en', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2eo', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ep', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2eq', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2er', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2es', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2et', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2eu', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ev', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ew', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ex', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ey', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2ez', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2fa', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2fb', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2fc', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefst2fd', @OrgCentre = 355469;

	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1a', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1b', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1c', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1d', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1e', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1f', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1g', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1h', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1i', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1j', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1k', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1l', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1m', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1n', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1o', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1p', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1q', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1r', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1s', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1t', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1u', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1v', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1w', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1x', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1y', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1z', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1aa', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1ab', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1ac', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1ad', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1ae', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1af', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1ag', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1ah', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1ai', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1aj', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1ak', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1al', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1am', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefdt1an', @OrgCentre = 355469;

	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1a', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1aa', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1ab', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1ac', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1ad', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1ae', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1af', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1ag', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1ah', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1ai', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1aj', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1ak', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1al', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1am', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1an', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1ao', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1b', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1c', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1d', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1e', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1f', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1g', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1h', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1i', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1j', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1k', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1l', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1m', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1n', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1o', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1p', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1q', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1r', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1s', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1t', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1u', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1v', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1w', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1x', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1y', @OrgCentre = 355469;
	EXEC dbo.AddDCSColleague @DCSUser = 'tcspefht1z', @OrgCentre = 355469;

END
GO 

/* --------------------------------- */

--- TRAINING ENVIRONMENT USERS, FEBRUARY 2012

--OrgCentres:
--355468	Leeds Office
--355469	Client Support
--355470	Leeds Counselling Office
--355487	Administration
--355488	Customer Services
--375526	Counselling Support

USE DCSLive
Go 

IF @@SERVERNAME = 'VMTRDCSPRODBA01'
BEGIN
	if exists (select * from sys.server_principals where name = N'CCCSNT\Training users')
	BEGIN
		IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\Training users')
		BEGIN
			CREATE USER [CCCSNT\Training users] FOR LOGIN [CCCSNT\Training users];
			exec sp_addrolemember  N'dcuser', N'CCCSNT\Training users';
			exec sp_addrolemember  N'dcsuser', N'CCCSNT\Training users';
		END
	END;
END ;
go 		

USE tempdb
GO

IF @@SERVERNAME = 'VMTRDCSPRODBA01'
BEGIN
		EXEC dbo.AddDCSColleague @DCSUser = 'TraineeCouns', @OrgCentre = 355470;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns1', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns10', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns11', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns12', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns13', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns14', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns15', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns16', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns17', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns18', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns19', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns2', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns20', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns21', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns22', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns23', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns24', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns25', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns3', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns4', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns5', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns6', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns7', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns8', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'traineecouns9', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'TraineeCSE', @OrgCentre = 355488;
		EXEC dbo.AddDCSColleague @DCSUser = 'TraineeCSP', @OrgCentre = 355469;
		EXEC dbo.AddDCSColleague @DCSUser = 'TraineeDMP', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'TraineeEast', @OrgCentre = 355468;
		EXEC dbo.AddDCSColleague @DCSUser = 'TraineeHLP', @OrgCentre = 355468;
		EXEC dbo.AddDCSColleague @DCSUser = 'TraineeLima', @OrgCentre = 355468;
		EXEC dbo.AddDCSColleague @DCSUser = 'TraineePay', @OrgCentre = 355468;
		EXEC dbo.AddDCSColleague @DCSUser = 'TraineeTL', @OrgCentre = 355470;
		EXEC dbo.AddDCSColleague @DCSUser = 'TrainerCouns', @OrgCentre = 355468;
		EXEC dbo.AddDCSColleague @DCSUser = 'TrainerCSE', @OrgCentre = 355468;
		EXEC dbo.AddDCSColleague @DCSUser = 'TrainerCSP', @OrgCentre = 355469;
		EXEC dbo.AddDCSColleague @DCSUser = 'TrainerDMP', @OrgCentre = 355487;
		EXEC dbo.AddDCSColleague @DCSUser = 'TrainerEAST', @OrgCentre = 355468;
		EXEC dbo.AddDCSColleague @DCSUser = 'TrainerHLP', @OrgCentre = 355468;
		EXEC dbo.AddDCSColleague @DCSUser = 'TrainerLima', @OrgCentre = 355468;
		EXEC dbo.AddDCSColleague @DCSUser = 'TrainerPay', @OrgCentre = 355468;
		EXEC dbo.AddDCSColleague @DCSUser = 'TrainerSPEC', @OrgCentre = 355468;
		EXEC dbo.AddDCSColleague @DCSUser = 'TrainerTL', @OrgCentre = 355468;
END
GO 

-- Colleagues requested by Simon Barnett 10/02/12
EXEC dbo.AddDCSColleague @DCSUser = 'AutoTCSDV', @OrgCentre = 355469;
EXEC dbo.AddDCSColleague @DCSUser = 'AutoTCS1', @OrgCentre = 355469;
EXEC dbo.AddDCSColleague @DCSUser = 'AutoTCS1TL', @OrgCentre = 355469;
EXEC dbo.AddDCSColleague @DCSUser = 'AutoTCS2', @OrgCentre = 355469;
EXEC dbo.AddDCSColleague @DCSUser = 'AutoTCS2TL', @OrgCentre = 355469;
EXEC dbo.AddDCSColleague @DCSUser = 'AutoTCS3', @OrgCentre = 355469;
EXEC dbo.AddDCSColleague @DCSUser = 'AutoTCS3TL', @OrgCentre = 355469;
EXEC dbo.AddDCSColleague @DCSUser = 'Automation1', @OrgCentre = 355469;

-- Colleagues requested by Hanu K 08/11/12
EXEC dbo.AddDCSColleague @DCSUser = 'AutoTCS1DV', @OrgCentre = 355469;
EXEC dbo.AddDCSColleague @DCSUser = 'AutoTCS1TLDV', @OrgCentre = 355469;
EXEC dbo.AddDCSColleague @DCSUser = 'AutoTCS2DV', @OrgCentre = 355469;
EXEC dbo.AddDCSColleague @DCSUser = 'AutoTCS2TLDV', @OrgCentre = 355469;
EXEC dbo.AddDCSColleague @DCSUser = 'AutoTCS3DV', @OrgCentre = 355469;
EXEC dbo.AddDCSColleague @DCSUser = 'AutoTCS3TLDV', @OrgCentre = 355469;

-- Warranty period permissions

IF @@SERVERNAME = 'VM01DCSSERVER' -- AND (GETDATE() > 'April 1 2012' AND GETDATE() < 'November 1 2012')
	BEGIN
		EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'stephenbu', @OrgCentre = 355487
		EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'davids', @OrgCentre = 355487
	END

-- AS, Sep 2012 - Requested by Environment Team
EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'nonlivedroservice', @OrgCentre = 355487;

-- TB, Jan 2013 - Requested by Alan Lo
IF @@SERVERNAME IN ( 'VMDEVDCSPRODBA1' , 'VM08DCSSERVER')
BEGIN
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'alanl', @OrgCentre = 355467
	--EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'alio', @OrgCentre = 355467
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'grahamh', @OrgCentre = 355467
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'davidk', @OrgCentre = 355467
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'adamma', @OrgCentre = 355467
END
-- JM, Sept 2013 - Requested by Alan Lo
IF @@SERVERNAME = 'VM01DCSSERVER'
BEGIN
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'alanl', @OrgCentre = 355467
END

--JM, May 2013, Requested by Dennis Potter
--Testers
USE DCSLive
GO

IF @@SERVERNAME IN ('VM02DCSPRODBA01', 'VM05DCSPRODBA01', 'VM06DCSPRODBA01', 'VM07DCSSERVER', 'VM08DCSSERVER', 'VM10DCSPRODBA01', 'VM11DCSSERVER', 'VM12DCSPRODBA01')
BEGIN
	UPDATE dbo.tblCOLLEAGUE
	SET Colleague_NT_Logon_Id = 'michaelk2'
	WHERE Colleague_NT_Logon_Id = 'michaelk'
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'michaelk', @OrgCentre = 355467
END
--Analysts
IF @@SERVERNAME IN ('VM03DCSPRODBA01')
BEGIN
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'tammyk', @OrgCentre = 355467
END
GO 


USE tempdb

-- Colleagues requested by Dennis P
EXEC dbo.AddDCSColleague @DCSUser = 'nonliveAdPl.st', @OrgCentre = 355470; --as per Adele Nelson 
EXEC dbo.AddDCSColleague @DCSUser = 'nonliveAdPl.sp', @OrgCentre = 355469; -- as per Andrew Cummings 
EXEC dbo.AddDCSColleague @DCSUser = 'nonliveAdPl.tl', @OrgCentre = 355488; -- as per Susan Roebuck
--
EXEC dbo.AddDCSColleague @DCSUser = 'nonliveDeAd.tl', @OrgCentre = 355471; -- as per Alison P
EXEC dbo.AddDCSColleague @DCSUser = 'nonliveDeAd.sp', @OrgCentre = 355470; -- as per Gareth B
EXEC dbo.AddDCSColleague @DCSUser = 'nonliveDeAd.tl', @OrgCentre = 355470; -- as per Chloe K
EXEC dbo.AddDCSColleague @DCSUser = 'nonliveHe.st', @OrgCentre = 355488; -- as per Nicolas W
EXEC dbo.AddDCSColleague @DCSUser = 'nonliveHe.tl1', @OrgCentre = 355487; -- as per Matthew Cl
EXEC dbo.AddDCSColleague @DCSUser = 'nonliveHe.tl2', @OrgCentre = 355473; -- as per Mike G
EXEC dbo.AddDCSColleague @DCSUser = 'nonliveHe.tl3', @OrgCentre = 355470; -- as per Emilie P

-- User group requested by Dennis P

USE DCSLive

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\Non-Live DCS Users')
BEGIN
	IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name='CCCSNT\Non-Live DCS Users')
	begin
		CREATE USER [CCCSNT\Non-Live DCS Users] FOR LOGIN [CCCSNT\Non-Live DCS Users]
		EXEC sp_addrolemember  'DCSUser', 'CCCSNT\Non-Live DCS Users'
		EXEC sp_addrolemember  'DCUser', 'CCCSNT\Non-Live DCS Users'
	end
END
go


/* Users for COP */
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveDCSdb2bus')
BEGIN
	IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'dcsDB2Bus')
		CREATE USER [dcsDB2Bus] FOR LOGIN [CCCSNT\nonliveDCSdb2bus] WITH DEFAULT_SCHEMA=[BusAdapter];
	IF NOT EXISTS (	SELECT *		
				FROM sys.database_principals
				WHERE name = 'DCSToBusAdapterRole'
				AND type = 'R' )
	BEGIN
		CREATE ROLE DCSToBusAdapterRole;
	END;
	EXEC sp_addrolemember N'DCSToBusAdapterRole', N'dcsDB2Bus';
END
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveDCSbus2db')
BEGIN
	IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'dcsBus2DB')
		CREATE USER [dcsBus2DB] FOR LOGIN [CCCSNT\nonliveDCSbus2db] WITH DEFAULT_SCHEMA=[BusAdapter];
	IF NOT EXISTS (	SELECT *		
				FROM sys.database_principals
				WHERE name = 'BusAdapterToDCSRole'
				AND type = 'R' )
	BEGIN
		CREATE ROLE BusAdapterToDCSRole;
	END;
	EXEC sp_addrolemember N'BusAdapterToDCSRole', N'dcsBus2DB';
END
	
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivebudgetrestser')
BEGIN
	IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'BudgetRestService')
		CREATE USER [BudgetRestService] FOR LOGIN [CCCSNT\nonlivebudgetrestser] WITH DEFAULT_SCHEMA=[BudgetService];
	IF NOT EXISTS (	SELECT *		
				FROM sys.database_principals
				WHERE name = 'BudgetServiceRole'
				AND type = 'R' )
	BEGIN
		CREATE ROLE BudgetServiceRole;
	END;
	EXEC sp_addrolemember N'BudgetServiceRole', N'BudgetRestService';
END
	
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivedebtsrestserv')
BEGIN
	IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'DebtsRestService')
		CREATE USER [DebtsRestService] FOR LOGIN [CCCSNT\nonlivedebtsrestserv] WITH DEFAULT_SCHEMA=[DebtsService];
	IF NOT EXISTS (	SELECT *		
				FROM sys.database_principals
				WHERE name = 'DebtsServiceRole'
				AND type = 'R' )
	BEGIN
		CREATE ROLE DebtsServiceRole;
	END;
	EXEC sp_addrolemember N'DebtsServiceRole', N'DebtsRestService';
END
go 

IF @@SERVERNAME='LDSDCSPRO1DBA01'
BEGIN		
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\assetsrest')
		CREATE LOGIN [CCCSNT\assetsrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
		
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\BudgetRestService')
		CREATE LOGIN [CCCSNT\BudgetRestService] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
	
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\clientsolrest')
		CREATE LOGIN [CCCSNT\clientsolrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
	
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\commsrest')
		CREATE LOGIN [CCCSNT\commsrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];

	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\clientrestser')
		CREATE LOGIN [CCCSNT\clientrestser] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
END
ELSE 
BEGIN
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveassetsrest')
		CREATE LOGIN [CCCSNT\nonliveassetsrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];

	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivebudgetrestser')
		CREATE LOGIN [CCCSNT\nonlivebudgetrestser] FROM WINDOWS WITH DEFAULT_DATABASE=[master];

	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveclientsolrest')
		CREATE LOGIN [CCCSNT\nonliveclientsolrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];

	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivecommsrest')
		CREATE LOGIN [CCCSNT\nonlivecommsrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];

	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveclientrestser')
		CREATE LOGIN [CCCSNT\nonliveclientrestser] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
END
GO

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'AssetsRest')
	DROP USER [AssetsRest];
GO
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'BudgetRestService')
	DROP USER [BudgetRestService];
GO
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'ClientSolRest')
	DROP USER [ClientSolRest];
GO
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CommsRest')
	DROP USER [CommsRest];
GO
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonliveclientrestser')
	DROP USER [CCCSNT\nonliveclientrestser];
GO 
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\clientrestser')
	DROP USER [CCCSNT\clientrestser];
GO 
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'clientrestser')
	DROP USER [clientrestser];
GO
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'DebtsRestService')
	DROP USER [DebtsRestService];
GO 

IF @@SERVERNAME = 'LDSDCSPRO1DBA01'
BEGIN
	CREATE USER [AssetsRest] FOR LOGIN [CCCSNT\assetsrest] WITH DEFAULT_SCHEMA=[dbo];
	CREATE USER [BudgetRestService] FOR LOGIN [CCCSNT\budgetrestser]  WITH DEFAULT_SCHEMA=[dbo];
	CREATE USER [ClientSolRest] FOR LOGIN [CCCSNT\clientsolrest] WITH DEFAULT_SCHEMA=[dbo];
	CREATE USER [CommsRest] FOR LOGIN [CCCSNT\commsrest] WITH DEFAULT_SCHEMA=[dbo];
	CREATE USER [clientrestser] FOR LOGIN [CCCSNT\clientrestser] WITH DEFAULT_SCHEMA=[dbo];
	CREATE USER [DebtsRestService] FOR LOGIN [CCCSNT\debtsrestserv] WITH DEFAULT_SCHEMA=[dbo];
END 	
ELSE
BEGIN
	CREATE USER [AssetsRest] FOR LOGIN [CCCSNT\nonliveassetsrest] WITH DEFAULT_SCHEMA=[dbo];
	CREATE USER [BudgetRestService] FOR LOGIN [CCCSNT\nonlivebudgetrestser]  WITH DEFAULT_SCHEMA=[dbo];
	CREATE USER [ClientSolRest] FOR LOGIN [CCCSNT\nonliveclientsolrest] WITH DEFAULT_SCHEMA=[dbo];
	CREATE USER [CommsRest] FOR LOGIN [CCCSNT\nonlivecommsrest] WITH DEFAULT_SCHEMA=[dbo];
	CREATE USER [clientrestser] FOR LOGIN [CCCSNT\nonliveclientrestser] WITH DEFAULT_SCHEMA=[dbo];
	CREATE USER [DebtsRestService] FOR LOGIN [CCCSNT\nonlivedebtsrestserv] WITH DEFAULT_SCHEMA=[dbo];
END;
GO 
IF EXISTS (	SELECT * FROM sys.database_principals WHERE name = 'BudgetServiceRole' AND type = 'R' )
BEGIN
	EXEC sp_addrolemember N'BudgetServiceRole', N'AssetsRest';
	EXEC sp_addrolemember N'BudgetServiceRole', N'BudgetRestService';
	EXEC sp_addrolemember N'BudgetServiceRole', N'ClientSolRest';
END;
GO
IF EXISTS (	SELECT * FROM sys.database_principals WHERE name = 'DebtsServiceRole' AND type = 'R' )
BEGIN
	EXEC sp_addrolemember N'DebtsServiceRole', N'AssetsRest';
	EXEC sp_addrolemember N'DebtsServiceRole', N'ClientSolRest';
	EXEC sp_addrolemember N'DebtsServiceRole', N'DebtsRestService';
END;
GO
IF EXISTS (	SELECT * FROM sys.database_principals WHERE name = 'CommsWebServiceRole' AND type = 'R' )
BEGIN
	EXEC sp_addrolemember N'CommsWebServiceRole', N'CommsRest';
	EXEC sp_addrolemember N'CommsWebServiceRole', N'CommsWebServiceUser';
END;
GO
IF EXISTS (	SELECT * FROM sys.database_principals WHERE name = 'ClientServiceRole' AND type = 'R' )
BEGIN
	EXEC sp_addrolemember N'ClientServiceRole', N'clientrestser';
END;
GO


/* thomasb (27/05/2015) - added the following users as a request from dennisp */
USE DCSLive
GO

IF LEFT(@@SERVERNAME, 4) IN ('VM02','VM03','VM05','VM06','VM07','VM08')
BEGIN
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'elysep', @OrgCentre = 355467;
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'mohandm', @OrgCentre = 355467;
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'davek', @OrgCentre = 355467;
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'martinm', @OrgCentre = 355467;
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'simonb', @OrgCentre = 355467;
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'kenl', @OrgCentre = 355467;
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'jasonh', @OrgCentre = 355467;
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'tinloonl', @OrgCentre = 355467;
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'jaaweds', @OrgCentre = 355467;
END;
GO 


/* andrews (18/08/2015) - new testers */
USE DCSLive
GO

IF LEFT(@@SERVERNAME, 4) IN ('VM02','VM03','VM05','VM06','VM07','VM08')
BEGIN
	EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'kitsak', @OrgCentre = 355467;
  EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'matthewwh', @OrgCentre = 355467;
END;
GO 

/* Requested by Crystal CC 23/09/16 */
EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'uatcscorresadddebt', @OrgCentre = 355488;
GO

/* Requested by Arandeep 23/09/16 */
EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'uatcamassociate', @OrgCentre = 355488;
GO

/* Requested by Dan B 11/10/16 */
EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'uatplanactivatedv', @OrgCentre = 355469;
EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'uatplanactivatedv', @OrgCentre = 355487;
EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'uatplanactivatedv', @OrgCentre = 355488;
EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'uatplanactivateda', @OrgCentre = 355469;
EXEC tempdb.dbo.AddDCSColleague @DCSUser = 'uatplanactivateda', @OrgCentre = 355487;
GO

-- CommunicationService user
USE DCSLive
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