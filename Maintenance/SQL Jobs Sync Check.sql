/*******************************************************************
* PURPOSE: Script to highlight any sql jobs that are not present on the 
*			HA or DR server that exist on the production server
* NOTES:   A job will be considered out of sync if it doesnt exist, or there
*			is a difference in either the description, step name, or step
*			command (except SSIS steps).
*		   Currently checks:
*				LDSTCSPRO1DBA01
*				LDSDCSPRO1DBA01
*				LDSDMSPRO1DBA01
*				LDSGENPRO1DBA02
*				LDSGENPRO1DBA03
*				LDSQMTPRO1DBA01
*				VMCLUPRO1DBA01
*				VMNSBPRO2DBA01
* AUTHOR:  Tom Braham
* CREATED DATE: 26/06/2013
* MODIFIED DETAILS
* DATE            AUTHOR                  CHGREF/DESCRIPTION
*-------------------------------------------------------------------
* {date}          {developer} {brief modification description}
*******************************************************************/

EXEC sp_configure 'show advanced options',1;
go 
RECONFIGURE
go 
EXEC sp_configure 'Ad Hoc Distributed Queries',1;
go 
RECONFIGURE
go 

/* Declare variables */
DECLARE @ProdSvr sysname, @ProdConn VARCHAR(255);
DECLARE @HASvr sysname, @HAConn VARCHAR(255);
DECLARE @DRSvr sysname, @DRConn VARCHAR(255);
DECLARE @SQL VARCHAR(MAX);

/* Create results table if it doesnt exist already */
IF OBJECT_ID('tempdb..#OutOfSyncJobs','U') IS NOT NULL
BEGIN
	drop TABLE #OutOfSyncJobs;
END;

IF OBJECT_ID('tempdb..#OutOfSyncJobs') IS NULL
BEGIN
	CREATE TABLE #OutOfSyncJobs
	(	ProductionServer sysname NOT NULL,
		JobName sysname NOT NULL,
		OutOfSyncServer sysname NOT NULL  );
END;

/* create table to hold list of servers to query */	
IF OBJECT_ID('tempdb..#AllServers') IS NOT NULL
BEGIN
	DROP TABLE #AllServers;
END

IF OBJECT_ID('tempdb..#AllServers') IS NULL
BEGIN
	CREATE TABLE #AllServers
	(	ProductionServer sysname NOT NULL,
		HAServer sysname NULL,
		DRServer sysname NOT NULL  );
END
ELSE
BEGIN
	TRUNCATE TABLE #AllServers;
END;

/* Populate server list */
INSERT INTO #AllServers 
	(	ProductionServer,
		HAServer,
		DRServer )
SELECT 	'LDSTCSPRO1DBA01','LDSGENDSR1DBA01\SQL2005STD','HLXGENDSR1DBA01'
UNION ALL
SELECT 	'LDSDCSPRO1DBA01','LDSGENDSR1DBA01','HLXGENDSR1DBA03'
UNION ALL
SELECT 	'LDSDMSPRO1DBA01','LDSGENDSR1DBA01','HLXDMSDSR1DBA02'
UNION ALL
SELECT 	'LDSGENPRO1DBA02',NULL,'HLXGENDSR1DBA01'
UNION ALL
SELECT 	'LDSGENPRO1DBA03',NULL,'HLXGENDSR1DBA04'
UNION ALL
SELECT  'LDSGENPRO1DBA04',NULL,'HLXGENDSR1DBA02'
UNION ALL
SELECT 	'LDSQMTPRO1DBA01','LDSGENDSR1DBA01\SQL2005STD','HLXGENDSR1DBA03'
UNION ALL
SELECT	'VMCLUPRO1DBA01',' VMCLUPRO2DBA01','VMCLUPRO4DBA01'
UNION ALL
SELECT	'VMNSBPRO2DBA01','VMNSBPRO3DBA01','VMNSBPRO5DBA01'
UNION ALL
SELECT	'VMWBSPRO1DBA01',NULL,'VMWBSDSR1DBA01'
UNION ALL
SELECT  'VMCIPPRO1DBA01',NULL,'HLXGENDSR1DBA04'


