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
--exec sp_change_users_login  'Auto_Fix', 'upd'
if exists (select * from sys.server_principals where name = N'DROUser')
BEGIN
	exec sp_change_users_login 'Auto_Fix', 'DROUser'
END
if exists (select * from sys.server_principals where name = N'shoretelUser')
BEGIN
	exec sp_change_users_login 'Auto_Fix', 'shoretelUser'
END

--Logins only added to database if present on server
if exists (select * from sys.server_principals where name = 'CCCSNT\IT Application Support')
BEGIN
	IF @@SERVERNAME IN ('VM01WEBPRODBA01', 'VM04WEBPRODBA01')
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

if exists (select * from sys.server_principals where name = 'SystemsTest')
BEGIN
	if exists (select * from sysusers where name = 'SystemsTest')
		EXEC sp_revokedbaccess 'SystemsTest'
	EXEC sp_grantdbaccess 'SystemsTest', 'SystemsTest'
	exec sp_addrolemember  'db_datareader', 'SystemsTest'

	UPDATE DebtRemedy_Live.dbo.Counsellors SET LastPasswordChange = GETDATE()-1
	WHERE LoginName = 'autotest'
	
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
/* SQL Compare Permissions */
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'SQLCompare')
BEGIN
	CREATE USER [SQLCompare] FOR LOGIN [SQLCompare]
END

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'SQLCompare')
BEGIN
	exec sp_change_users_login  'Auto_Fix', 'SQLCompare'
	EXEC sp_addrolemember N'db_datareader', N'SQLCompare'
	GRANT VIEW DEFINITION TO SQLCompare
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
			EXEC sp_addrolemember N'db_datareader', N'AutomationTest'
			EXEC sp_addrolemember N'db_datawriter', N'AutomationTest'
			GRANT VIEW DEFINITION TO [AutomationTest]
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

	if exists (select * from sys.server_principals where name IN( 'CCCSNT\IT Testing Team', 'SystemsTest'))
	BEGIN	
		/* TB Updated testers list - 30/10/2015 */
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('ArdeshirD');
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('BarryW');
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('BenF');	
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('SarahBa');		
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('KirstyR');
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('ArronC');			
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('alistairs');		
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('darrens');		
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('kitsak');		
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('michaelk');		
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('rachaelt');		
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('sangeethas');
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('sureshg');		
		INSERT INTO #TesterCounsellors (LoginName) VALUES ('vinoliap');
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


declare @CounsellorID uniqueidentifier
declare @Start datetime
declare @Finish datetime
set @Start = CURRENT_TIMESTAMP
set @Finish = DateAdd(Year, 5, CURRENT_TIMESTAMP)
if not exists(select CounsellorID from Counsellors where LoginName = 'autotest')
execute addCounsellorTimeSpan 'autotest',    'X6/z2Keo7SWgvw8kr8bbTA==', 3003894845782124756, 'autotest','autotest', @Start, @Finish, @CounsellorID OUTPUT
update dbo.Counsellors set ForcePasswordChange=0 where LoginName = 'autotest'
update dbo.CounsellorsValidIPs set Finish = DateAdd(Year, 5, CURRENT_TIMESTAMP)


/*RedGate Automated Compare Permissions*/
IF @@SERVERNAME = 'VM01GENPRODBA02'
BEGIN
	USE [DebtRemedy_Live]
	EXEC sp_addrolemember N'db_datareader', N'CCCSNT\RedgateAdmin'

	Use [master]
	Grant View Any Definition To [CCCSNT\RedgateAdmin]

END