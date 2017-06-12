SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [Admin].[DependencyToFrom]
AS
SELECT s1.name AS from_schema
	  ,o1.Name AS from_table
	  ,s2.name AS to_schema
	  ,o2.Name AS to_table
FROM    sys.foreign_keys fk
INNER JOIN sys.objects o1 ON fk.parent_object_id = o1.object_id
INNER JOIN sys.schemas s1 ON o1.schema_id = s1.schema_id
INNER JOIN sys.objects o2 ON  fk.referenced_object_id = o2.object_id
INNER JOIN sys.schemas s2 ON o2.schema_id = s2.schema_id
WHERE NOT (s1.name = s2.name AND o1.name = o2.name);







GO


