/* ---- Grant Permissions ----
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 5 - Grant Permissions.sql"
*/
:on error exit
SET NOCOUNT ON
Print 'Step 5 - Grant Permissions - DMS'

-- Re-establish multi-user access
ALTER DATABASE [DMS] SET MULTI_USER;

USE DMS
GO

--Rematch SQL Logins
exec sp_change_users_login 'Auto_Fix', 'DisbursementUser'
exec sp_change_users_login 'Auto_Fix', 'AccountServicesUser'
exec sp_change_users_login 'Auto_Fix', 'CWSRefreshUser'
if exists (select * from sys.server_principals where name = N'DirectDebitUser')
BEGIN
	exec sp_change_users_login 'Auto_Fix', 'DirectDebitUser'
END
if exists (select * from sys.server_principals where name = N'DMS_BMI_DWExtract')
BEGIN
	exec sp_change_users_login 'auto_fix', 'DMS_BMI_DWExtract'
END
if exists (select * from sys.server_principals where name = N'DMSRefreshUser')
BEGIN
	exec sp_change_users_login 'auto_fix', 'DMSRefreshUser'
END
exec sp_change_users_login 'Auto_Fix', 'LinkedServerLogin'
exec sp_change_users_login 'Auto_Fix', 'PDDUser'
exec sp_change_users_login 'Auto_Fix', 'ReportingServices'
exec sp_change_users_login 'Auto_Fix', 'TCS_USER'
exec sp_change_users_login 'Auto_Fix', 'wsDMSUser'
exec sp_change_users_login 'Auto_Fix', 'ReProposalsUser'
GO 

--ADD Permissions for CCCSNT\SUPPRO3_SQLAGENT
IF EXISTS (select * from sys.server_principals where name = N'CCCSNT\SUPPRO3_SQLAGENT')
BEGIN
	IF NOT EXISTS (select * from sys.database_principals where name = N'CCCSNT\SUPPRO3_SQLAGENT')
	BEGIN
		CREATE USER [CCCSNT\SUPPRO3_SQLAGENT] FOR LOGIN [CCCSNT\SUPPRO3_SQLAGENT]
		exec sp_addrolemember  N'WSS_DMSWriteback', N'CCCSNT\SUPPRO3_SQLAGENT'
		exec sp_addrolemember  N'KeyIVRRole', N'CCCSNT\SUPPRO3_SQLAGENT'
	END
END

--Create NON_LIVE ISI Data User...
USE [master]
GO
IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name =  N'CCCSNT\nonliveISIDataServic')
	CREATE LOGIN [CCCSNT\nonliveISIDataServic] FROM WINDOWS WITH DEFAULT_DATABASE=[master]

USE [DMS]
GO
IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'CCCSNT\nonliveISIDataServic')
	CREATE USER [CCCSNT\nonliveISIDataServic] FOR LOGIN [CCCSNT\nonliveISIDataServic]

EXEC sp_addrolemember N'ISIUser', N'CCCSNT\nonliveISIDataServic'
GO

-- Rematch iFACE Proxy user
USE DMS
GO 
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\VMDCSiFACE_SSISProxy')
BEGIN
	IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'DCSiFACE_SSISProxy')
	BEGIN
		ALTER  USER [DCSiFACE_SSISProxy]
		WITH LOGIN = [CCCSNT\VMDCSiFACE_SSISProxy];
	END
END
GO 

--Login to query the database
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'DMSSQLLogin')
BEGIN
	CREATE USER [DMSSQLLogin] FOR LOGIN [DMSSQLLogin]
	--EXEC dbo.sp_grantdbaccess @loginame = N'DMSSQLLogin', @name_in_db = N'DMSSQLLogin'
	EXEC sp_addrolemember N'db_datareader', N'DMSSQLLogin'
END

--Remove Domain Users
if exists (select * from sysusers where name = 'Domain Users')
EXEC sp_revokedbaccess 'Domain Users'


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
SET @AssociatedDatabase =  $(DBName)
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



--Add Application Roles...
if exists (select * from sys.database_principals where name = N'CCCSNT\IT Testing Team')
BEGIN
	exec sp_addrolemember  N'dms_user', N'CCCSNT\IT Testing Team'
	exec sp_addrolemember  N'dcs_user', N'CCCSNT\IT Testing Team'
	exec sp_addrolemember  N'DDeRole', N'CCCSNT\IT Testing Team'
	exec sp_addrolemember  N'PDD', N'CCCSNT\IT Testing Team'
END

IF @@SERVERNAME NOT LIKE  'VM01%'
BEGIN 
	if exists (select * from sys.database_principals where name = N'CCCSNT\IT Development Team')
	BEGIN
		exec sp_addrolemember  N'dms_user', N'CCCSNT\IT Development Team'
		exec sp_addrolemember  N'DDeRole', N'CCCSNT\IT Development Team'
		exec sp_addrolemember  N'PDD', N'CCCSNT\IT Development Team'
	END
 END   

