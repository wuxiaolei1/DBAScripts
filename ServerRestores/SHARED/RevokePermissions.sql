USE [tempdb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[tempdb].[dbo].[DropSchemaAndUserIfExists]', 'P') IS NOT NULL
	SET NOEXEC ON;
GO
-- STUB
CREATE PROCEDURE [dbo].[DropSchemaAndUserIfExists] (@DbName SYSNAME, @UserName SYSNAME) AS BEGIN SELECT (NULL); END;
GO
SET NOEXEC OFF;
GO
-- DEFINITION
ALTER PROCEDURE [dbo].[DropSchemaAndUserIfExists] (@DbName SYSNAME, @UserName SYSNAME)
AS
BEGIN
	DECLARE @Sql NVARCHAR(4000), @SchemaName SYSNAME, @PrincipalName SYSNAME;
	SET @Sql = N'SELECT @sch = s.name, @ppl = dp.name FROM [' + @DbName + N'].sys.database_principals dp
LEFT JOIN [' + @DbName + N'].sys.schemas s ON dp.principal_id = s.principal_id
WHERE dp.name = @usr AND type IN (''G'', ''S'', ''U'')';
	EXEC sp_executesql @Sql, N'@usr SYSNAME, @sch SYSNAME OUTPUT, @ppl SYSNAME OUTPUT', @usr = @UserName, @sch = @SchemaName OUTPUT, @ppl = @PrincipalName OUTPUT;
	IF @PrincipalName IS NOT NULL BEGIN
		SET @Sql = N'USE [' + @DbName + N']
';
		IF @SchemaName IS NOT NULL
			SET @Sql = @Sql + N'DROP SCHEMA [' + @SchemaName + N']
';
		SET @Sql = @Sql + N'DROP USER [' + @PrincipalName + N']
';
		PRINT N'Executing...
' + @Sql;
		EXEC (@Sql);
	END;
END;
GO

EXEC [tempdb].[dbo].[DropSchemaAndUserIfExists] N'$(DbName)', N'CCCSNT\Systems Application Support';
EXEC [tempdb].[dbo].[DropSchemaAndUserIfExists] N'$(DbName)', N'Systems Application Support';
EXEC [tempdb].[dbo].[DropSchemaAndUserIfExists] N'$(DbName)', N'CCCSNT\Systems Testers';
EXEC [tempdb].[dbo].[DropSchemaAndUserIfExists] N'$(DbName)', N'CCCSNT\Systems Development';
EXEC [tempdb].[dbo].[DropSchemaAndUserIfExists] N'$(DbName)', N'Systems Development';
EXEC [tempdb].[dbo].[DropSchemaAndUserIfExists] N'$(DbName)', N'CCCSNT\Systems Analysis';
