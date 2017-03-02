/*******************************************************************
* PURPOSE: Script to highlight any sql jobs that are not present on the 
*			Daily servers that exist on the production server and those that exist in support but not on daily
* NOTES:   A job will be considered out of sync if it doesnt exist, or there
*			is a difference in either the description, step name, or step
*			command (except SSIS steps).
*		   Currently checks:
*				LDSTCSPRO1DBA01
*				LDSDCSPRO1DBA01
*				LDSDMSPRO1DBA01
*				LDSGENPRO1DBA02
*				LDSGENPRO1DBA03
* AUTHOR:  Jef Morris
* CREATED DATE: 26/06/2013
* MODIFIED DETAILS
* DATE            AUTHOR                  CHGREF/DESCRIPTION
*-------------------------------------------------------------------
* {date}          {developer} {brief modification description}
*******************************************************************/

--Support Environment Job Check
--Compares:
--Daily to Production
--All other support to daily (accounts for similar altered job steps to be checked)
--Reports on:
--Missing Jobs
--Differing Job Descriptions
--Difference in step name or step command
--Initially returned 700+ rows, 250 of which being job descriptions


EXEC sp_configure 'show advanced options',1;
go 
RECONFIGURE
go 
EXEC sp_configure 'Ad Hoc Distributed Queries',1;
go 
RECONFIGURE
go 

/* Declare variables */
DECLARE @OrigSvr sysname, @OrigConn VARCHAR(255);
DECLARE @SuppSvr sysname, @SuppConn VARCHAR(255);
DECLARE @SQL VARCHAR(MAX);

/* Create results table if it doesnt exist already */
IF OBJECT_ID('tempdb.dbo.OutOfSyncJobs','U') IS NOT NULL
BEGIN
	drop TABLE tempdb.dbo.OutOfSyncJobs;
END;
--SELECT OBJECT_ID('tempdb.dbo.AllServers')
/* create table to hold list of servers to query */	
IF OBJECT_ID('tempdb.dbo.AllServers','U') IS NOT NULL
BEGIN
	DROP TABLE tempdb.dbo.AllServers;
END

IF OBJECT_ID('tempdb.dbo.OutOfSyncJobs') IS NULL
BEGIN
	CREATE TABLE tempdb.dbo.OutOfSyncJobs
	(	OriginatingServer sysname NOT NULL,
		JobName sysname NOT NULL,
		OutOfSyncServer sysname NOT NULL, OutOfSyncStep sysname NULL, CommandHash VARCHAR(50) NULL, ConnectionError sysname NULL );
END;

IF OBJECT_ID('tempdb.dbo.AllServers') IS NULL
BEGIN
	CREATE TABLE tempdb.dbo.AllServers
	(	OriginatingServer sysname NOT NULL,
		SupportServer sysname NOT NULL);
END
ELSE
BEGIN
	TRUNCATE TABLE tempdb.dbo.AllServers;
END;

/* Populate server list */
INSERT INTO tempdb.dbo.AllServers 
	(	OriginatingServer,
		SupportServer)
SELECT 	'LDSTCSPRO1DBA01','VM01TCSPRODBA01'
UNION ALL SELECT 	'VM01TCSPRODBA01','VM02TCSPRODBA01'
--UNION ALL SELECT 	'VM01TCSPRODBA01','VM04TCSPRODBA01'
UNION ALL SELECT 	'VM01TCSPRODBA01','VM05TCSPRODBA01'
UNION ALL SELECT 	'VM01TCSPRODBA01','VM06TCSPRODBA01'
UNION ALL SELECT 	'VM01TCSPRODBA01','VM07TCSPRODBA01'
UNION ALL SELECT 	'VM01TCSPRODBA01','VM08TCSPRODBA01'
UNION ALL SELECT 	'VM01TCSPRODBA01','VM10TCSPRODBA01'
UNION ALL SELECT 	'VM01TCSPRODBA01','VM11TCSPRODBA01'
--UNION ALL SELECT 	'VM01TCSPRODBA01','VM12TCSPRODBA01'

