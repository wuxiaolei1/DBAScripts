IF (SELECT LEFT (CONVERT (VARCHAR, SERVERPROPERTY('productversion')), 1)) > 8
	BEGIN
		EXEC sp_configure 'show advanced options', '1'
		RECONFIGURE
		
		CREATE TABLE #Config (
							 [name] CHAR (25)
							 ,minimum BIT
							 ,maximum BIT
							 ,config_value BIT 
							 ,run_value BIT 
							 )
		INSERT INTO #Config  (
							 [name],
							 minimum,
							 maximum,
							 config_value,
							 run_value
							 ) 
		EXEC sp_configure 'Ole Automation Procedures'	
		
		EXEC sp_configure 'Ole Automation Procedures', '1'
		RECONFIGURE
	END



DECLARE		@rs INT
DECLARE		@fso INT
DECLARE		@getdrive VARCHAR(13)
DECLARE		@drv INT
DECLARE		@driveletter CHAR(1)
DECLARE		@drivesize VARCHAR(20)
DECLARE		@NO SMALLINT
DECLARE		@MAXNO SMALLINT
DECLARE		@CONFIG BIT

CREATE TABLE #FreeSpace
			 (
			 DriveID SMALLINT IDENTITY PRIMARY KEY CLUSTERED
			 ,Drive CHAR (1)
			 ,MBFree DECIMAL (15,2)		
			 )
			 
CREATE TABLE #UsedSpace
			 (
			 DriveID SMALLINT IDENTITY PRIMARY KEY CLUSTERED
			 ,Drive CHAR (1)			
			 ,MBUsed DECIMAL (15,2)	
			 )
			 
INSERT INTO #FreeSpace 
EXEC		xp_fixeddrives

SET			@NO = 1
WHILE		@NO <=  (
					SELECT		MAX (DriveID)
					FROM		#FreeSpace
					)
	BEGIN
		SET @driveletter =  (
							SELECT		Drive 
							FROM		#FreeSpace
							WHERE		DriveID = @NO
							)


  		SET @getdrive = 'GetDrive("' + @driveletter + '")'
		EXEC @rs = sp_OACreate 'Scripting.FileSystemObject', @fso OUTPUT


		IF @rs = 0 
			BEGIN 
				EXEC @rs = sp_OAMethod @fso, @getdrive, @drv OUTPUT
			END
		IF @rs = 0 
			BEGIN
				EXEC @rs = sp_OAGetProperty @drv, 'TotalSize', @drivesize OUTPUT
			END
		IF @rs <> 0 
			BEGIN
				SET @drivesize = NULL
			END
			

		EXEC sp_OADestroy @drv
		EXEC sp_OADestroy @fso
		
		INSERT INTO #UsedSpace 
					(
					Drive
					,MBUsed
					) 
		SELECT		Drive
					,CONVERT (BIGINT, @drivesize) / 1024 / 1024 
		FROM		#FreeSpace
		WHERE		DriveID = @NO
		
		SET @NO = @NO + 1
		
	END
	
	
SELECT		F.Drive
			,F.MBFree
			,U.MBUsed
			,F.MBFree + U.MBUsed
			,F.MBFree / (F.MBFree + U.MBUsed) * 100 AS PercentageFreeSpace
FROM		#FreeSpace F
				INNER JOIN #UsedSpace U ON f.Drive = u.Drive
WHERE 		F.Drive IN ('E', 'F', 'T')
		

IF (SELECT LEFT (CONVERT (VARCHAR, SERVERPROPERTY('productversion')), 1)) > 8
	BEGIN
		SET		@CONFIG =	(
							SELECT		config_value
							FROM		#Config
							)	
		
		EXEC sp_configure 'Ole Automation Procedures', @CONFIG
		RECONFIGURE
		
		EXEC sp_configure 'show advanced options', '0'
		RECONFIGURE
	END




IF EXISTS (
		   SELECT	1 
		   FROM		tempdb.dbo.sysobjects 
		   WHERE	NAME LIKE '#FreeSpace%'
		   )
	BEGIN
		DROP TABLE #FreeSpace
	END
	
IF EXISTS (
		   SELECT	1 
		   FROM		tempdb.dbo.sysobjects 
		   WHERE	NAME LIKE '#UsedSpace%'
		   )
	BEGIN
		DROP TABLE #UsedSpace
	END
	
IF EXISTS (
		   SELECT	1 
		   FROM		tempdb.dbo.sysobjects 
		   WHERE	NAME LIKE '#Config%'
		   )
	BEGIN
		DROP TABLE #Config
	END