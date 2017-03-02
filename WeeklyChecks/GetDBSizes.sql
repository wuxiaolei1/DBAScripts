--sp_spaceused
DECLARE		@NO SMALLINT
DECLARE		@MAXNO SMALLINT
DECLARE		@DBNAME VARCHAR (100)
DECLARE		@CMD NVARCHAR (100)

CREATE TABLE #DBS
			 (
			 DBID SMALLINT IDENTITY PRIMARY KEY
			 ,DBNAME VARCHAR (100)
			 )


CREATE TABLE #DBEXTENTS
			 (
			 Fileid TINYINT 
			 ,FileGroup1 TINYINT
			 ,TotalExtents1 DECIMAL (16, 2)
			 ,UsedExtents1 DECIMAL (16, 2)
			 ,[Name] VARCHAR (100)
			 ,[FileName] SYSNAME 
			 )

CREATE TABLE #DBLOGS
			 (
			 DB_NAME VARCHAR(100)
			 ,Log_size DECIMAL (16, 2)
			 ,Log_used_percent DECIMAL (16, 2)
			 ,Status DECIMAL (16, 2)
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
					+ ' DBCC SHOWFILESTATS'
					
	
		INSERT INTO		#DBEXTENTS 
						(
						Fileid 
						,FileGroup1 
						,TotalExtents1 
						,UsedExtents1 
						,[Name] 
						,[FileName] 
						) 
		
		EXEC sp_executesql @CMD				
		
		SET @NO = @NO + 1
	END
	
SET @CMD =  'USE ' 
					+ @DBNAME 
					+ ' DBCC SQLPERF(logspace) WITH NO_INFOMSGS'
		
INSERT INTO		#DBLOGS
				(
				DB_NAME 
				,Log_size 
				,Log_used_percent 
				,Status 
				) 
		
EXEC sp_executesql @CMD	


SELECT		c.[name] + ' ' + 'Data:'  AS DBNAME						
			,SUM (a.UsedExtents1) * 65536.0 / 1048576.0 AS TotalSpaceUsedinMB
FROM		#DBEXTENTS a
				INNER JOIN master.dbo.sysaltfiles b ON a.FileName = b.Filename
				INNER JOIN master.dbo.sysdatabases c ON b.dbid = c.dbid				
GROUP BY	c.[name]

UNION ALL

SELECT		[DB_NAME] + ' ' + 'Log:' AS DBNAME			
			,Log_size AS TotalSpaceUsedinMB						
FROM		#DBLOGS a
				INNER JOIN #DBS b ON a.DB_NAME = b.DBNAME
ORDER BY	DBNAME
			



IF EXISTS (
		   SELECT	1 
		   FROM		tempdb.dbo.sysobjects 
		   WHERE	NAME LIKE '#DBS%'
		   )
	BEGIN
		DROP TABLE #DBS
	END
	
IF EXISTS (
		   SELECT	1 
		   FROM		tempdb.dbo.sysobjects 
		   WHERE	NAME LIKE '#DBEXTENTS%'
		   )
	BEGIN
		DROP TABLE #DBEXTENTS
	END

IF EXISTS (
		   SELECT	1 
		   FROM		tempdb.dbo.sysobjects 
		   WHERE	NAME LIKE '#DBLOGS%'
		   )
	BEGIN
		DROP TABLE #DBLOGS
	END