if exists (select * from sys.database_principals where name = N'CCCSNT\IT Analysis')
BEGIN
	exec sp_addrolemember  N'dcs_user', N'CCCSNT\IT Analysis'
	exec sp_addrolemember  N'DDeRole', N'CCCSNT\IT Analysis'
	exec sp_addrolemember  N'PDD', N'CCCSNT\IT Analysis'
END

if exists (select * from sys.database_principals where name = N'CCCSNT\IT Integration Team')
BEGIN
	exec sp_addrolemember  N'dms_user', N'CCCSNT\IT Integration Team'
	exec sp_addrolemember  N'dcs_user', N'CCCSNT\IT Integration Team'
	exec sp_addrolemember  N'DDeRole', N'CCCSNT\IT Integration Team'
	exec sp_addrolemember  N'PDD', N'CCCSNT\IT Integration Team'
END

/*--- Add UAT Users ---*/

USE DMS
GO

--Logins added to database if on server
if exists (select * from sys.server_principals where name = N'CCCSNT\DMS UAT')
BEGIN
	IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\DMS UAT')
		EXEC sp_revokedbaccess 'CCCSNT\DMS UAT'
	CREATE USER [CCCSNT\DMS UAT] FOR LOGIN [CCCSNT\DMS UAT]
	exec sp_addrolemember  'DCS_User', 'CCCSNT\DMS UAT'
	exec sp_addrolemember  'dms_user', 'CCCSNT\DMS UAT'
	exec sp_addrolemember  'DDeRole', 'CCCSNT\DMS UAT'
	exec sp_addrolemember  'PDD', 'CCCSNT\DMS UAT'
END


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

/*--- Add Test Users to Solutions User Groups ---*/

USE DMS
GO

if exists (select * from sys.server_principals where name = N'CCCSNT\DMS UAT')
BEGIN
	EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'uatadmin'
	EXEC dbo.UK_AddUserToBusinessDevelopmentGroup @sAMAccountName = 'uatbusinessdev'
	--Commented out as it was failing due to the 'Corres Team Leader' not existing in the Group_table table
	--EXEC dbo.UK_AddUserToCorresTeamLeaderGroup @sAMAccountName = 'uatcorrestmldr'
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'uatcounsellor'
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'uatcounseltl'
	EXEC dbo.UK_AddUserToCSCorrespondenceGroup @sAMAccountName = 'uatcscorrespon'
	EXEC dbo.UK_AddUserToCSPAdministratorGroup @sAMAccountName = 'uatcspadmin'
	EXEC dbo.UK_AddUserToCSPCounsellorGroup @sAMAccountName = 'uatcspcounsel'
	EXEC dbo.UK_AddUserToCSPTeamLeaderGroup @sAMAccountName = 'uatcspteamlead'
	EXEC dbo.UK_AddUserToCSTeamCoordinatorGroup @sAMAccountName = 'uatcsteamcoord'
	EXEC dbo.UK_AddUserToCSTeamLeaderGroup @sAMAccountName = 'uatcsteamlead'
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'uatdmpprocess'
	EXEC dbo.UK_AddUserToDMSTeamLeaderGroup @sAMAccountName = 'uatdmsteamlead'
	EXEC dbo.UK_AddUserToFinanceGroup @sAMAccountName = 'uatfinance'
	EXEC dbo.UK_AddUserToOperationalManagerGroup @sAMAccountName = 'uatopsmanager'
	EXEC dbo.UK_AddUserToPaymentsGroup @sAMAccountName = 'uatpayments'
	EXEC dbo.UK_AddUserToPaymentsBGroup @sAMAccountName = 'uatpaymentsb'
	EXEC dbo.UK_AddUserToPhoneCSAGroup @sAMAccountName = 'uatphonecsa'
	EXEC dbo.UK_AddUserToDMPSupportCounsellorGroup @sAMAccountName = 'uatsupcounsel'
	EXEC dbo.UK_AddUserToDMPSupportCounsellorGroup @sAMAccountName = 'uatcounsupptl'
	EXEC dbo.UK_AddUserToTPTeamCoordinatorGroup @sAMAccountName = 'uattpteamcoord'
	--new user requested by Darren farley
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'uathelpline1';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'uathelpline2';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'uatapoints';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'uatappoints1';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'uatcounsellor1';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'uatcounsellor2';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'uatcounsellor3';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'uatcounsellor4';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'uatcounsellor5';
END

GO

