-- Failed Check and missing foreign key tests
SET NOCOUNT ON ;

CREATE TABLE #Tests (
	ID INT IDENTITY(1,1),
	TestSchema sysname,
	TestName sysname,
	ExpectedErrorNumber INT,
	TestType sysname,
	TestingTableName sysname,
	TestingSchemaName sysname,
	ConstraintName sysname );

CREATE TABLE #Output (SQLText VARCHAR(MAX));

DECLARE @SQL VARCHAR(MAX);
DECLARE @TestSchema sysname;
DECLARE @TestName sysname;
DECLARE @ExpectedErrorNumber INT;
DECLARE @TestingColumnName sysname;
DECLARE @TestingTableName sysname;
DECLARE @TestingSchemaName sysname;
DECLARE @ConstraintName sysname;
DECLARE @TestType sysname;
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
	TestType ,
	TestingTableName ,
	TestingSchemaName ,
	ConstraintName)
SELECT 
	TestSchema ,
	TestName ,
	ExpectedErrorNumber ,
	TestType ,
	TestingTableName ,
	TestingSchemaName ,
	ConstraintName
FROM 
(
SELECT --TOP 1 
 TABLE_SCHEMA + 'Tests' TestSchema,
 'test ' + TABLE_NAME + CONSTRAINT_NAME AS TestName,
  CASE CONSTRAINT_TYPE WHEN 'Check' THEN 547 WHEN 'FOREIGN KEY' THEN 547 ELSE NULL END AS ExpectedErrorNumber,
  CONSTRAINT_TYPE AS [TestType],
  TABLE_NAME AS TestingTableName,
  TABLE_SCHEMA AS TestingSchemaName,
  CONSTRAINT_NAME AS ConstraintName
FROM   INFORMATION_SCHEMA.TABLE_CONSTRAINTS
	WHERE    CONSTRAINT_TYPE IN ( 'FOREIGN KEY','CHECK')
	AND TABLE_NAME NOT LIKE '%SysDiagrams%'
	AND TABLE_SCHEMA <> 'tsqlt'
	AND TABLE_SCHEMA <> 'dbo'  
	AND TABLE_SCHEMA <> 'sys' 
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
			@TestType			 = TestType,
			@TestingTableName	 = TestingTableName,
			@TestingSchemaName	 = TestingSchemaName,
			@ConstraintName		 = ConstraintName
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
* PURPOSE: To test the constraint is enforced
* NOTES:	Table: ' + @TestingTableName + '
*			Constraint: ' + @ConstraintName + '
*			Type: ' + @TestType + '
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
/*  Test Variables */
' + @DecVarSQL + '
/*  Act  */
	BEGIN TRY
			/* Create any dependant data */
     
		/* now try to insert the data that breaks the constraint */
' + @InsertSQL + '

/* ensure the test fails - remove this line */
select 1/0;

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