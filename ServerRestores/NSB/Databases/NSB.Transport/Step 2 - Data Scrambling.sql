:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON

SET QUOTED_IDENTIFIER ON
go 

PRINT 'Step 2 - Scramble Data - [NSB.Transport]'


/* TB (24/11/2014): App support have advised there may be client data in this database but cannot give any more detail 
so all tables will be truncated. App support are happy just to have structure only in this db. See email from Ian Ashworth on 19/11/2014 */

USE [NSB.Transport]
GO

SELECT ROW_NUMBER() OVER(ORDER BY name) AS ID 
			, name  AS TableName
			,SCHEMA_NAME(schema_id) AS SchemaName
INTO #AllTables
FROM sys.objects 
WHERE type in (N'U');

DECLARE @i TINYINT, @maxi TINYINT;
DECLARE @sql NVARCHAR(4000);

SELECT @i=1, @maxi = MAX(ID)
FROM #AllTables;

WHILE @i <= @maxi
BEGIN
	SELECT @sql = 'TRUNCATE TABLE [' + SchemaName + '].[' + Tablename + '];'
	FROM #AllTables
	WHERE ID = @i;
	
	EXEC(@sql);
	
	SET @i = @i + 1;
END;


