DECLARE		 @DBROLE VARCHAR (50)
DECLARE		 @CMD VARCHAR (1000)


CREATE TABLE #DBUSERS
			 (
			 DBNAME VARCHAR (50)			 
			 ,MemberSid VARBINARY (2048)
			 ,MemberName VARCHAR (100)
			 )


SET @CMD = 'use ?

INSERT INTO #DBUSERS
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

EXEC sp_MSForEachDB @CMD


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