UNION ALL SELECT 	'LDSDCSPRO1DBA01','VM01DCSSERVER'
UNION ALL SELECT 	'VM01DCSSERVER','VM02DCSPRODBA01'
--UNION ALL SELECT 	'VM01DCSSERVER','VM04DCSSERVER'
UNION ALL SELECT 	'VM01DCSSERVER','VM05DCSPRODBA01'
UNION ALL SELECT 	'VM01DCSSERVER','VM06DCSPRODBA01'
UNION ALL SELECT 	'VM01DCSSERVER','VM07DCSSERVER'
UNION ALL SELECT 	'VM01DCSSERVER','VM08DCSPRODBA01'
UNION ALL SELECT 	'VM01DCSSERVER','VM10DCSPRODBA01'
UNION ALL SELECT 	'VM01DCSSERVER','VM11DCSPRODBA01'
--UNION ALL SELECT 	'VM01DCSSERVER','VM12DCSPRODBA01'

UNION ALL SELECT 	'LDSDMSPRO1DBA01','VM01DMSPRODBA01'
UNION ALL SELECT 	'VM01DMSPRODBA01','VM02DMSPRODBA01'
--UNION ALL SELECT 	'VM01DMSPRODBA01','VM04DMSPRODBA01'
UNION ALL SELECT 	'VM01DMSPRODBA01','VM05DMSPRODBA01'
UNION ALL SELECT 	'VM01DMSPRODBA01','VM06DMSPRODBA01'
UNION ALL SELECT 	'VM01DMSPRODBA01','VM07DMSPRODBA01'
UNION ALL SELECT 	'VM01DMSPRODBA01','VM08DMSPRODBA01'
UNION ALL SELECT 	'VM01DMSPRODBA01','VM10DMSPRODBA01'
UNION ALL SELECT 	'VM01DMSPRODBA01','VM11DMSPRODBA01'
--UNION ALL SELECT 	'VM01DMSPRODBA01','VM12DMSPRODBA01'

UNION ALL SELECT 	'LDSGENPRO1DBA02','VM01GENPRODBA02'
UNION ALL SELECT 	'VM01GENPRODBA02','VM02GENPRODBA02'
--UNION ALL SELECT 	'VM01GENPRODBA02','VM04GENPRODBA02'
UNION ALL SELECT 	'VM01GENPRODBA02','VM05GENPRODBA02'
UNION ALL SELECT 	'VM01GENPRODBA02','VM06GENPRODBA02'
UNION ALL SELECT 	'VM01GENPRODBA02','VM07GENPRODBA02'
UNION ALL SELECT 	'VM01GENPRODBA02','VM08GENPRODBA02'
UNION ALL SELECT 	'VM01GENPRODBA02','VM10GENPRODBA02'
UNION ALL SELECT 	'VM01GENPRODBA02','VM11GENPRODBA02'
--UNION ALL SELECT 	'VM01GENPRODBA02','VM12GENPRODBA02'

UNION ALL SELECT 	'LDSGENPRO1DBA03','VM01GENPRODBA03'
UNION ALL SELECT 	'VM01GENPRODBA03','VM02GENPRODBA03'
--UNION ALL SELECT 	'VM01GENPRODBA03','VM04GENPRODBA03'
UNION ALL SELECT 	'VM01GENPRODBA03','VM05GENPRODBA03'
UNION ALL SELECT 	'VM01GENPRODBA03','VM06GENPRODBA03'
UNION ALL SELECT 	'VM01GENPRODBA03','VM07GENPRODBA03'
UNION ALL SELECT 	'VM01GENPRODBA03','VM08GENPRODBA03'
UNION ALL SELECT 	'VM01GENPRODBA03','VM10GENPRODBA03'
UNION ALL SELECT 	'VM01GENPRODBA03','VM11GENPRODBA03'
--UNION ALL SELECT 	'VM01GENPRODBA03','VM12GENPRODBA03'

