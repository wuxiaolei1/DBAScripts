USE [master]
GO

if NOT exists (select * from sys.server_principals where name = N'SystemsRelease')
BEGIN
	--Systems Release Team
	CREATE LOGIN [SystemsRelease] WITH PASSWORD=N'Password4$', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
	EXEC master..sp_addsrvrolemember @loginame = N'SystemsRelease', @rolename = N'sysadmin'
END

if NOT exists (select * from sys.server_principals where name = N'SystemsTest')
BEGIN
	--Systems Testers SQL Login for DMZ / POP servers
	CREATE LOGIN [SystemsTest] WITH PASSWORD=N'Password2', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
	EXEC master..sp_addsrvrolemember @loginame = N'SystemsTest', @rolename = N'sysadmin'
END

--Permissions for SYSTEST/DEV
--Environments: VM02; VM04; VM06; VM07; VM08; VM10
IF LEFT(@@SERVERNAME, 4) IN ('VM02', 'VM04', 'VM06', 'VM07', 'VM08', 'VM10')
BEGIN
	/* Automation Test Permissions */
	IF  NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'AutomationTest')
	BEGIN
		CREATE LOGIN [AutomationTest] WITH PASSWORD=N'7tH9mY*vc64mn', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
	END
END
--Permissions for UAT/Analysis/PEF
--Environments: VM03, VM11, VM12, & PEF
--IF LEFT(@@SERVERNAME, 4) IN ('VM03', 'VM11', 'VM12') --OR SUBSTRING(@@SERVERNAME, 4, 3) = 'PEF'
--BEGIN
--	/* Automation Test Permissions */
--	IF  NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'AutomationTest')
--	BEGIN
--		CREATE LOGIN [AutomationTest] WITH PASSWORD=N'7tH9mY*vc64mn', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
--	END
--END
----Permissions for Support/Release Environments
----Environments: VM01, VM05
--IF LEFT(@@SERVERNAME, 4) IN ('VM01', 'VM05')
--BEGIN
--	SELECT @@SERVERNAME
--END
