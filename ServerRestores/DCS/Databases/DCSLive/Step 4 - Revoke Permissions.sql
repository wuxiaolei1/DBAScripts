:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\RevokePermissions.sql"
EXEC [tempdb].[dbo].[DropSchemaAndUserIfExists] N'$(DbName)', N'BudgetRestService';
EXEC [tempdb].[dbo].[DropSchemaAndUserIfExists] N'$(DbName)', N'DebtsRestService';
EXEC [tempdb].[dbo].[DropSchemaAndUserIfExists] N'$(DbName)', N'dcsDB2Bus';
EXEC [tempdb].[dbo].[DropSchemaAndUserIfExists] N'$(DbName)', N'dcsBus2DB';
