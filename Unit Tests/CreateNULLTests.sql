-- null tests
SET NOCOUNT ON ;

CREATE TABLE #Tests (
	ID INT IDENTITY(1,1),
	TestSchema sysname,
	TestName sysname,
	ExpectedErrorNumber INT,
	TestingColumnName sysname,
	TestingTableName sysname,
	TestingSchemaName sysname );

CREATE TABLE #Output (SQLText VARCHAR(MAX));

DECLARE @SQL VARCHAR(MAX);
DECLARE @TestSchema sysname;
DECLARE @TestName sysname;
DECLARE @ExpectedErrorNumber INT;
DECLARE @TestingColumnName sysname;
DECLARE @TestingTableName sysname;
DECLARE @TestingSchemaName sysname;
DECLARE @NoOfTests INT;
DECLARE @Counter INT = 1;
DECLARE @DecVarSQL NVARCHAR(MAX);
DECLARE @InsertSQL NVARCHAR(MAX);
DECLARE @InsertSQL1 NVARCHAR(MAX);
DECLARE @InsertSQL2 NVARCHAR(MAX);

INSERT INTO #Tests (
	TestSchema ,
	TestName ,
	ExpectedErrorNumber ,
	TestingColumnName ,
	TestingTableName ,
	TestingSchemaName )
SELECT 
	TestSchema ,
	TestName ,
	ExpectedErrorNumber ,
	TestingColumnName ,
	TestingTableName ,
	TestingSchemaName
FROM 
(
SELECT  --TOP 1 
		col.TABLE_SCHEMA + 'Tests' AS TestSchema,
        'test ' + col.TABLE_NAME + col.COLUMN_NAME AS TestName,
        CASE WHEN col.IS_NULLABLE = 'NO' THEN 515 ELSE 0 END AS ExpectedErrorNumber,
		col.COLUMN_NAME AS TestingColumnName,
		col.TABLE_NAME AS TestingTableName,
		col.TABLE_SCHEMA AS TestingSchemaName
FROM    INFORMATION_SCHEMA.COLUMNS col
        LEFT OUTER JOIN ( SELECT    TABLE_SCHEMA ,
                                    TABLE_NAME ,
                                    COLUMN_NAME
                            FROM      information_schema.columns
                            WHERE     COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA
                                                    + '.'
                                                    + TABLE_NAME),
                                                    column_name,
                                                    'IsIdentity') = 1
                        ) idc ON col.Table_Schema = idc.Table_Schema
                                    AND col.Table_Name = idc.Table_Name
                                    AND Col.COLUMN_NAME = idc.COLUMN_NAME
		LEFT JOIN sys.views v
			ON col.TABLE_NAME = v.name	
			AND col.TABLE_SCHEMA = schema_name(v.SCHEMA_ID)
WHERE     idc.COLUMN_NAME IS NULL
		--AND	col.TABLE_NAME = 'Colleagues' --AND col.COLUMN_NAME = 'HoldLetter2Date'
        AND col.TABLE_NAME NOT LIKE '%SysDiagrams%'
        AND col.TABLE_SCHEMA NOT IN ('tsqlt','dbo','sys','AdminTests','AuditTests','Audit')
		AND v.NAME IS NULL  -- we dont want any views
) AS rtn
LEFT OUTER JOIN (
	SELECT SPECIFIC_SCHEMA, SPECIFIC_NAME
	FROM INFORMATION_SCHEMA.ROUTINES 
	WHERE SPECIFIC_NAME LIKE 'Test %' 
) tests ON rtn.TestSchema = tests.SPECIFIC_SCHEMA AND rtn.TestName = tests.SPECIFIC_NAME
-- only return tests that havent been created
WHERE tests.SPECIFIC_NAME IS NULL;

SELECT @NoOfTests = COUNT(*) 
FROM #Tests;