UNION ALL SELECT 	'LDSGENPRO1DBA04','VM01GENPRODBA04'
UNION ALL SELECT 	'VM01GENPRODBA04','VM02GENPRODBA04'
UNION ALL SELECT 	'VM01GENPRODBA04','VM03GENPRODBA04'
UNION ALL SELECT 	'VM01GENPRODBA04','VM06GENPRODBA04'
--UNION ALL SELECT 	'VM01GENPRODBA04','VM12GENPRODBA04'

UNION ALL SELECT 	'LDSQMTPRO1DBA01','VM01QMTPRODBA01'

UNION ALL SELECT 	'VMWBSPRO1DBA01','VM01WBSPRODBA01'
UNION ALL SELECT 	'VM01WBSPRODBA01','VMWBSDEV1DBA01'


/* now loop through each of the servers to pull back all the APP jobs */
DECLARE SvrCursor CURSOR FAST_FORWARD FOR
	SELECT	OriginatingServer,
			SupportServer
	FROM tempdb.dbo.AllServers ;


--SELECT * FROM tempdb.dbo.AllServers

OPEN SvrCursor
FETCH NEXT FROM SvrCursor
	INTO @OrigSvr,@SuppSvr;
	
WHILE @@FETCH_STATUS = 0
BEGIN	

	BEGIN TRY

		PRINT @OrigSvr;
		PRINT @SuppSvr;
		
		/* Drop all temp tables */
		IF OBJECT_ID('tempdb..##SupportJobs') IS NOT NULL
		BEGIN
			DROP TABLE ##SupportJobs;
		END;
		IF OBJECT_ID('tempdb..##OriginatorJobs') IS NOT NULL
		BEGIN
			DROP TABLE ##OriginatorJobs;
		END;

		/* Build connections strings */
		SET @OrigConn = 'Server=' + @OrigSvr + ';Trusted_Connection=yes;';
		SET @SuppConn = 'Server=' + @SuppSvr + ';Trusted_Connection=yes;';

		--/* Clear any existing data for the server */
		--DO NOT CLEAR, VM01 is used as originator multiple times
		--IF EXISTS(SELECT * FROM tempdb.dbo.OutOfSyncJobs WHERE OriginatingServer = @OrigSvr)
		--BEGIN
		--	DELETE FROM tempdb.dbo.OutOfSyncJobs WHERE OriginatingServer = @OrigSvr;
		--END;

		/* Get SUPPORT server jobs */
		IF @SuppSvr IS NOT NULL 
		BEGIN	
			SET @SQL = '
			SELECT a.*
			INTO ##SupportJobs	
			FROM OPENROWSET(''SQLNCLI'', ''' + @SuppConn + ''',
				 ''SELECT	JobName
					,DescriptionHash
					,StepName
					,CommandHash
			FROM 
			(SELECT SJ.name AS JobName
				,SJ.job_id
				,CHECKSUM(SJ.description) AS DescriptionHash
				,SJS.step_name AS StepName
				,SJS.step_id
				,CASE	WHEN SJS.subsystem = ''''SSIS'''' THEN CHECKSUM(SJS.step_name)
						ELSE CHECKSUM(SJS.step_name + SJS.command) 
				 END AS CommandHash
			FROM msdb.dbo.sysjobs SJ
				INNER JOIN msdb.dbo.sysjobsteps SJS
					ON SJ.job_id = SJS.job_id
			WHERE sj.name LIKE ''''APP%'''') AS a
			'') AS a;';

			PRINT @SQL
			EXEC (@SQL);
		
		END ;

		/* Get Originator server jobs */
		SET @SQL = '
			SELECT a.*
			INTO ##OriginatorJobs	
			FROM OPENROWSET(''SQLNCLI'', ''' + @OrigConn + ''',
				 ''SELECT	JobName
					,DescriptionHash
					,StepName
					,CommandHash
			FROM 
			(SELECT SJ.name AS JobName
				,SJ.job_id
				,CHECKSUM(SJ.description) AS DescriptionHash
				,SJS.step_name AS StepName
				,SJS.step_id
				,CASE	WHEN SJS.subsystem = ''''SSIS'''' THEN CHECKSUM(SJS.step_name)
						ELSE CHECKSUM(SJS.step_name + SJS.command) 
				 END AS CommandHash
			FROM msdb.dbo.sysjobs SJ
				INNER JOIN msdb.dbo.sysjobsteps SJS
					ON SJ.job_id = SJS.job_id
			WHERE sj.name LIKE ''''APP%'''') AS a
			'') AS a;';

		PRINT @SQL
		EXEC (@SQL);
		
		/* record all jobs out of sync on the Support servers (compared to Originator) */
		IF @SuppSvr IS NOT NULL 
		BEGIN
			--Job Descriptions not matching...
			INSERT INTO tempdb.dbo.OutOfSyncJobs
					( OriginatingServer, JobName, OutOfSyncServer, OutOfSyncStep, CommandHash, ConnectionError )
			SELECT @OrigSvr, JobName, @SuppSvr, 'JOB DESCRIPTION', 'N/A', ''
			FROM (		
			SELECT JobName, DescriptionHash FROM ##OriginatorJobs
			EXCEPT
			SELECT JobName, DescriptionHash FROM ##SupportJobs ) AS a;
			--Job Steps Not Matching
			INSERT INTO tempdb.dbo.OutOfSyncJobs
					( OriginatingServer, JobName, OutOfSyncServer, OutOfSyncStep, CommandHash, ConnectionError )
			SELECT @OrigSvr, JobName, @SuppSvr, StepName, CommandHash, ''
			FROM (		
			SELECT JobName, StepName, CommandHash FROM ##OriginatorJobs
			EXCEPT
			SELECT JobName, StepName, CommandHash FROM ##SupportJobs ) AS a;
		END;
		
		FETCH NEXT FROM SvrCursor
			INTO @OrigSvr,@SuppSvr;

	END TRY

	BEGIN CATCH


--Msg 53, Level 16, State 1, Line 0
--Named Pipes Provider: Could not open a connection to SQL Server [53]. 

		IF @SuppSvr IS NOT NULL 
		BEGIN
			--Job Descriptions not matching...
			INSERT INTO tempdb.dbo.OutOfSyncJobs
					( OriginatingServer, JobName, OutOfSyncServer, OutOfSyncStep, CommandHash, ConnectionError )
			SELECT @OrigSvr, '', @SuppSvr, '', 'N/A', @SuppSvr + ' SERVER NOT RESPONDING - ' + ERROR_MESSAGE()
		END;


		FETCH NEXT FROM SvrCursor
		INTO @OrigSvr,@SuppSvr;


--		SELECT	@ERRORNO = ERROR_NUMBER() 
--				,@ERRORMSG = ERROR_MESSAGE() 
--
--		PRINT 'Restore of Archived DMS Client failed: ' + CONVERT (VARCHAR, @ERRORNO) + ' ' + @ERRORMSG
--
--		IF @@TRANCOUNT > 0
--			BEGIN 
--				ROLLBACK TRANSACTION UnArchive_DMSClient
--			END 
--
--	--	SET @DMSSuccess = 0
--	--	SELECT @DMSSuccess
--		SELECT RESULTMESSAGE = 'An error whilst restoring archived DMS client'

	END CATCH


END 

CLOSE SvrCursor
DEALLOCATE SvrCursor

/* remove any entries that are not applicable e.g. job steps altered due to email */

--JOB EXCEPTIONS...
DELETE FROM tempdb.dbo.OutOfSyncJobs
WHERE (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP WSS Long Acc Numbers')
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS CHECK SYSTEM_CODES VALUE')
--Temp Job in live only:
OR (OriginatingServer = 'LDSTCSPRO1DBA01' AND JobName = 'APP DCS Originator Counsellor Job')
OR (OriginatingServer = 'LDSDCSPRO1DBA01' AND JobName = 'APP DCSLIVE End Date Duplicate Data')
OR (OriginatingServer = 'LDSGENPRO1DBA02' AND JobName = 'APP DirectDebit Payer License Alert')
--Production Reports Only...
OR (OriginatingServer = 'LDSDCSPRO1DBA01' AND JobName = 'APP CWS Refresh Error Report Data')
OR (OriginatingServer = 'LDSDCSPRO1DBA01' AND JobName = 'APP DCSLIVE Comms Queue Checks')
--Jobs on GENPRO2 that are on WEBPRO servers in other environments...
OR (OriginatingServer = 'VM01GENPRODBA02' AND JobName = 'APP DEBTREMEDY_LIVE CREATE_DCS_CLIENTS')
--Daily Disbursement jobs being tested in daily
--OR (OriginatingServer = 'VM01GENPRODBA03' AND JobName = 'APP CPF_BACS Create Daily Disbursement')
OR (OriginatingServer = 'VM01DMSPRODBA01' AND JobName = 'APP DMS Add Creditor Hold Notes')



--JOB STEP EXCEPTIONS... Only do for OriginatingServer = <PRODUCTION> as compare of Daily to other support should match
DELETE FROM tempdb.dbo.OutOfSyncJobs
WHERE (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS FindSuspectClients' AND OutOfSyncStep = 'Errored')
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS FindSuspectClients' AND OutOfSyncStep = 'Send Report')
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS CREDITOR MERGE' AND OutOfSyncStep = 'email')
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS CREDITOR MERGE' AND OutOfSyncStep = 'fail email')
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS REPORT TYPE 3 RECORD LOCKS' AND OutOfSyncStep = 'email')
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS REPORT TYPE 3 RECORD LOCKS' AND OutOfSyncStep = 'report')
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS END OF MONTH PROCESS' AND OutOfSyncStep = 'Failure Email')
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS END OF MONTH PROCESS' AND OutOfSyncStep = 'Success Email')
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS SET DEBTS ON HOLD' AND OutOfSyncStep = 'Fail Notification')
--APP DMS ExportDroppedDDs altered as it updates the file system
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS ExportDroppedDDs' AND OutOfSyncStep = 'Export DDs')
-- This will also always be out of sync for support environments too
OR (OriginatingServer = 'VM01DMSPRODBA01' AND JobName = 'APP DMS ExportDroppedDDs' AND OutOfSyncStep = 'Export DDs')
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS Unprocessed Additional Client Debts Reminder' AND OutOfSyncStep = 'Step 1')
OR (OriginatingServer = 'LDSDCSPRO1DBA01' AND JobName = 'APP DCSLIVE CLEANSE BUDGET DATA' AND OutOfSyncStep = 'Fail Notification')
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS DAILY PROCESS' AND OutOfSyncStep = 'Email Unlocked Record Locks')
OR (OriginatingServer = 'LDSGENPRO1DBA03' AND JobName = 'APP WSS Refresh' AND OutOfSyncStep = 'Fail notification (DocuTrieve)')
OR (OriginatingServer = 'LDSGENPRO1DBA03' AND JobName = 'APP WSS Refresh' AND OutOfSyncStep = 'Fail notification (Refresh)')
OR (OriginatingServer = 'LDSGENPRO1DBA03' AND JobName = 'APP WSS Writeback' AND OutOfSyncStep = 'Fail Notification')
OR (OriginatingServer = 'LDSGENPRO1DBA03' AND JobName = 'APP DCS Find Mismatched WSS Proposals' AND OutOfSyncStep = 'Send Report')
OR (OriginatingServer = 'LDSGENPRO1DBA03' AND JobName = 'APP DCS Find Mismatched WSS Proposals' AND OutOfSyncStep = 'Errored')
OR (OriginatingServer = 'VM01DCSSERVER' AND JobName = 'APP DMS Request Creditor Reproposals')

--APP CWS Refresh Error Report Data

/* return result set if any exists */
SELECT 	OriginatingServer,
		JobName,
		OutOfSyncServer, OutOfSyncStep, ConnectionError
 
FROM tempdb.dbo.OutOfSyncJobs
--WHERE jobname = 'APP DCSLIVE CLEANSE BUDGET DATA'
--ORDER BY outofsyncstep
ORDER BY OriginatingServer, JobName, OutOfSyncServer

