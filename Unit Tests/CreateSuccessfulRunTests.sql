-- Successful Run tests
/* Data types currently supported are 
		DateTime
		DATE
		TINYINT
		SMALLINT
		INT
		BIGINT
		NVARCHAR
		VARCHAR
		CHAR
		MONEY
		BIT	
*/
SET NOCOUNT ON ;

CREATE TABLE #Tests (
	ID INT IDENTITY(1,1),
	TestSchema sysname,
	TestName sysname,
	ExpectedErrorNumber INT,
	TestingObjectName sysname NULL,
	TestingParentObjectName sysname,
	TestingSchemaName sysname );

CREATE TABLE #Output (SQLText VARCHAR(MAX));

DECLARE @SQL VARCHAR(MAX);
DECLARE @TestSchema sysname;
DECLARE @TestName sysname;
DECLARE @ExpectedErrorNumber INT;
DECLARE @TestingObjectName sysname;
DECLARE @TestingParentObjectName sysname;
DECLARE @TestingSchemaName sysname;
DECLARE @NoOfTests INT;
DECLARE @Counter INT = 1;
DECLARE @DecVarSQL NVARCHAR(MAX);
DECLARE @ExecSQL NVARCHAR(MAX);
DECLARE @ExecSQL1 NVARCHAR(MAX);

INSERT INTO #Tests (
	TestSchema ,
	TestName ,
	ExpectedErrorNumber ,
	TestingObjectName ,
	TestingParentObjectName ,
	TestingSchemaName )
SELECT 
	TestSchema ,
	TestName ,
	ExpectedErrorNumber ,
	TestingObjectName ,
	TestingParentObjectName ,
	TestingSchemaName
FROM 
(
SELECT 
	SPECIFIC_SCHEMA + 'Tests' TestSchema, 
	'test ' + SPECIFIC_NAME AS TestName, 
	0 AS ExpectedErrorNumber,
	NULL AS TestingObjectName,
	SPECIFIC_NAME AS TestingParentObjectName,
	SPECIFIC_SCHEMA AS TestingSchemaName
	FROM INFORMATION_SCHEMA.ROUTINES 
	WHERE SPECIFIC_NAME NOT LIKE 'Test %' 
	AND SPECIFIC_NAME NOT LIKE '%SysDiagrams%'
	AND ROUTINE_SCHEMA <> 'tsqlt'
	AND ROUTINE_SCHEMA <> 'dbo'  
	AND ROUTINE_SCHEMA <> 'sys'  
	AND ROUTINE_TYPE = 'PROCEDURE'
	--AND SPECIFIC_NAME = 'GetAllCases'
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
			@TestingObjectName	 = TestingObjectName,
			@TestingParentObjectName	 = TestingParentObjectName,
			@TestingSchemaName	 = TestingSchemaName
	FROM	#Tests
	WHERE	ID = @Counter;

	--SELECT @ExpectedErrorNumber,@TestingObjectName,@TestingParentObjectName,@TestName,@TestSchema,@TestingSchemaName

	/* get all the columns for the sp */
	CREATE TABLE #Columns (ColName sysname, ColDataType sysname, ColVarName sysname, IsOutput bit);
	INSERT INTO #Columns
			( ColName,
				ColDataType,
				ColVarName,
				IsOutput )
	SELECT	REPLACE(params.NAME,'@','') AS ColumnName,
			t.name 
			+ CASE	
				WHEN t.collation_name IS NOT NULL AND params.max_length = -1 THEN '(MAX)' 
				WHEN t.collation_name IS NOT NULL  THEN '(' + CAST(params.max_length AS VARCHAR(5)) + ')' 
				ELSE ''
			END ,
			params.NAME,
			is_output
	FROM sys.procedures procs
		INNER JOIN sys.parameters params	
			ON procs.object_id = params.object_id
		INNER JOIN sys.types t
				ON params.user_type_id = t.user_type_id
	WHERE procs.object_id = object_id(@TestingSchemaName + '.' + @TestingParentObjectName);


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

	/* generate sql for the execute statement */
	SET @ExecSQL  = NULL;
	SET @ExecSQL1 = NULL;

	SELECT @ExecSQL1 = COALESCE(@ExecSQL1 + ',' + CHAR(13),'') + ColVarName + CASE IsOutput WHEN 1 THEN ' OUTPUT' ELSE '' END
	FROM #Columns;

	SELECT @ExecSQL =
			'EXECUTE [' + @TestingSchemaName + '].[' + @TestingParentObjectName + '] ' + CHAR(13)
			+ COALESCE(@ExecSQL1,'') + ';' + CHAR(13)

SELECT @SQL = '
CREATE PROCEDURE [' + @TestSchema + '].[' + @TestName + ']
AS
BEGIN
/*******************************************************************
* PURPOSE: To test the successful execution of a stored procedure
* NOTES:	SP: ' + @TestingParentObjectName + '
*			Expected error: ' + CAST(@ExpectedErrorNumber AS VARCHAR(5)) + '
* AUTHOR:  ' + SUSER_SNAME() + '
* CREATED DATE: ' + CONVERT(VARCHAR(12),CURRENT_TIMESTAMP,112) + '
* MODIFIED DETAILS
* DATE            AUTHOR                  CHGREF/DESCRIPTION
*-------------------------------------------------------------------
* {date}          {developer} {brief modification description}
*******************************************************************/
DECLARE @ErrorNumber INT;
DECLARE @ErrorMessage VARCHAR(MAX);
DECLARE @Expected INT = ' + CASE WHEN @ExpectedErrorNumber = 0 THEN 'NULL' ELSE CAST(@ExpectedErrorNumber AS VARCHAR(5)) END + ';
/* Test Variables */
' + COALESCE(@DecVarSQL,'') + '
	/* Act */
	BEGIN TRY
			/* Create any dependant data */
        
		/* EXECUTE THE SP */
' + @ExecSQL + '

/* ensure the test fails - remove this line */
select 1/0;

	END TRY
	BEGIN CATCH
		SET @ErrorNumber = ERROR_NUMBER();
	END CATCH  
  
	/* Assert */
	/******* CREATE SP ***********
	  IF @<Enter primary key value variable> IS NULL
	  BEGIN
		SET @ErrorMessage = N''Expected a <Enter primary key value variable>, got NULL'';  
		EXEC tSQLt.Fail @ErrorMessage;
	  END 
	  ELSE
	*****************************/ 
	/******* DELETE SP ***********
	  IF @RowsDeleted <> 1
	  BEGIN
		SET @ErrorMessage = N''Expected number of rows not deleted'';  
		EXEC tSQLt.Fail @ErrorMessage;
	  END 
	  ELSE 
	*****************************/ 
	/******* UPDATE SP ***********
	  IF @RowsUpdated <> 1
	  BEGIN
		SET @ErrorMessage = N''Expected number of rows not updated'';  
		EXEC tSQLt.Fail @ErrorMessage;
	  END  
	  ELSE
	*****************************/ 
	  BEGIN
		EXEC tSQLt.assertEquals @Expected, @ErrorNumber;	
	  END
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