WHILE @Counter <= @NoOfTests
BEGIN 
	SELECT @TestSchema			 = TestSchema,
			@TestName			 = TestName,
			@ExpectedErrorNumber = ExpectedErrorNumber,
			@TestingColumnName	 = TestingColumnName,
			@TestingTableName	 = TestingTableName,
			@TestingSchemaName	 = TestingSchemaName
	FROM	#Tests
	WHERE	ID = @Counter;

	--SELECT @ExpectedErrorNumber,@TestingColumnName,@TestingTableName,@TestName,@TestSchema

	/* get all the columns for the table */
	CREATE TABLE #Columns (ColName sysname, ColDataType sysname, ColVarName sysname);
	INSERT INTO #Columns
			( ColName,
				ColDataType,
				ColVarName )
	SELECT	c.NAME,
			t.name 
			+ CASE	
				WHEN c.collation_name IS NOT NULL AND c.max_length = -1 THEN '(MAX)' 
				WHEN c.collation_name IS NOT NULL  THEN '(' + CAST(c.max_length AS VARCHAR(5)) + ')' 
				ELSE ''
			END ,
			'@' + c.NAME
	FROM sys.columns c
		INNER JOIN sys.types t
			ON c.user_type_id = t.user_type_id
	WHERE object_id = object_id(@TestingSchemaName + '.' + @TestingTableName);

--	SELECT * FROM #Columns

	/* generate sql to populate variable declaration */
	SET @DecVarSQL = NULL;
	SELECT @DecVarSQL = COALESCE(@DecVarSQL + CHAR(13),'') +
			('DECLARE ' 
			+ ColVarName 
			+ SPACE(1) 
			+ ColDataType 
			+ CASE 
				WHEN ColDataType IN ('DateTime','Date','datetime2') THEN ' = ''20140101'';'
				WHEN ColDataType IN ('TINYINT','SMALLINT','INT','BIGINT','BIT','MONEY') THEN ' = 0;'
				WHEN ColDataType LIKE '%CHAR%' THEN ' = ''Test'';'
				END)
	FROM #Columns;

	--SELECT @DecVarSQL

	/* generate sql for the insert statement */
	SET @InsertSQL  = NULL;
	SET @InsertSQL1 = NULL;
	SET @InsertSQL2 = NULL;

	SELECT @InsertSQL1 = COALESCE(@InsertSQL1 + ',' + CHAR(13),'') + ColName,
			@InsertSQL2 = COALESCE(@InsertSQL2 + ',' + CHAR(13),'') + ColVarName
	FROM #Columns;

	SELECT @InsertSQL =
			'INSERT INTO [' + @TestingSchemaName + '].[' + @TestingTableName + '] (' + CHAR(13)
			+ @InsertSQL1 + ')' + CHAR(13)
			+ 'VALUES (' + CHAR(13)
			+ @InsertSQL2 + ');' + CHAR(13);

SELECT @SQL = '
CREATE PROCEDURE [' + @TestSchema + '].[' + @TestName + ']
AS
BEGIN
/*******************************************************************
* PURPOSE: To test to ensure a column can/cannot contain a null value
* NOTES:	Table: ' + @TestingTableName + '
*			Columns: ' + @TestingColumnName + '
*			Expected error: ' + CAST(@ExpectedErrorNumber AS VARCHAR(5)) + '
* AUTHOR:  ' + SUSER_SNAME() + '
* CREATED DATE: ' + CONVERT(VARCHAR(12),CURRENT_TIMESTAMP,112) + '
* MODIFIED DETAILS
* DATE            AUTHOR                  CHGREF/DESCRIPTION
*-------------------------------------------------------------------
* {date}          {developer} {brief modification description}
*******************************************************************/
DECLARE @ErrorNumber INT;
DECLARE @Expected INT = ' + CAST(@ExpectedErrorNumber AS VARCHAR(5)) + ';
/* Test Variables */
' + @DecVarSQL + '
	/*Act*/
	BEGIN TRY
/* ensure the test fails - remove this line */
select 1/0;

		/* Create any dependant data */

		/* set the column to null */
		SET @' + @TestingColumnName + ' = NULL;
        
		/* now try to insert the data with a null value */
' + @InsertSQL + '
	END TRY
	BEGIN CATCH
		SET @ErrorNumber = ERROR_NUMBER();
	END CATCH  
  
	/* Assert */
	EXEC tSQLt.assertEquals @Expected, @ErrorNumber;    
END;
'

	INSERT INTO #Output (SQLText)
	SELECT @SQL;

	SET @Counter += 1;
	DROP TABLE #Columns;
END 

SELECT * FROM #Output

DROP TABLE #Output;
DROP TABLE #Tests;