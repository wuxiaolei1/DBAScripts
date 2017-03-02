/* ---- Grant Permissions ----
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 5 - Grant Permissions.sql"
*/

:on error exit
SET NOCOUNT ON
Print 'Step 5 - Grant Permissions - [NSB.Transport]'

-- Re-establish multi-user access
ALTER DATABASE [NSB.Transport] SET MULTI_USER;

USE [NSB.Transport]
GO

--Rematch the SQL Logins
--if exists (select * from sys.server_principals where name = N'SQLCompare')
--BEGIN
--	exec sp_change_users_login 'Auto_Fix', 'SQLCompare'
--END
GO 

if exists (select * from sys.server_principals where name = N'CCCSNT\IT Application Support')
BEGIN
	IF @@SERVERNAME IN ('VM01NSBPRODBA01', 'VM04NSBPRODBA01')
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
	exec sp_addrolemember  N'db_datareader', N'CCCSNT\IT Testing Team'
END

if exists (select * from sys.server_principals where name = N'CCCSNT\IT Development Team')
BEGIN
	CREATE USER [CCCSNT\IT Development Team] FOR LOGIN [CCCSNT\IT Development Team]
	exec sp_addrolemember  N'db_datareader', N'CCCSNT\IT Development Team'
END

if exists (select * from sys.server_principals where name = N'CCCSNT\IT Analysis')
BEGIN
	CREATE USER [CCCSNT\IT Analysis] FOR LOGIN [CCCSNT\IT Analysis]
	exec sp_addrolemember  N'db_datareader', N'CCCSNT\IT Analysis'
END

