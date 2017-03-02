/* ---- Grant Permissions ----
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 5 - Grant Permissions.sql"
*/

:on error exit
SET NOCOUNT ON
Print 'Step 5 - Grant Permissions - ITOperations'

-- Re-establish multi-user access
ALTER DATABASE [ITOperations] SET MULTI_USER;

USE ITOperations
GO

--Rematch the SQL Logins
--if exists (select * from sys.server_principals where name = N'SQLCompare')
--BEGIN
--	exec sp_change_users_login 'Auto_Fix', 'SQLCompare'
--END
GO 

if exists (select * from sys.server_principals where name = N'CCCSNT\IT Application Support')
BEGIN
	IF @@SERVERNAME IN ('VM01CLUPRODBA01', 'VM04CLUPRODBA01')
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

	GRANT VIEW DEFINITION TO [CCCSNT\IT Analysis];
END

GO

/* users for COP - taken from $/COP/Database/ITOperations/trunk/Redgate Setup */
/* create logins */
USE [master]
GO
/**********************************************
*	Expected Logins are:
*		ITOpsRESTService                - ITOperations rest service
*		CCCSNT\CIUser					- continuous integration (TeamCity)
*		CCCSNT\RedgateAdmin				- Redgate admin account used for audit reports
**********************************************/

/* Environment dependant logins */
/* SQL logins for services in DMZ */
IF @@SERVERNAME IN ('VMCLUPRO1DBA01','VMCLUPRO2DBA01','VMCLUPRO4DBA01')
BEGIN		
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'ITOpsRESTService')
		CREATE LOGIN [ITOpsRESTService] 
				WITH PASSWORD = 0x0200FC0D456B41CB7838A76CCCE6C4BB9141CB841E0EB62AFD0AB31F3D5C26B574C2AFA549D5DE892249F613A928AB77A9AA1F416BE7A0504109A57F7FCCA15DBDC7761A6072 HASHED, 
				SID = 0x1AB5BB6E28D8DF4C83B82D0AF2A21545, 
				DEFAULT_DATABASE = [master], CHECK_POLICY=ON, CHECK_EXPIRATION=OFF;
END
ELSE 
BEGIN
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'ITOpsRESTService')
		CREATE LOGIN [ITOpsRESTService] 
				WITH PASSWORD = 0x02003885D03DD241812E2F4862B4E0319FCA2A1532E5D8FC00451C1F2607C8CA9830222F738DCB6B92D05047D216D0797A81AC25B2BBA6D3E183767ECB28B258045133671B27 HASHED, 
				SID = 0x1AB5BB6E28D8DF4C83B82D0AF2A21545, 
				DEFAULT_DATABASE = [master], CHECK_POLICY=OFF, CHECK_EXPIRATION=OFF;
END
GO


/* All remaining logins */
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\CIUser')
	CREATE LOGIN [CCCSNT\CIUser] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english];

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\RedgateAdmin')
		CREATE LOGIN [CCCSNT\RedgateAdmin] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO


/* Create users */
/* Create users */
USE [ITOperations]
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'ITOpsRESTService')
	CREATE USER [ITOpsRESTService] FOR LOGIN [ITOpsRESTService];;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\RedgateAdmin')
	CREATE USER [CCCSNT\RedgateAdmin] FOR LOGIN [CCCSNT\RedgateAdmin];
GO

/* Assign Roles */
IF EXISTS (	SELECT * FROM sys.database_principals WHERE name = 'WebServiceRole' AND type = 'R' )
BEGIN
	EXEC sp_addrolemember N'WebServiceRole', N'ITOpsRESTService';
END;

EXEC sp_addrolemember N'db_datareader', N'CCCSNT\RedgateAdmin';

GRANT VIEW DEFINITION TO [CCCSNT\RedgateAdmin];
GO