-- DMS performance users requested by Barry
IF @@SERVERNAME = 'LDSDMSPEF1DBA01'
BEGIN
	--TCS Stage 3 User
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2a';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2aa';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ab';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ac';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ad';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ae';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2af';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ag';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ah';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ai';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2aj';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ak';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2al';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2am';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2an';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ao';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ap';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2b';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2c';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2d';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2e';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2f';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2g';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2h';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2i';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2j';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2k';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2l';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2m';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2n';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2o';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2p';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2q';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2r';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2s';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2t';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2u';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2v';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2w';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2x';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2y';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2z';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2aq';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ar';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2as';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2at';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2au';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2av';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2aw';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ax';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ay';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2az';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ba';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bb';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bc';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bd';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2be';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bf';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bg';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bh';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bi';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bj';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bk';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bl';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bm';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bn';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bo';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bp';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bq';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2br';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bs';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bt';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bu';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bv';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bw';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bx';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2by';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2bz';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ca';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cb';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cc';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cd';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ce';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cf';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cg';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ch';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ci';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cj';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ck';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cl';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cm';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cn';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2co';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cp';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cq';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cr';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cs';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ct';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cu';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cv';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cw';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cx';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cy';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2cz';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2da';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2db';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dc';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dd';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2de';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2df';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dg';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dh';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2di';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dj';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dk';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dl';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dm';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dn';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2do';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dp';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dq';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dr';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ds';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dt';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2du';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dv';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dw';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dx';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dy';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2dz';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ea';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2eb';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ec';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ed';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ee';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ef';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2eg';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2eh';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ei';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ej';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ek';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2el';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2em';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2en';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2eo';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ep';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2eq';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2er';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2es';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2et';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2eu';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ev';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ew';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ex';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ey';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2ez';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2fa';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2fb';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2fc';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefst2fd';

	--TCS DMP Data Verifier User
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1a';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1b';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1c';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1d';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1e';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1f';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1g';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1h';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1i';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1j';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1k';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1l';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1m';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1n';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1o';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1p';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1q';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1r';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1s';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1t';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1u';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1v';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1w';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1x';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1y';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1z';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1aa';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1ab';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1ac';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1ad';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1ae';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1af';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1ag';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1ah';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1ai';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1aj';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1ak';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1al';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1am';
	EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'tcspefdt1an';

	--TCS Stage 1 User
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1a';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1aa';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1ab';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1ac';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1ad';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1ae';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1af';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1ag';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1ah';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1ai';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1aj';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1ak';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1al';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1am';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1an';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1ao';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1b';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1c';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1d';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1e';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1f';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1g';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1h';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1i';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1j';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1k';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1l';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1m';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1n';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1o';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1p';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1q';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1r';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1s';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1t';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1u';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1v';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1w';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1x';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1y';
	EXEC dbo.UK_AddUserToCounsellorGroup @sAMAccountName = 'tcspefht1z';

END
GO 

/* --------------------------------- */

--- TRAINING ENVIRONMENT USERS, FEBRUARY 2012

USE DMS
GO

IF @@SERVERNAME = 'VMTRDMSPRODBA01'
BEGIN
		if exists (select * from sys.server_principals where name = N'CCCSNT\Training users')
		BEGIN
		if NOT exists (select * from sys.database_principals where name = N'CCCSNT\Training users')
			BEGIN
				CREATE USER [CCCSNT\Training users] FOR LOGIN [CCCSNT\Training users];
				exec sp_addrolemember  N'dms_user', N'CCCSNT\Training users';
				exec sp_addrolemember  N'dcs_user', N'CCCSNT\Training users';
			END
		END;
		EXEC dbo.UK_AddUserToCSPCounsellorGroup @sAMAccountName = 'TRAINEECSP';
		EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'TRAINEEDMP';
		EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'TRAINERDMP';
END
GO 


/* --------------------------------- */

--- ANALYST ENVIRONMENT USERS, JUNE 2012
USE DMS
GO

IF @@SERVERNAME = 'VM03DMSPRODBA01'
BEGIN
		--EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'adamjo';
		--EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'alane';
		--EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'davidst';
		--EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'rasnal';
		EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'andreww';
		EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'gordonl';
		EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'grahams';
		EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'vickramb';
		EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'philq';
		EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'lees';
		
END
GO 

--- SIT ENVIRONMENT USERS in VM08, January 2013
USE DMS
GO

IF @@SERVERNAME = 'VM08DMSPRODBA01'
BEGIN
		EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'alanl';
END
GO 

/* Create users for COP */
USE DMS
GO 

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivedmsdb2bus')
BEGIN
	IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'dmsDB2Bus')
		BEGIN
			CREATE USER [dmsDB2Bus] FOR LOGIN [CCCSNT\nonliveDMSdb2bus] WITH DEFAULT_SCHEMA=[BusAdapter];
			EXEC sp_addrolemember N'BusAdapterRole', N'dmsDB2Bus';
		END