/* now loop through each of the servers to pull back all the APP jobs */
DECLARE SvrCursor CURSOR FAST_FORWARD FOR
	SELECT	ProductionServer,
			HAServer,
			DRServer
	FROM #AllServers ;

OPEN SvrCursor
FETCH NEXT FROM SvrCursor
	INTO @ProdSvr,@HASvr,@DRSvr;
	
WHILE @@FETCH_STATUS = 0
BEGIN	

	PRINT @ProdSvr;
	PRINT @HASvr;
	PRINT @DRSvr;
	
	/* Drop all temp tables */
	IF OBJECT_ID('tempdb..##HAJobs') IS NOT NULL
	BEGIN
		DROP TABLE ##HAJobs;
	END;
	IF OBJECT_ID('tempdb..##ProductionJobs') IS NOT NULL
	BEGIN
		DROP TABLE ##ProductionJobs;
	END;
	IF OBJECT_ID('tempdb..##DRJobs') IS NOT NULL
	BEGIN
		DROP TABLE ##DRJobs;
	END;

	/* Build connections strings */
	SET @ProdConn = 'Server=' + @ProdSvr + ';Trusted_Connection=yes;';
	SET @HAConn = 'Server=' + @HASvr + ';Trusted_Connection=yes;';
	SET @DRConn = 'Server=' + @DRSvr + ';Trusted_Connection=yes;';

	/* Clear any existing data for the server */
	IF EXISTS(SELECT * FROM #OutOfSyncJobs WHERE ProductionServer = @ProdSvr)
	BEGIN
		DELETE FROM #OutOfSyncJobs WHERE ProductionServer = @ProdSvr;
	END;

	/* Get High availability server jobs */
	IF @HASvr IS NOT NULL 
	BEGIN	
		SET @SQL = '
		SELECT a.*
		INTO ##HAJobs	
		FROM OPENROWSET(''SQLNCLI'', ''' + @HAConn + ''',
			 ''SELECT	JobName
				,DescriptionHash
				,[1] AS Step1
				,[2] AS Step2
				,[3] AS Step3
				,[4] AS Step4
				,[5] AS Step5
				,[6] AS Step6
				,[7] AS Step7
				,[8] AS Step8
				,[9] AS Step9
				,[10] AS Step10	
		FROM 
		(SELECT SJ.name AS JobName
			,SJ.job_id
			,CHECKSUM(SJ.description) AS DescriptionHash
			,SJS.step_id
			,CASE	WHEN SJS.subsystem = ''''SSIS'''' THEN CHECKSUM(SJS.step_name)
					ELSE CHECKSUM(SJS.step_name + SJS.command) 
			 END AS CommandHash
		FROM msdb.dbo.sysjobs SJ
			INNER JOIN msdb.dbo.sysjobsteps SJS
				ON SJ.job_id = SJS.job_id
		WHERE sj.name LIKE ''''APP%'''') AS a
		PIVOT(MAX(a.CommandHash) FOR a.step_id IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])) AS p;'') AS a;';

		--PRINT @SQL
		EXEC (@SQL);
	
	END ;

	/* Get High production server jobs */
	SET @SQL = '
	SELECT a.*
	INTO ##ProductionJobs	
	FROM OPENROWSET(''SQLNCLI'', ''' + @ProdConn + ''',
		 ''SELECT	JobName
			,DescriptionHash
			,[1] AS Step1
			,[2] AS Step2
			,[3] AS Step3
			,[4] AS Step4
			,[5] AS Step5
			,[6] AS Step6
			,[7] AS Step7
			,[8] AS Step8
			,[9] AS Step9
			,[10] AS Step10	
	FROM 
	(SELECT SJ.name AS JobName
		,SJ.job_id	
		,CHECKSUM(SJ.description) AS DescriptionHash
		,SJS.step_id
		,CASE	WHEN SJS.subsystem = ''''SSIS'''' THEN CHECKSUM(SJS.step_name)
					ELSE CHECKSUM(SJS.step_name + SJS.command) 
			 END AS CommandHash
	FROM msdb.dbo.sysjobs SJ
		INNER JOIN msdb.dbo.sysjobsteps SJS
			ON SJ.job_id = SJS.job_id
	WHERE sj.name LIKE ''''APP%'''') AS a
	PIVOT(MAX(a.CommandHash) FOR a.step_id IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])) AS p;'') AS a;';

	--PRINT @SQL
	EXEC (@SQL);

	/* Get disaster recovery server jobs */
	IF @DRSvr IS NOT NULL 
	BEGIN 
		SET @SQL = '
		SELECT a.*
		INTO ##DRJobs	
		FROM OPENROWSET(''SQLNCLI'', ''' + @DRConn + ''',
			 ''SELECT	JobName
				,DescriptionHash
				,[1] AS Step1
				,[2] AS Step2
				,[3] AS Step3
				,[4] AS Step4
				,[5] AS Step5
				,[6] AS Step6
				,[7] AS Step7
				,[8] AS Step8
				,[9] AS Step9
				,[10] AS Step10	
		FROM 
		(SELECT SJ.name AS JobName
			,SJ.job_id
			,CHECKSUM(SJ.description) AS DescriptionHash
			,SJS.step_id
			,CASE	WHEN SJS.subsystem = ''''SSIS'''' THEN CHECKSUM(SJS.step_name)
					ELSE CHECKSUM(SJS.step_name + SJS.command) 
			 END AS CommandHash
		FROM msdb.dbo.sysjobs SJ
			INNER JOIN msdb.dbo.sysjobsteps SJS
				ON SJ.job_id = SJS.job_id
		WHERE sj.name LIKE ''''APP%'''') AS a
		PIVOT(MAX(a.CommandHash) FOR a.step_id IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])) AS p;'') AS a;';
		
		--PRINT @SQL
		EXEC (@SQL);
	
	END ;
	

	/* record all jobs out of sync on the HA server */
	IF @HASvr IS NOT NULL 
	BEGIN
		INSERT INTO #OutOfSyncJobs
				( ProductionServer, JobName, OutOfSyncServer )
		SELECT @ProdSvr, JobName, @HASvr
		FROM (		
		SELECT * FROM ##ProductionJobs
		EXCEPT
		SELECT * FROM ##HAJobs ) AS a;
	END;

	/* record all jobs out of sync on the DR server */
	IF @DRSvr IS NOT NULL 
	BEGIN 
		INSERT INTO #OutOfSyncJobs
				( ProductionServer, JobName, OutOfSyncServer )
		SELECT @ProdSvr, JobName, @DRSvr
		FROM (		
		SELECT * FROM ##ProductionJobs
		EXCEPT
		SELECT * FROM ##DRJobs ) AS a;
	END ;
	
	FETCH NEXT FROM SvrCursor
		INTO @ProdSvr,@HASvr,@DRSvr;
END 

CLOSE SvrCursor
DEALLOCATE SvrCursor

/* remove any entries that are not applicable i.e. client retention jobs */
DELETE FROM #OutOfSyncJobs
WHERE JobName LIKE 'APP Client Retention%' 
OR JobName LIKE 'APP iFACE%'
OR JobName LIKE 'APP PDD%'
OR JobName LIKE 'APP CallTracking%'
OR JobName LIKE 'APP Credit Report%'
OR JobName LIKE 'APP DRO%'
OR JobName LIKE 'APP IVATransfer%'
OR JobName IN (
	'APP DirectDebit Archive',
	'APP DirectDebit DDeStatistics Report',
	'APP DirectDebit ExtractDDELetters',
	'APP DirectDebit Payer License Alert',
	'APP DirectDebit SetEndOfYear')
OR [JobName] LIKE 'APP - Reconciliation%'
OR [JobName] LIKE 'APP Complaints%'


/* return result set if any exists */
SELECT * FROM #OutOfSyncJobs
