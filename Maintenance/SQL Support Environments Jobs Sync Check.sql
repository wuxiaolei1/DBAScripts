/*---------------------------------------------------------

Non-live environment jobs sync check, will report:

- Job descriptions not matching
- Job step commands not matching
- SSIS target server names not matching the server name
- Jobs that may be obsolete
	(i.e. don't exist on the originating server)

---------------------------------------------------------*/


EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE
GO
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
GO
RECONFIGURE
GO

DECLARE @OrigSvr sysname, @OrigConn VARCHAR(255);
DECLARE @SuppSvr sysname, @SuppConn VARCHAR(255);
DECLARE @SQL VARCHAR(MAX), @TempSQL VARCHAR(MAX);

IF OBJECT_ID(N'tempdb..#AllServers', 'U') IS NOT NULL
	DROP TABLE #AllServers;

CREATE TABLE #AllServers (
	OriginatingServer SYSNAME NOT NULL,
	SupportServer SYSNAME NOT NULL );

INSERT #AllServers (OriginatingServer, SupportServer)


-- EDIT SERVER LIST HERE ----------------------------------

					--TCSPRO*
          SELECT	'LDSTCSPRO1DBA01',	'VM01TCSPRODBA01'
UNION ALL SELECT	'VM01TCSPRODBA01',	'VM02TCSPRODBA01'
UNION ALL SELECT	'VM01TCSPRODBA01',	'VM03TCSPRODBA01'
UNION ALL SELECT	'VM01TCSPRODBA01',	'VM05TCSPRODBA01'
UNION ALL SELECT	'VM01TCSPRODBA01',	'VM06TCSPRODBA01'
UNION ALL SELECT	'VM01TCSPRODBA01',	'VM07TCSPRODBA01'
UNION ALL SELECT	'VM01TCSPRODBA01',	'VM08TCSPRODBA01'
UNION ALL SELECT	'VM01TCSPRODBA01',	'VM10TCSPRODBA01'
UNION ALL SELECT	'VM01TCSPRODBA01',	'VM11TCSPRODBA01'
UNION ALL SELECT	'VM01TCSPRODBA01',	'VMTRTCSPRODBA01'
					--DCS*
UNION ALL SELECT	'LDSDCSPRO1DBA01',	'VM01DCSSERVER'
UNION ALL SELECT	'VM01DCSSERVER',	'VM02DCSPRODBA01'
UNION ALL SELECT	'VM01DCSSERVER',	'VM03DCSPRODBA01'
UNION ALL SELECT	'VM01DCSSERVER',	'VM05DCSPRODBA01'
UNION ALL SELECT	'VM01DCSSERVER',	'VM06DCSPRODBA01'
UNION ALL SELECT	'VM01DCSSERVER',	'VM07DCSPRODBA01'
UNION ALL SELECT	'VM01DCSSERVER',	'VM08DCSPRODBA01'
UNION ALL SELECT	'VM01DCSSERVER',	'VM10DCSPRODBA01'
UNION ALL SELECT	'VM01DCSSERVER',	'VM11DCSPRODBA01'
UNION ALL SELECT	'VM01DCSSERVER',	'VMTRDCSPRODBA01'
					--DMSPRO*
UNION ALL SELECT	'LDSDMSPRO1DBA01',	'VM01DMSPRODBA01'
UNION ALL SELECT	'VM01DMSPRODBA01',	'VM02DMSPRODBA01'
UNION ALL SELECT	'VM01DMSPRODBA01',	'VM03DMSPRODBA01'
UNION ALL SELECT	'VM01DMSPRODBA01',	'VM05DMSPRODBA01'
UNION ALL SELECT	'VM01DMSPRODBA01',	'VM06DMSPRODBA01'
UNION ALL SELECT	'VM01DMSPRODBA01',	'VM07DMSPRODBA01'
UNION ALL SELECT	'VM01DMSPRODBA01',	'VM08DMSPRODBA01'
UNION ALL SELECT	'VM01DMSPRODBA01',	'VM10DMSPRODBA01'
UNION ALL SELECT	'VM01DMSPRODBA01',	'VM11DMSPRODBA01'
UNION ALL SELECT	'VM01DMSPRODBA01',	'VMTRDMSPRODBA01'
					--GENPRO2*
