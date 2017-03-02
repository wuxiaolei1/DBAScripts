/* ---- Grant Permissions ----
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 5 - Grant Permissions.sql"
*/

:on error exit
SET NOCOUNT ON
Print 'Step 5 - Grant Permissions - [NSB.TaskReminders.Writer.Sagas]'

-- Re-establish multi-user access
ALTER DATABASE [NSB.TaskReminders.Writer.Sagas] SET MULTI_USER;

USE [NSB.TaskReminders.Writer.Sagas]
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
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonlivetskrembusa')
		CREATE LOGIN ['CCCSNT\nonlivetskrembusa'] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO 

/* Create users */
USE [NSB.TaskReminders.Writer.Sagas]
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonlivetskrembusa')
		CREATE USER [CCCSNT\nonlivetskrembusa] for login [CCCSNT\nonlivetskrembusa];
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\CIUser')
		CREATE USER [CCCSNT\CIUser] for login [CCCSNT\CIUser];
GO

/* Roles */
USE [NSB.TaskReminders.Writer.Sagas]
GO
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\CIUser'
EXECUTE sp_AddRoleMember 'db_owner', 'CCCSNT\nonlivetskrembusa'
GO