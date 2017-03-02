/* ---- Grant Permissions ----
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 5 - Grant Permissions.sql"
*/
:on error exit
SET NOCOUNT ON
Print 'Step 5 - Grant Permissions - DMS'

-- Re-establish multi-user access
ALTER DATABASE [WebsiteServices] SET MULTI_USER;

USE WebsiteServices
GO

EXEC sp_change_users_login 'auto_fix', 'webuser'

--Reset 'davidk' user password to 'ChangeMe'
update dbo.Users
set password = 'WvflpK9w+zjfqpC0GjxVPw==',
	passwordSalt = '8357756770098897637'
--Comment Out the Line below if you want to reset all the
--Users! Testing Only
--where UserName = 'davidk'

--update PasswordPolicy.UserPasswordExpiries
--set ForcePasswordChange = 1,LastPasswordChange=CURRENT_TIMESTAMP
--where UserID in (select UserID from dbo.Users
--		where UserName = 'uattest1')

--Reset the Bad Attempts Gubbins
update PasswordPolicy.UserBadAttempts
set AttemptCount = 0
--If you want reset all the attempts count comment out the stuff below
--where UserID in (select UserID from dbo.Users
--		where UserName = 'uattest1')


--Logins only added to database if present on server
if exists (select * from sys.server_principals where name = 'CCCSNT\IT Application Support')
BEGIN
	IF @@SERVERNAME IN ('VM01GENPRODBA01', 'VM04GENPRODBA01')
	BEGIN
		EXEC sp_grantdbaccess 'CCCSNT\IT Application Support', 'CCCSNT\IT Application Support'
		exec sp_addrolemember  'db_owner', 'CCCSNT\IT Application Support'
	END
	ELSE
	BEGIN
		EXEC sp_grantdbaccess 'CCCSNT\IT Application Support', 'CCCSNT\IT Application Support'
		exec sp_addrolemember  'db_datareader', 'CCCSNT\IT Application Support'
	END
END

if exists (select * from sys.server_principals where name = 'CCCSNT\IT Testing Team')
BEGIN
	EXEC sp_grantdbaccess 'CCCSNT\IT Testing Team', 'CCCSNT\IT Testing Team'
	exec sp_addrolemember  'db_owner', 'CCCSNT\IT Testing Team'
END

if exists (select * from sys.server_principals where name = 'CCCSNT\IT Development Team')
BEGIN
	EXEC sp_grantdbaccess 'CCCSNT\IT Development Team', 'CCCSNT\IT Development Team'
	exec sp_addrolemember  'db_datareader', 'CCCSNT\IT Development Team'
END

if exists (select * from sys.server_principals where name = 'CCCSNT\IT Analysis')
BEGIN
	EXEC sp_grantdbaccess 'CCCSNT\IT Analysis', 'CCCSNT\IT Analysis'
	exec sp_addrolemember  'db_owner', 'CCCSNT\IT Analysis'
END

if exists (select * from sys.server_principals where name = 'CCCSNT\BISQLReaders')
BEGIN
	if exists (select * from sysusers where name = 'CCCSNT\BISQLReaders')
		EXEC sp_revokedbaccess 'CCCSNT\BISQLReaders'
	EXEC sp_grantdbaccess 'CCCSNT\BISQLReaders', 'CCCSNT\BISQLReaders'
	exec sp_addrolemember  'db_datareader', 'CCCSNT\BISQLReaders'
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
