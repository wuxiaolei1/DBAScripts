DECLARE		 @DBROLE VARCHAR (50)
DECLARE		 @CMD NVARCHAR (1000)
DECLARE		 @NO SMALLINT
DECLARE		 @MAXNO SMALLINT
DECLARE		 @DBNAME VARCHAR (100)


CREATE TABLE #DBS
			 (
			 DBID SMALLINT IDENTITY PRIMARY KEY
			 ,DBNAME VARCHAR (100)
			 )
			 

INSERT INTO #DBS
			(
			DBNAME 
			)
SELECT 		[NAME]
FROM 		master.dbo.sysdatabases 
WHERE 		DBID > 4
			AND  DATABASEPROPERTYEX(NAME, 'Status')  = 'ONLINE'
ORDER BY	[NAME]


CREATE TABLE #DBROLES
			 (
			 DBNAME VARCHAR (50)
			 ,DBRole VARCHAR (50)
			 ,MemberName VARCHAR (100)
			 )

CREATE TABLE #DBUSERS
			 (
			 DBRole VARCHAR (100)
			 ,MemberName VARCHAR (100)
			 ,MemberSid VARBINARY (2048)
			 )

SET @NO = 1
SET @MAXNO = (
			 SELECT		MAX (DBID)
			 FROM		#DBS
			 )
			 
WHILE @NO <= @MAXNO
	BEGIN
		SET		@DBNAME = (
						  SELECT	DBNAME
						  FROM		#DBS
						  WHERE		DBID = @NO
						  )
		
		SET @CMD =  'USE ' 
					+ @DBNAME 
					+ ' TRUNCATE TABLE #DBUSERS

						INSERT INTO #DBUSERS
						EXEC sp_helprolemember 

						INSERT INTO	#DBROLES
									(
									DBNAME
									,DBRole
									,MemberName
									)
						SELECT      db_name()
									,dbRole
									,MemberName
						FROM		#DBUSERS
						WHERE		MemberName <> ''dbo'''

			EXEC sp_executesql @CMD				
		
		SET @NO = @NO + 1
	END
	
	
SELECT		DBNAME
			,MemberName
FROM		#DBROLES
WHERE		DBROLE = 'db_owner'


IF EXISTS (
		   SELECT	1 
		   FROM		tempdb.dbo.sysobjects 
		   WHERE	NAME LIKE '#DBROLES%'
		   )
	BEGIN
		DROP TABLE #DBROLES
	END
	
IF EXISTS (
		   SELECT	1 
		   FROM		tempdb.dbo.sysobjects 
		   WHERE	NAME LIKE '#DBUSERS%'
		   )
	BEGIN
		DROP TABLE #DBUSERS
	END
	
IF EXISTS (
		   SELECT	1 
		   FROM		tempdb.dbo.sysobjects 
		   WHERE	NAME LIKE '#DBS%'
		   )
	BEGIN
		DROP TABLE #DBS
	END