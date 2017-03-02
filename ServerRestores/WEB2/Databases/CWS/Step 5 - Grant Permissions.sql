/* ---- Grant Permissions ----
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 5 - Grant Permissions.sql"
*/

:on error exit
SET NOCOUNT ON
Print 'Step 5 - Grant Permissions - CWS'

-- Re-establish multi-user access
ALTER DATABASE [CWS] SET MULTI_USER;

USE CWS
GO

-- Reset all passwords

update dbo.Clients
set password = 'WvflpK9w+zjfqpC0GjxVPw==',
	passwordSalt = '8357756770098897637',
	IsNewToCWS=1
--where DMSRef=0

--Rematch the SQL Logins
--exec sp_change_users_login  'Auto_Fix', 'CWSApp'
exec sp_change_users_login  'Auto_Fix', 'cwsuser'
exec sp_change_users_login  'Auto_Fix', 'CWSRefreshUser'

--Logins only added to database if present on server
if exists (select * from sys.server_principals where name = N'CCCSNT\IT Application Support')
BEGIN
	IF @@SERVERNAME IN ('VM01GENPRODBA02', 'VM04GENPRODBA02')
	BEGIN
		CREATE USER [CCCSNT\IT Application Support] FOR LOGIN [CCCSNT\IT Application Support]
		exec sp_addrolemember  N'db_owner', N'CCCSNT\IT Application Support'
	END
	ELSE
	BEGIN
		CREATE USER [CCCSNT\IT Application Support] FOR LOGIN [CCCSNT\IT Application Support]
		exec sp_addrolemember  N'db_datareader', N'CCCSNT\IT Application Support'
	END
END

if exists (select * from sys.server_principals where name = N'CCCSNT\IT Testing Team')
BEGIN
	CREATE USER [CCCSNT\IT Testing Team] FOR LOGIN [CCCSNT\IT Testing Team]
	exec sp_addrolemember  N'db_owner', N'CCCSNT\IT Testing Team'
END

if exists (select * from sys.server_principals where name = N'CCCSNT\IT Development Team')
BEGIN
	CREATE USER [CCCSNT\IT Development Team] FOR LOGIN [CCCSNT\IT Development Team]
	exec sp_addrolemember  N'db_datareader', N'CCCSNT\IT Development Team'
END

if exists (select * from sys.server_principals where name = N'CCCSNT\IT Analysis')
BEGIN
	IF @@SERVERNAME IN ('VM06GENPRODBA02')
	BEGIN
		CREATE USER [CCCSNT\IT Analysis] FOR LOGIN [CCCSNT\IT Analysis]
		exec sp_addrolemember  N'db_owner', N'CCCSNT\IT Analysis'
	END
	ELSE
	BEGIN
		CREATE USER [CCCSNT\IT Analysis] FOR LOGIN [CCCSNT\IT Analysis]
		exec sp_addrolemember  N'db_datareader', N'CCCSNT\IT Analysis'
	END
END

if exists (select * from sys.server_principals where name = N'CCCSNT\BISQLReaders')
BEGIN
	IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\BISQLReaders')
		EXEC sp_revokedbaccess 'CCCSNT\BISQLReaders'
		--DROP USER [CCCSNT\BISQLReaders]
	CREATE USER [CCCSNT\BISQLReaders] FOR LOGIN [CCCSNT\BISQLReaders]
	exec sp_addrolemember  N'db_datareader', N'CCCSNT\BISQLReaders'
END

/* --------------------------------- */
/* SQL Compare Permissions */
IF  NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'SQLCompare')
BEGIN
	CREATE USER [SQLCompare] FOR LOGIN [SQLCompare]
	EXEC sp_addrolemember N'db_datareader', N'SQLCompare'
	GRANT VIEW DEFINITION TO SQLCompare
END
ELSE
BEGIN
	exec sp_change_users_login  'Auto_Fix', 'SQLCompare'
END

/* --------------------------------- */
--Permissions for SYSTEST/DEV
--Environments: VM02; VM04; VM06; VM07; VM08; VM10
IF LEFT(@@SERVERNAME, 4) IN ('VM02', 'VM04', 'VM05', 'VM06', 'VM07', 'VM08', 'VM10')
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