USE master
GO
/* Create logins */
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveassetsrest')
		CREATE LOGIN ['CCCSNT\nonliveassetsrest'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveassetsbusa')
		CREATE LOGIN ['CCCSNT\nonliveassetsbusa'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveclientrestser')
		CREATE LOGIN ['CCCSNT\nonliveclientrestser'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'cccsnt\nonliveclientbusadap')
		CREATE LOGIN ['cccsnt\nonliveclientbusadap'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveclientsolrest')
		CREATE LOGIN ['CCCSNT\nonliveclientsolrest'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveclientsolbusa')
		CREATE LOGIN ['CCCSNT\nonliveclientsolbusa'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivecolleaguerest')
		CREATE LOGIN ['CCCSNT\nonlivecolleaguerest'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'cccsnt\nonlivecolleaguebusa')
		CREATE LOGIN ['cccsnt\nonlivecolleaguebusa'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivecommsrest')
		CREATE LOGIN ['CCCSNT\nonlivecommsrest'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivecommsbusa')
		CREATE LOGIN ['CCCSNT\nonlivecommsbusa'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivebudgetrestser')
		CREATE LOGIN ['CCCSNT\nonlivebudgetrestser'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivebudgetbusa')
		CREATE LOGIN ['CCCSNT\nonlivebudgetbusa'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivedcsdb2bus')
		CREATE LOGIN ['CCCSNT\nonlivedcsdb2bus'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivedcsbus2db')
		CREATE LOGIN ['CCCSNT\nonlivedcsbus2db'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivetskremrest')
		CREATE LOGIN ['CCCSNT\nonlivetskremrest'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivetskrembusa')
		CREATE LOGIN ['CCCSNT\nonlivetskrembusa'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveddbusadap')
		CREATE LOGIN ['CCCSNT\nonliveddbusadap'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveportal')
		CREATE LOGIN ['CCCSNT\nonliveportal'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivenotesrestserv')
		CREATE LOGIN ['CCCSNT\nonlivenotesrestserv'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivedmsdb2bus')
		CREATE LOGIN ['CCCSNT\nonlivedmsdb2bus'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivedmsbus2db')
		CREATE LOGIN ['CCCSNT\nonlivedmsbus2db'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveimagingrest')
		CREATE LOGIN ['CCCSNT\nonliveimagingrest'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveimagingbusa')
		CREATE LOGIN ['CCCSNT\nonliveimagingbusa'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivenotesbusadapt')
		CREATE LOGIN ['CCCSNT\nonlivenotesbusadapt'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\erikfccservices')
		CREATE LOGIN ['CCCSNT\erikfccservices'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\erikservice')
		CREATE LOGIN ['CCCSNT\erikservice'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\erik')
		CREATE LOGIN ['CCCSNT\erik'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO 

/* Create users */
USE [NSB.Transport]
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\CIUser')
		CREATE USER [CCCSNT\CIUser] for login [CCCSNT\CIUser];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\erikfccservices')
		CREATE USER [CCCSNT\erikfccservices] for login [CCCSNT\erikfccservices];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\erikservice')
		CREATE USER [CCCSNT\erikservice] for login [CCCSNT\erikservice];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonliveassetsrest')
		CREATE USER [CCCSNT\nonliveassetsrest] for login [CCCSNT\nonliveassetsrest];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\erik')
		CREATE USER [CCCSNT\erik] for login [CCCSNT\erik];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonliveassetsbusa')
		CREATE USER [CCCSNT\nonliveassetsbusa] for login [CCCSNT\nonliveassetsbusa];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonliveclientrestser')
		CREATE USER [CCCSNT\nonliveclientrestser] for login [CCCSNT\nonliveclientrestser];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'cccsnt\nonliveclientbusadap')
		CREATE USER [cccsnt\nonliveclientbusadap] for login [cccsnt\nonliveclientbusadap];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonliveclientsolrest')
		CREATE USER [CCCSNT\nonliveclientsolrest] for login [CCCSNT\nonliveclientsolrest];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonliveclientsolbusa')
		CREATE USER [CCCSNT\nonliveclientsolbusa] for login [CCCSNT\nonliveclientsolbusa];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivecolleaguerest')
		CREATE USER [CCCSNT\nonlivecolleaguerest] for login [CCCSNT\nonlivecolleaguerest];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'cccsnt\nonlivecolleaguebusa')
		CREATE USER [cccsnt\nonlivecolleaguebusa] for login [cccsnt\nonlivecolleaguebusa];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivecommsrest')
		CREATE USER [CCCSNT\nonlivecommsrest] for login [CCCSNT\nonlivecommsrest];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivecommsbusa')
		CREATE USER [CCCSNT\nonlivecommsbusa] for login [CCCSNT\nonlivecommsbusa];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivebudgetrestser')
		CREATE USER [CCCSNT\nonlivebudgetrestser] for login [CCCSNT\nonlivebudgetrestser];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivebudgetbusa')
		CREATE USER [CCCSNT\nonlivebudgetbusa] for login [CCCSNT\nonlivebudgetbusa];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivedcsdb2bus')
		CREATE USER [CCCSNT\nonlivedcsdb2bus] for login [CCCSNT\nonlivedcsdb2bus];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivedcsbus2db')
		CREATE USER [CCCSNT\nonlivedcsbus2db] for login [CCCSNT\nonlivedcsbus2db];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonliveddbusadap')
		CREATE USER [CCCSNT\nonliveddbusadap] for login [CCCSNT\nonliveddbusadap];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivedmsdb2bus')
		CREATE USER [CCCSNT\nonlivedmsdb2bus] for login [CCCSNT\nonlivedmsdb2bus];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivedmsbus2db')
		CREATE USER [CCCSNT\nonlivedmsbus2db] for login [CCCSNT\nonlivedmsbus2db];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonliveimagingrest')
		CREATE USER [CCCSNT\nonliveimagingrest] for login [CCCSNT\nonliveimagingrest];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonliveimagingbusa')
		CREATE USER [CCCSNT\nonliveimagingbusa] for login [CCCSNT\nonliveimagingbusa];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivenotesrestserv')
		CREATE USER [CCCSNT\nonlivenotesrestserv] for login [CCCSNT\nonlivenotesrestserv];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivenotesbusadapt')
		CREATE USER [CCCSNT\nonlivenotesbusadapt] for login [CCCSNT\nonlivenotesbusadapt];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivetskremrest')
		CREATE USER [CCCSNT\nonlivetskremrest] for login [CCCSNT\nonlivetskremrest];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivetskrembusa')
		CREATE USER [CCCSNT\nonlivetskrembusa] for login [CCCSNT\nonlivetskrembusa];
GO

/* Roles */
USE [NSB.Transport]
GO
EXECUTE sp_AddRoleMember 'ErikAppRole', 'CCCSNT\erikfccservices'
EXECUTE sp_AddRoleMember 'ErikAppRole', 'CCCSNT\erikservice'
EXECUTE sp_AddRoleMember 'ErikAppRole', 'CCCSNT\erik'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\CIUser'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonliveassetsrest'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonliveassetsbusa'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonliveclientrestser'
EXECUTE sp_AddRoleMember 'db_owner', 'cccsnt\nonliveclientbusadap'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonliveclientsolrest'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonliveclientsolbusa'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivecolleaguerest'
EXECUTE sp_AddRoleMember 'db_owner', 'cccsnt\nonlivecolleaguebusa'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivecommsrest'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivecommsbusa'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivebudgetrestser'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivebudgetbusa'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivedcsdb2bus'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivedcsbus2db'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonliveddbusadap'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivedmsdb2bus'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivedmsbus2db'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonliveimagingrest'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonliveimagingbusa'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivenotesrestserv'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivenotesbusadapt'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivetskremrest'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivetskrembusa'
GO