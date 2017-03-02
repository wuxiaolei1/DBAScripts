:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"

USE ITOperations
GO

-- all environments require this data to be truncated
TRUNCATE TABLE [Internal].[RefreshToken];