END
	
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivedmsbus2db')
BEGIN
	IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'dmsBus2DB')
		BEGIN
			CREATE USER [dmsBus2DB] FOR LOGIN [CCCSNT\nonliveDMSbus2db] WITH DEFAULT_SCHEMA=[BusAdapter];
			EXEC sp_addrolemember N'BusAdapterRole', N'dmsBus2DB';
		END
END

GO 	

/* Create Logins */

USE master
GO
IF @@SERVERNAME = 'LDSDMSPRO1DBA01'
BEGIN
	IF NOT EXISTS(SELECT * FROM sys.server_principals WHERE Name = N'CCCSNT\assetsrest')
		CREATE LOGIN [CCCSNT\assetsrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];

	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\clientsolrest')
		CREATE LOGIN [CCCSNT\clientsolrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
END
ELSE
BEGIN
	IF NOT EXISTS(SELECT * FROM sys.server_principals WHERE Name = N'CCCSNT\nonliveassetsrest')
		CREATE LOGIN [CCCSNT\nonliveassetsrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];

	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveclientsolrest')
		CREATE LOGIN [CCCSNT\nonliveclientsolrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
END
GO
/* Create Users */
USE DMS
go
IF EXISTS (SELECT * from sys.database_principals WHERE name=N'AssetsRest')
	DROP USER [AssetsRest]

IF EXISTS (SELECT * from sys.database_principals WHERE name=N'CCCSNT\nonliveassetsrest')
	DROP USER [CCCSNT\nonliveassetsrest]

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'ClientSolRest')
	DROP USER [ClientSolRest];

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonliveclientsolrest')
	DROP USER [CCCSNT\nonliveclientsolrest];
GO
IF @@SERVERNAME = 'LDSDMSPRO1DBA01'
BEGIN
	CREATE USER [AssetsRest] FOR LOGIN [CCCSNT\assetsrest] WITH DEFAULT_SCHEMA=[dbo];

	CREATE USER [ClientSolRest] FOR LOGIN [CCCSNT\clientsolrest] WITH DEFAULT_SCHEMA=[dbo];
END
ELSE
BEGIN
	CREATE USER [AssetsRest] FOR LOGIN [CCCSNT\nonliveassetsrest] WITH DEFAULT_SCHEMA=[dbo];

	CREATE USER [ClientSolRest] FOR LOGIN [CCCSNT\nonliveclientsolrest] WITH DEFAULT_SCHEMA=[dbo];
END
GO
/* Create Roles */
IF NOT EXISTS(SELECT * from sys.database_principals where name = 'AssetsRestRole' and type='R')
BEGIN
	CREATE ROLE [AssetsRestRole]
END

IF NOT EXISTS(SELECT * from sys.database_principals where name = 'ClientSolRestRole' and type='R')
BEGIN
	CREATE ROLE [ClientSolRestRole]
END
GO
/* Associate Users to Roles */
EXEC sp_addrolemember N'AssetsRestRole',N'AssetsRest'
EXEC sp_addrolemember N'ClientSolRestRole',N'ClientSolRest'
GO
/* Role permissions */
GRANT EXEC ON [UK_WebService_AnL_CurrentDebts] to [AssetsRestRole]
GRANT EXEC ON [UK_WebService_AnL_CurrentDebts] to [ClientSolRestRole]
GRANT INSERT, UPDATE on BusAdapter.TaskLogExtensions to [BusAdapterRole]
Go


-- Added as a request by Dennis P
EXEC dbo.UK_AddUserToCSPCounsellorGroup @sAMAccountName = 'nonliveHe.tl3';
EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'nonliveHe.st';
EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'nonliveHe.tl1';
GO

/* thomasb (27/05/2015) - added the following users as a request from dennisp */
IF @@SERVERNAME IN ('VM02DMSPRODBA01','VM03DMSPRODBA01','VM05DMSPRODBA01','VM06DMSPRODBA01','VM07DMSPRODBA01','VM08DMSPRODBA01')
BEGIN
	EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'mohandm';
	EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'davek';
	EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'martinm';
	EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'simonb';
	EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'kenl';
	EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'jasonh';
	EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'elysep';
	EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'tinloonl';
	EXEC dbo.UK_AddUserToAdminGroup @sAMAccountName = 'jaaweds';	
END
GO 

/* Requested by Crystal CC 23/09/16 */
EXEC dbo.UK_AddUserToCSCorrespondenceGroup @sAMAccountName = 'uatcscorresadddebt'
GO

/* Requested by Arandeep 23/09/16 */
EXEC dbo.UK_AddUserToPaymentsGroup @sAMAccountName = 'uatcamassociate'
GO

/* Requested by Dan B 11/10/16 */
EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'uatplanactivatedv'
EXEC dbo.UK_AddUserToDMPProcessingGroup @sAMAccountName = 'uatplanactivateda'
GO

-- CommunicationService user
USE DMS
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