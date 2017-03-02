--Support, Test and UAT User Group Logins...
--Database Users get assigned at database restore
--Jef M 13-9-2011

--Systems Release Analysts Logins for support servers
USE [master]
GO

if NOT exists (select * from sys.server_principals where name = N'CCCSNT\IT Release Analysts')
BEGIN
	CREATE LOGIN [CCCSNT\IT Release Analysts] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
	EXEC master..sp_addsrvrolemember @loginame = N'CCCSNT\IT Release Analysts', @rolename = N'sysadmin'
END

if NOT exists (select * from sys.server_principals where name = N'CCCSNT\DCS UAT')
BEGIN
	CREATE LOGIN [CCCSNT\DCS UAT] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
END

if NOT exists (select * from sys.server_principals where name = N'CCCSNT\DCS Editors UAT')
BEGIN
	CREATE LOGIN [CCCSNT\DCS Editors UAT] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
END

if NOT exists (select * from sys.server_principals where name = N'CCCSNT\DDE UAT')
BEGIN
	CREATE LOGIN [CCCSNT\DDE UAT] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
END

if NOT exists (select * from sys.server_principals where name = N'CCCSNT\IT Testing Team')
BEGIN
	CREATE LOGIN [CCCSNT\IT Testing Team] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
END

--Support Environment Logins...

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


	USE [master]
	CREATE LOGIN [AutomationTest] WITH PASSWORD=N'7tH9mY*vc64mn', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON


GO

--	IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\DCS UAT')
--	--if exists (select * from sysusers where name = 'CCCSNT\DCS UAT')
--		EXEC sp_revokedbaccess 'CCCSNT\DCS UAT'
--	CREATE USER [CCCSNT\DCS UAT] FOR LOGIN [CCCSNT\DCS UAT]
--	exec sp_addrolemember  'DCSUser', 'CCCSNT\DCS UAT'
--	exec sp_addrolemember  'DCUser', 'CCCSNT\DCS UAT'
--
--	IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\DCS Editors UAT')
--		EXEC sp_revokedbaccess 'CCCSNT\DCS Editors UAT'
--	CREATE USER [CCCSNT\DCS Editors UAT] FOR LOGIN [CCCSNT\DCS Editors UAT]
--	exec sp_addrolemember  'DCSUser', 'CCCSNT\DCS Editors UAT'
--	exec sp_addrolemember  'DCUser', 'CCCSNT\DCS Editors UAT'
--	exec sp_addrolemember  'DCEditor', 'CCCSNT\DCS Editors UAT'
--	exec sp_addrolemember  'DocuSpam', 'CCCSNT\DCS Editors UAT'
--	IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\DDE UAT')
--		EXEC sp_revokedbaccess 'CCCSNT\DDE UAT'
--	CREATE USER [CCCSNT\DDE UAT] FOR LOGIN [CCCSNT\DDE UAT]
--	exec sp_addrolemember  'DCSUser', 'CCCSNT\DDE UAT'
--	exec sp_addrolemember  'DCEditor', 'CCCSNT\DDE UAT'
--	exec sp_addrolemember  'PDD', 'CCCSNT\DDE UAT'
