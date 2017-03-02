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


CREATE TABLE #DBUSERS
			 (
			 DBNAME VARCHAR (50)			 
			 ,MemberSid VARBINARY (2048)
			 ,MemberName VARCHAR (100)
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
					+ ' INSERT INTO #DBUSERS
									(
									DBNAME 		 
									,MemberSid 
									,MemberName 
									)

						SELECT		DB_NAME()
									,sid 
									,[name]		
						FROM		dbo.sysusers u 
						WHERE		issqlrole = 0
									AND isapprole = 0
									AND [name] <> ''dbo''
									AND [name] <> ''guest''
									AND sid IS NOT NULL
						'

			EXEC sp_executesql @CMD				
		
		SET @NO = @NO + 1
	END
	
	
SELECT		l.[NAME] AS LOGIN 
			,u.DBNAME			
			,u.MemberName AS UserName 		
FROM		master.dbo.syslogins l
				LEFT JOIN #DBUSERS u ON l.sid = u.MemberSid
WHERE		u.MemberName IS NULL
			AND l.[NAME] <> 'sa'
			AND RIGHT (l.[NAME], 5) <> 'MSSQL'
			AND RIGHT (l.[NAME], 5) <> 'Agent'

UNION

SELECT		l.[NAME] AS LOGIN 
			,u.DBNAME			
			,u.MemberName AS UserName 	
FROM		master.dbo.syslogins l
				RIGHT JOIN #DBUSERS u ON l.sid = u.MemberSid
WHERE		l.[NAME] IS NULL



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