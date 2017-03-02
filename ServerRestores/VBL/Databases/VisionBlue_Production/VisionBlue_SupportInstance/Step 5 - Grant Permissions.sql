/* ---- Grant Permissions ----
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 5 - Grant Permissions.sql"
*/

SET NOCOUNT ON;
PRINT 'Step 5 - Grant Permissions - VisionBlue';

-- Re-establish multi-user access
ALTER DATABASE [VisionBlue_Support] SET MULTI_USER;

USE [VisionBlue_Support];
GO
-- SQL Login Fixes
exec sp_change_users_login 'auto_fix','LGX_VISIONBLUE';
exec sp_change_users_login 'auto_fix','VisionBlue';
go 
