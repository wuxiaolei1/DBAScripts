/* ---- Grant Permissions ----
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 5 - Grant Permissions.sql"
*/

:on error exit
SET NOCOUNT ON
Print 'Step 5 - Grant Permissions - ClientSolution'

-- Re-establish multi-user access
ALTER DATABASE [ClientSolution] SET MULTI_USER;

USE ClientSolution
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

/* users for COP - taken from $/COP/Database/ClientSolution/Trunk/Redgate Setup*/
/* create logins */
USE [master]
GO
/**********************************************
*	Expected Logins are:
*		CCCSNT\nonliveimagingrest		- non live imaging rest service
*		CCCSNT\imagingrest                      - live imaging rest service
*		CCCSNT\CIUser					- continuous integration (TeamCity)
*		CCCSNT\RedgateAdmin				- Redgate admin account used for audit reports
**********************************************/

/* Environment dependant logins */
IF @@SERVERNAME IN ('VMCLUPRO1DBA01','VMCLUPRO2DBA01','VMCLUPRO4DBA01')
BEGIN		
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\clientsolrest')
		CREATE LOGIN [CCCSNT\clientsolrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
END
ELSE 
BEGIN
	IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\nonliveclientsolrest')
		CREATE LOGIN [CCCSNT\nonliveclientsolrest] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
END
GO

/* All remaining logins */
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\CIUser')
	CREATE LOGIN [CCCSNT\CIUser] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english];

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'CCCSNT\RedgateAdmin')
		CREATE LOGIN [CCCSNT\RedgateAdmin] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO

/* Create users */
USE [ClientSolution]
GO

/* Drop schemas if they exist */
IF  EXISTS (SELECT * FROM sys.schemas WHERE name = N'ClientSolRest')
	DROP SCHEMA [ClientSolRest]
GO

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\nonliveclientsolrest')
	DROP USER [CCCSNT\nonliveclientsolrest];
	
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\clientsolrest')
	DROP USER [CCCSNT\clientsolrest];		
	
IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'ClientSolRest')
	DROP USER [ClientSolRest];

IF  EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\RedgateAdmin')
	DROP USER [CCCSNT\RedgateAdmin]
GO

IF @@SERVERNAME IN ('VMCLUPRO1DBA01','VMCLUPRO2DBA01','VMCLUPRO4DBA01')
BEGIN
	CREATE USER [ClientSolRest] FOR LOGIN [CCCSNT\clientsolrest] WITH DEFAULT_SCHEMA=[dbo];
	
END 	
ELSE
BEGIN
	CREATE USER [ClientSolRest] FOR LOGIN [CCCSNT\nonliveclientsolrest] WITH DEFAULT_SCHEMA=[dbo];
END;
GO 

CREATE USER [CCCSNT\RedgateAdmin] FOR LOGIN [CCCSNT\RedgateAdmin];

/* Assign Roles */
IF EXISTS (	SELECT * FROM sys.database_principals WHERE name = 'WebServiceRole' AND type = 'R' )
BEGIN
	EXEC sp_addrolemember N'WebServiceRole', N'ClientSolRest';
END;

EXEC sp_addrolemember N'db_datareader', N'CCCSNT\RedgateAdmin';
GO
GRANT VIEW DEFINITION TO [CCCSNT\RedgateAdmin];
GO