UNION ALL SELECT	'LDSGENPRO1DBA02',	'VM01GENPRODBA02'
UNION ALL SELECT	'VM01GENPRODBA02',	'VM02GENPRODBA02'
UNION ALL SELECT	'VM01GENPRODBA02',	'VM03GENPRODBA02'
UNION ALL SELECT	'VM01GENPRODBA02',	'VM05GENPRODBA02'
UNION ALL SELECT	'VM01GENPRODBA02',	'VM06GENPRODBA02'
UNION ALL SELECT	'VM01GENPRODBA02',	'VM07GENPRODBA02'
UNION ALL SELECT	'VM01GENPRODBA02',	'VM08GENPRODBA02'
UNION ALL SELECT	'VM01GENPRODBA02',	'VM10GENPRODBA02'
UNION ALL SELECT	'VM01GENPRODBA02',	'VM11GENPRODBA02'
UNION ALL SELECT	'VM01GENPRODBA02',	'VMTRGENPRODBA02'
					--GENPRO3*
UNION ALL SELECT	'LDSGENPRO1DBA03',	'VM01GENPRODBA03'
UNION ALL SELECT	'VM01GENPRODBA03',	'VM02GENPRODBA03'
UNION ALL SELECT	'VM01GENPRODBA03',	'VM03GENPRODBA03'
UNION ALL SELECT	'VM01GENPRODBA03',	'VM05GENPRODBA03'
UNION ALL SELECT	'VM01GENPRODBA03',	'VM06GENPRODBA03'
UNION ALL SELECT	'VM01GENPRODBA03',	'VM07GENPRODBA03'
UNION ALL SELECT	'VM01GENPRODBA03',	'VM08GENPRODBA03'
UNION ALL SELECT	'VM01GENPRODBA03',	'VM10GENPRODBA03'
UNION ALL SELECT	'VM01GENPRODBA03',	'VM11GENPRODBA03'
UNION ALL SELECT	'VM01GENPRODBA03',	'VMTRGENPRODBA03'
					--GENPRO4*
UNION ALL SELECT	'LDSGENPRO1DBA04',	'VM01GENPRODBA04'
UNION ALL SELECT	'VM01GENPRODBA04',	'VM02GENPRODBA04'
UNION ALL SELECT	'VM01GENPRODBA04',	'VM03GENPRODBA04'
UNION ALL SELECT	'VM01GENPRODBA04',	'VM05GENPRODBA04'
--UNION ALL SELECT	'VM01GENPRODBA04',	'VM06GENPRODBA04'
UNION ALL SELECT	'VM01GENPRODBA04',	'VM07GENPRODBA04'
UNION ALL SELECT	'VM01GENPRODBA04',	'VM08GENPRODBA04'
UNION ALL SELECT	'VM01GENPRODBA04',	'VM10GENPRODBA04'
UNION ALL SELECT	'VM01GENPRODBA04',	'VM11GENPRODBA04'
					--QMT*
UNION ALL SELECT	'LDSQMTPRO1DBA01',	'VM01QMTPRODBA01'
					--WBS*
UNION ALL SELECT	'VMWBSPRO1DBA01',	'VM01WBSPRODBA01'
UNION ALL SELECT	'VM01WBSPRODBA01',	'VMWBSDEV1DBA01'

-----------------------------------------------------------



IF OBJECT_ID(N'tempdb..#OutOfSyncJobs', 'U') IS NOT NULL
	DROP TABLE #OutOfSyncJobs;

CREATE TABLE #OutOfSyncJobs (
	OriginatingServer SYSNAME NOT NULL,
	JobName SYSNAME NOT NULL,
	OutOfSyncServer SYSNAME NOT NULL,
	OutOfSyncStep SYSNAME NULL,
	CommandHash VARCHAR(50) NULL,
	ConnectionError SYSNAME NULL );

