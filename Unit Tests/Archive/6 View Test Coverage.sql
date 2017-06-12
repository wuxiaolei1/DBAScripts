


CREATE VIEW [Admin].[TestCoverage]
AS
SELECT TestSchema, TestName, TestType, ExpectedErrorNumber, CASE WHEN tests.SPECIFIC_NAME IS NULL THEN 0 ELSE 1 END AS TestCreated
FROM (
	SELECT col.TABLE_SCHEMA + 'Tests' TestSchema, 'testNull ' + col.TABLE_NAME + col.COLUMN_NAME AS TestName, 'NULL Test' AS TestType, CASE WHEN col.IS_NULLABLE = 'NO' THEN 515 ELSE 0 END AS ExpectedErrorNumber 
	FROM INFORMATION_SCHEMA.COLUMNS col
	LEFT OUTER JOIN (
		SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME
		FROM information_schema.columns 
		WHERE COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME),column_name,'IsIdentity')=1
	) idc ON col.Table_Schema = idc.Table_Schema AND col.Table_Name = idc.Table_Name AND Col.COLUMN_NAME = idc.COLUMN_NAME
	WHERE idc.COLUMN_NAME IS NULL
	AND col.TABLE_NAME NOT LIKE '%SysDiagrams%'
	AND col.TABLE_SCHEMA <> 'tsqlt'
	AND col.TABLE_SCHEMA <> 'dbo'      
	AND col.TABLE_SCHEMA <> 'sys'      
	UNION
	SELECT TABLE_SCHEMA + 'Tests' TestSchema, 'testCheck ' + TABLE_NAME + CONSTRAINT_NAME AS TestName, CASE CONSTRAINT_TYPE WHEN 'Check' THEN 'Failed Check' WHEN 'FOREIGN KEY' THEN 'Missing Foreign Key' ELSE 'Unknown' END AS TestType, CASE CONSTRAINT_TYPE WHEN 'Check' THEN 547 WHEN 'FOREIGN KEY' THEN 547 ELSE NULL END AS ExpectedErrorNumber 
	FROM   INFORMATION_SCHEMA.TABLE_CONSTRAINTS
	WHERE    CONSTRAINT_TYPE <> 'PRIMARY KEY'
	AND TABLE_NAME NOT LIKE '%SysDiagrams%'
	AND TABLE_SCHEMA <> 'tsqlt'
	AND TABLE_SCHEMA <> 'dbo'  
	AND TABLE_SCHEMA <> 'sys'  
	UNION
	SELECT SCHEMA_NAME(so.schema_id) + 'Tests' TestSchema, 'testDuplicate ' + so.[Name] + si.[Name] AS TestName, 'Duplicate Test' AS TestType, 2601 AS ExpectedErrorNumber  
	FROM sys.indexes si
	INNER JOIN sys.objects so ON si.object_id = so.object_id
	WHERE is_unique = 1
	AND si.[Type] <> 1
	AND so.[Name] NOT LIKE '%SysDiagrams%'
	AND SCHEMA_NAME(so.schema_id) <> 'tsqlt'
	AND SCHEMA_NAME(so.schema_id) <> 'dbo'  
	AND SCHEMA_NAME(so.schema_id) <> 'sys'  
	UNION
	SELECT SPECIFIC_SCHEMA + 'Tests' TestSchema, 'testSuccess ' + SPECIFIC_NAME AS TestName, 'Successful Run' AS TestType, 0 AS ExpectedErrorNumber 
	FROM INFORMATION_SCHEMA.ROUTINES 
	WHERE SPECIFIC_NAME NOT LIKE 'Test %' 
	AND SPECIFIC_NAME NOT LIKE '%SysDiagrams%'
	AND ROUTINE_SCHEMA <> 'tsqlt'
	AND ROUTINE_SCHEMA <> 'dbo'  
	AND ROUTINE_SCHEMA <> 'sys'  
	UNION
	SELECT    [col].[TABLE_SCHEMA] + 'Tests' [TestSchema] ,
                        'testCharLength ' + [col].[TABLE_NAME] + [col].[COLUMN_NAME] AS [TestName] ,
                        'Character Length Test' AS [TestType] ,
                        CASE WHEN [col].[CHARACTER_MAXIMUM_LENGTH] IS NOT NULL
                             THEN 8152
                             ELSE NULL
                        END AS [ExpectedErrorNumber]
              FROM      [INFORMATION_SCHEMA].[COLUMNS] [col]
			  WHERE col.TABLE_SCHEMA <> 'tsqlt'
	AND col.TABLE_SCHEMA <> 'dbo'      
	AND col.TABLE_SCHEMA <> 'sys' 
	AND [col].[CHARACTER_MAXIMUM_LENGTH] IS NOT NULL
	UNION
	SELECT    [col].[TABLE_SCHEMA] + 'Tests' [TestSchema] ,
                        'testDefaultValue ' + [col].[TABLE_NAME] + [col].[COLUMN_NAME] AS [TestName] ,
                        'Default Value Test' AS [TestType] ,
                        CASE WHEN [col].[COLUMN_DEFAULT] IS NOT NULL
                             THEN 0
                             ELSE NULL
                        END AS [ExpectedErrorNumber]
              FROM      [INFORMATION_SCHEMA].[COLUMNS] [col]
			  WHERE col.TABLE_SCHEMA <> 'tsqlt'
	AND col.TABLE_SCHEMA <> 'dbo'      
	AND col.TABLE_SCHEMA <> 'sys' 
	AND [col].[COLUMN_DEFAULT] IS NOT NULL

) rtn
LEFT OUTER JOIN (
	SELECT SPECIFIC_SCHEMA, SPECIFIC_NAME
	FROM INFORMATION_SCHEMA.ROUTINES 
	WHERE SPECIFIC_NAME LIKE 'Test %' 
) tests ON rtn.TestSchema = tests.SPECIFIC_SCHEMA AND rtn.TestName = tests.SPECIFIC_NAME









GO


