:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\RevokePermissions.sql"
EXEC [tempdb].[dbo].[DropSchemaAndUserIfExists] N'$(DbName)', N'dmsDB2Bus';
EXEC [tempdb].[dbo].[DropSchemaAndUserIfExists] N'$(DbName)', N'dmsBus2DB';