SET @TempSQL =
'
SELECT *
INTO <TargetTable>
FROM OPENROWSET(''SQLNCLI'', ''<Connection>'', ''
SELECT	JobName
		, DescriptionHash
		, StepName
		, CommandHash
		, SSISServerName
FROM (
	SELECT	sj.name AS JobName
			, sj.job_id
			, CHECKSUM(sj.description) AS DescriptionHash
			, sjs.step_name AS StepName
			, sjs.step_id
			, CASE WHEN sjs.subsystem = ''''SSIS''''
				THEN CHECKSUM(sjs.step_name)
				ELSE CHECKSUM(sjs.step_name + sjs.command)
				END AS CommandHash
			, CASE WHEN sjs.subsystem = ''''SSIS''''
				THEN SUBSTRING(sjs.command, CHARINDEX(''''/SERVER '''', sjs.command) + 8, CHARINDEX('''' '''', sjs.command, CHARINDEX(''''/SERVER '''', sjs.command) + 8) - CHARINDEX(''''/SERVER '''', sjs.command) - 8)
				ELSE ''''N/A''''
				END AS SSISServerName
	FROM	msdb.dbo.sysjobs sj
		INNER JOIN msdb.dbo.sysjobsteps sjs
			ON sj.job_id = sjs.job_id
	WHERE	sj.name LIKE ''''APP%''''
) AS a'')
';

DECLARE SvrCursor CURSOR FAST_FORWARD FOR SELECT OriginatingServer, SupportServer FROM #AllServers;
OPEN SvrCursor;
FETCH NEXT FROM SvrCursor INTO @OrigSvr, @SuppSvr;

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRY
		IF OBJECT_ID(N'tempdb..##SupportJobs', 'U') IS NOT NULL
			DROP TABLE ##SupportJobs;
		IF OBJECT_ID(N'tempdb..##OriginatorJobs', 'U') IS NOT NULL
			DROP TABLE ##OriginatorJobs;
		SET @SuppConn = 'Server=' + @SuppSvr + ';Trusted_Connection=yes;';
		SET @OrigConn = 'Server=' + @OrigSvr + ';Trusted_Connection=yes;';
		SET @SQL = REPLACE(REPLACE(@TempSQL, '<TargetTable>', '##SupportJobs'), '<Connection>', @SuppConn);
		EXEC (@SQL);
		SET @SQL = REPLACE(REPLACE(@TempSQL, '<TargetTable>', '##OriginatorJobs'), '<Connection>', @OrigConn);
		EXEC (@SQL);

		--Job Descriptions not matching...
		INSERT #OutOfSyncJobs (OriginatingServer, JobName, OutOfSyncServer, OutOfSyncStep, CommandHash, ConnectionError)
		SELECT @OrigSvr, JobName, @SuppSvr, 'JOB DESCRIPTION', 'N/A', ''
		FROM (
		SELECT JobName, DescriptionHash FROM ##OriginatorJobs
		EXCEPT
		SELECT JobName, DescriptionHash FROM ##SupportJobs ) AS a;

		--Job Steps Not Matching
		INSERT #OutOfSyncJobs (OriginatingServer, JobName, OutOfSyncServer, OutOfSyncStep, CommandHash, ConnectionError)
		SELECT @OrigSvr, JobName, @SuppSvr, StepName, CommandHash, ''
		FROM (
		SELECT JobName, StepName, CommandHash FROM ##OriginatorJobs
		EXCEPT
		SELECT JobName, StepName, CommandHash FROM ##SupportJobs ) AS a;

		--SSIS Server Name incorrect
		INSERT #OutOfSyncJobs (OriginatingServer, JobName, OutOfSyncServer, OutOfSyncStep, CommandHash, ConnectionError)
		SELECT @OrigSvr, JobName, @SuppSvr, 'SSIS SERVER NAME', 'N/A', REPLACE(SSISServerName, '"', '')
		FROM (
		SELECT JobName, SSISServerName FROM ##SupportJobs WHERE SSISServerName != 'N/A' AND REPLACE(SSISServerName, '"', '') != @SuppSvr) AS a;

		--Jobs that no longer exist
		INSERT #OutOfSyncJobs (OriginatingServer, JobName, OutOfSyncServer, OutOfSyncStep, CommandHash, ConnectionError)
		SELECT @OrigSvr, JobName, @SuppSvr, 'JOB NO LONGER EXISTS', 'N/A', ''
		FROM (
		SELECT JobName FROM ##SupportJobs
		EXCEPT
		SELECT JobName FROM ##OriginatorJobs ) AS a;

	END TRY

	BEGIN CATCH

		INSERT #OutOfSyncJobs (OriginatingServer, JobName, OutOfSyncServer, OutOfSyncStep, CommandHash, ConnectionError)
		SELECT @OrigSvr, '', @SuppSvr, '', 'N/A', @SuppSvr + ' SERVER NOT RESPONDING - ' + ERROR_MESSAGE();

	END CATCH

	FETCH NEXT FROM SvrCursor INTO @OrigSvr, @SuppSvr;

END

CLOSE SvrCursor;
DEALLOCATE SvrCursor;




-- FILTER EXCEPTIONS HERE ---------------------------------

DELETE #OutOfSyncJobs
WHERE

--PRODUCTION ONLY JOBS (FOR ALERTING)...
   (OriginatingServer = 'LDSDCSPRO1DBA01' AND JobName = 'APP CWS Refresh Error Report Data')
OR (OriginatingServer = 'LDSDCSPRO1DBA01' AND JobName = 'APP DCSLIVE Comms Queue Checks')
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS CHECK SYSTEM_CODES VALUE')
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP WSS Long Acc Numbers')

--STEPS THAT WILL BE DIFFERENT IN NON-PRODUCTION...
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS Unprocessed Additional Client Debts Reminder' AND OutOfSyncStep = 'Step 1') -- MAIL COMMENTED OUT
OR (OriginatingServer IN ('LDSGENPRO1DBA03','LDSGENPRO1DBA04') AND JobName = 'APP DCS Find Mismatched WSS Proposals' AND OutOfSyncStep = 'Send Report') -- MAIL COMMENTED OUT
OR (OriginatingServer IN ('LDSGENPRO1DBA03','LDSGENPRO1DBA04') AND JobName = 'APP DCS Find Mismatched WSS Proposals' AND OutOfSyncStep = 'Errored') -- MAIL COMMENTED OUT
OR (OriginatingServer IN ('LDSGENPRO1DBA03','LDSGENPRO1DBA04') AND JobName = 'APP WSS Refresh' AND OutOfSyncStep = 'Fail notification (DocuTrieve)') -- MAIL COMMENTED OUT
OR (OriginatingServer IN ('LDSGENPRO1DBA03','LDSGENPRO1DBA04') AND JobName = 'APP WSS Refresh' AND OutOfSyncStep = 'Fail notification (Refresh)') -- MAIL COMMENTED OUT
OR (OriginatingServer IN ('LDSGENPRO1DBA03','LDSGENPRO1DBA04') AND JobName = 'APP WSS Writeback' AND OutOfSyncStep = 'Fail Notification') -- MAIL COMMENTED OUT
OR (OriginatingServer = 'LDSTCSPRO1DBA01' AND JobName = 'APP TCS Purge Client PAPs' AND OutOfSyncStep = 'Create PAP Drops File') -- FILE PATH
OR (OriginatingServer = 'LDSDMSPRO1DBA01' AND JobName = 'APP DMS Alert on XX Batches Reconciliation' AND OutOfSyncStep = 'Check XX Batches = 0') -- MAIL COMMENTED OUT
OR (OriginatingServer = 'LDSTCSPRO1DBA01' AND JobName = 'APP TCS Debt Awareness Week' AND OutOfSyncStep = 'Get Stats') -- MAIL COMMENTED OUT

--TRAINING ENVIRONMENT ONLY...
OR (OriginatingServer = 'VM01GENPRODBA03' AND JobName = 'APP Generate Client Scenarios' AND OutOfSyncServer = 'VMTRGENPRODBA03')

--VM01 JOBS THAT ARE ON WEBPRO SERVERS IN OTHER ENVIRONMENTS
OR (JobName = 'APP DEBTREMEDY_LIVE CREATE_DCS_CLIENTS' AND (OriginatingServer = 'VM01GENPRODBA04' OR OutOfSyncServer = 'VM01GENPRODBA04' ) )
OR (JobName = 'APP DotNetNuke Archiving' AND (OriginatingServer = 'VM01GENPRODBA04' OR OutOfSyncServer = 'VM01GENPRODBA04') )

--JOBS IN DEVELOPMENT...
OR (OriginatingServer = 'VM01GENPRODBA03' AND JobName = 'APP CPF_BACS Create Daily Then Monthly Disbursement' AND OutOfSyncServer = 'VM07GENPRODBA03')
OR (OriginatingServer = 'VM01GENPRODBA03' AND JobName = 'APP CPF_BACS Unit Test DAS Disbursement' AND OutOfSyncServer = 'VM07GENPRODBA03')
OR (OriginatingServer = 'VM01GENPRODBA03' AND JobName = 'APP CPF_BACS Create Daily Then Monthly Disbursement' AND OutOfSyncServer = 'VM11GENPRODBA03')
--OR (JobName = 'APP CPF_BACS Release Closed Plan Emails')
--OR (JobName = 'APP CPF_BACS Release CPF Emails')
--OR (JobName = 'APP CPF_BACS Release Non Payer Emails')
OR (OriginatingServer = 'VM01GENPRODBA03' AND JobName = 'APP CPF_BACS Apply UCM Transactions' AND OutOfSyncServer = 'VM02GENPRODBA03')
OR (JobName = 'AppsSupportUtility' AND (OriginatingServer = 'VM01WBSPRODBA01' OR OutOfSyncServer = 'VM01WBSPRODBA01'))

-----------------------------------------------------------



SELECT 	OriginatingServer,
		JobName,
		OutOfSyncServer, OutOfSyncStep, ConnectionError
 
FROM #OutOfSyncJobs
ORDER BY OriginatingServer, JobName, OutOfSyncServer
