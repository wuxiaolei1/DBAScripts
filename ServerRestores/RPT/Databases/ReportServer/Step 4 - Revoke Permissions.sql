:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\RevokePermissions.sql"
EXEC [tempdb].[dbo].[DropSchemaAndUserIfExists] N'$(DbName)', N'CCCSNT\RPTPRO1_SSRS';
