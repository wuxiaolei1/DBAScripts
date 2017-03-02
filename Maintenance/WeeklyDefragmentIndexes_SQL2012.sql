USE [msdb]
GO

/****** Object:  Job [<SERVERNAME, NVARCHAR(128), >_WeeklyDefragmentIndexes]    Script Date: 07/24/2012 11:14:24 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 07/24/2012 11:14:24 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'<SERVERNAME, NVARCHAR(128), >_WeeklyDefragmentIndexes', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Job to manually rebuild fragmented indexes, >30% fragmentation will rebuild, 10%-30% will reorganize, the rest will be ignored.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Defragment indexes]    Script Date: 07/24/2012 11:14:24 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Defragment indexes', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- job step for SQL 2008 reindex

SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
GO

DECLARE @DB_Exceptions TABLE (DatabaseName NVARCHAR(128))
-- INSERT DB exceptions here
--INSERT @DB_Exceptions
--SELECT ''SystemsHelpDesk'';

DECLARE @version SMALLINT;
SELECT @version = @@microsoftversion / 0x01000000;

IF @version >= 9
BEGIN
	DECLARE	@DBName NVARCHAR(128), 
			@TableName NVARCHAR(256),
			@SQLString NVARCHAR(max)
	DECLARE @loop_counter SMALLINT,
			@MaxNoOfDBs SMALLINT,
			@ErrorCount TINYINT,
			@MaxNoOfTables INT,
			@TableLoopCounter INT
	SELECT @ErrorCount = 0

	-- CREATE TEMP TABLES
	IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE [NAME] LIKE ''#dbs%'')
		DROP TABLE #dbs;
	IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE [NAME] LIKE ''#Indexes%'')
		DROP TABLE #Indexes;
		
	CREATE TABLE #dbs
		(Primary_key TINYINT IDENTITY(1,1) PRIMARY KEY,
		  DatabaseName VARCHAR(128));

	CREATE TABLE #Indexes
		( Primary_key INT IDENTITY(1,1) PRIMARY KEY,
		  TableSchema NVARCHAR(128),
		  TableName NVARCHAR(256),
		  IndexName NVARCHAR(256),
		  RebuildIndex BIT,
		  OnLineReIndex BIT -- Used if it is enterprise edition 
		  );

	-- POPULATE TEMP TABLE
	INSERT INTO #dbs
	SELECT	[NAME]
	FROM	sys.databases db	
			/* we only want to defrag replica that are the primary if they are in an availability group */
			LEFT JOIN sys.dm_hadr_availability_replica_states st
				ON db.replica_id = st.replica_id
	WHERE	Db.database_id > 4
	AND		db.state_desc = ''ONLINE''
	AND		db.[name] NOT IN (SELECT DatabaseName FROM @DB_Exceptions)
	/* we only want to defrag replica that are the primary if they are in an availability group */
	AND		( st.role_desc = ''PRIMARY'' OR st.role_desc IS NULL);

	IF @@ERROR <> 0
	BEGIN
		RAISERROR (''SQLReIndexJob: Unable to populate #dbs temp table'', 16, 1) WITH LOG
		SELECT @ErrorCount = 1
	END

	SELECT @MaxNoOfDBs = COUNT(1) FROM #dbs
	SELECT @loop_counter = 1

	IF @MaxNoOfDBs > 0
	BEGIN
		WHILE @loop_counter <= @MaxNoOfDBs
		BEGIN
			-- Get DB name
			SELECT	@DBName = DatabaseName 
			FROM	#dbs
			WHERE	Primary_key = @loop_counter
			-- truncate tenp table
			TRUNCATE TABLE #Indexes

			-- populate temp table
			-- Enterprise edition SQL so find all indexes where reindex can be done online
			SELECT @SQLString = 
			''USE ['' + @dbname + '']; 					
			WITH BadCols_CTE ([OBJECT_ID])
			AS
			(	SELECT DISTINCT cols.OBJECT_ID 
				FROM sys.columns cols 
				INNER JOIN sys.types typ ON typ.system_type_id = cols.system_type_id
				WHERE typ.NAME IN (''''image'''', ''''TEXT'''', ''''NTEXT'''', ''''XML'''')
					OR	
					(typ.NAME IN (''''varchar'''', ''''nvarchar'''', ''''varbinary'''') AND cols.max_length = -1)
			)
			INSERT INTO #Indexes
			SELECT DISTINCT 
					sch.[NAME],
					OBJECT_NAME(idx.[object_id]),
					idx.NAME AS IndexName,
					CASE 
						WHEN FRG.avg_fragmentation_in_percent > 30 THEN 1
						ELSE 0
					END AS RebuildIndex,
					CASE 
						-- Check edition of SQL, if enterprise then get all tables that can be done online
						WHEN CONVERT(NVARCHAR(128),SERVERPROPERTY(''''edition'''')) NOT LIKE ''''%Enterprise%'''' THEN 0
						WHEN BadCols_CTE.[OBJECT_ID] IS NULL THEN 1
						ELSE 0
					END AS OnLineReindex
			FROM sys.[dm_db_index_physical_stats]('' + CONVERT(NVARCHAR(3),DB_ID(@dbname)) + '', NULL, NULL, NULL, ''''LIMITED'''') FRG
				INNER JOIN sys.indexes idx ON idx.[object_id] = FRG.[object_id]
												AND idx.index_id = FRG.index_id
				INNER JOIN sys.tables tab ON idx.[object_id] = tab.[OBJECT_ID]
				INNER JOIN sys.schemas sch ON tab.[SCHEMA_ID] = sch.[SCHEMA_ID]
				LEFT JOIN BadCols_CTE ON BadCols_CTE.[OBJECT_ID] = idx.[object_id]	
			WHERE  tab.[TYPE] = ''''U''''
			AND FRG.avg_fragmentation_in_percent > 10.0 AND NOT (FRG.avg_fragmentation_in_percent <= 30 AND (idx.is_disabled = 1 OR idx.allow_page_locks = 0)) AND idx.index_id > 0 AND FRG.page_count > 8;''

			
			EXEC (@SQLString)
			--PRINT ''Executed: '' + @SQLString

			IF @@ERROR <> 0
			BEGIN
				RAISERROR (''SQLReIndexJob: Unable to populate #Indexes temp table'', 16, 1) WITH LOG
				SELECT @ErrorCount = 1
			END
			ELSE
			BEGIN
				SELECT	@MaxNoOfTables = MAX(primary_key)
				FROM	#Indexes;
				
				SELECT	@TableLoopCounter = 1;

				IF @MaxNoOfTables > 0
				BEGIN
					WHILE @TableLoopCounter <= @MaxNoOfTables
					BEGIN
						-- Build the sql string to rebuild/reorganize
						-- Add the online option
						SELECT	@SQLString  = 
							CASE 
								WHEN RebuildIndex = 1 AND OnLineReIndex = 1 AND @version >= 11
									THEN ''USE ['' + @dbname + '']; ALTER INDEX ['' + IndexName + ''] ON ['' + TableSchema + ''].['' + TableName + ''] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON, MAXDOP = 1)''
								WHEN RebuildIndex = 1 AND OnLineReIndex = 1 
									THEN ''USE ['' + @dbname + '']; ALTER INDEX ['' + IndexName + ''] ON ['' + TableSchema + ''].['' + TableName + ''] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON)''
								WHEN RebuildIndex = 1 AND OnLineReIndex = 0 
									THEN ''USE ['' + @dbname + '']; ALTER INDEX ['' + IndexName + ''] ON ['' + TableSchema + ''].['' + TableName + ''] REBUILD WITH (SORT_IN_TEMPDB = ON)''
								WHEN RebuildIndex = 0 
									THEN ''USE ['' + @dbname + '']; ALTER INDEX ['' + IndexName + ''] ON ['' + TableSchema + ''].['' + TableName + ''] REORGANIZE''
								ELSE ''USE ['' + @dbname + '']; ALTER INDEX ['' + IndexName + ''] ON ['' + TableSchema + ''].['' + TableName + ''] REBUILD WITH (SORT_IN_TEMPDB = ON)''
							END
						FROM	#Indexes
						WHERE	Primary_key = @TableLoopCounter;
						
						EXEC(@SQLString)
						PRINT ''Executed: '' + @SQLString
						IF @@ERROR <> 0 
						BEGIN
							RAISERROR (''SQLReIndexJob: There has been an error performing a reindex on database %s'', 16, 1, @DBName) WITH LOG
							SELECT @ErrorCount = 1
						END

						SET @TableLoopCounter = @TableLoopCounter + 1
					END
				END
			END
			SET @loop_counter = @loop_counter + 1
		END
	END

	-- Tidy Up
	IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE [NAME] LIKE ''#dbs%'')
		DROP TABLE #dbs
	IF EXISTS (SELECT 1 FROM tempdb.dbo.sysobjects WHERE [NAME] LIKE ''#Indexes%'')
		DROP TABLE #Indexes
END
ELSE 
BEGIN
	RAISERROR (''SQLReIndexJob: Untested SQL version'', 16, 1) WITH LOG;
END', 
		@database_name=N'master', 
		@output_file_name=N'E:\SQLOutput\<SERVERNAME, NVARCHAR(128), >_WeeklyIndexDefrag.txt', 
		@flags=12
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'WeeklySchedule', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20110822, 
		@active_end_date=99991231, 
		@active_start_time=20000, 
		@active_end_time=235959, 
		@schedule_uid=N'a50b2e94-b050-4913-9b50-20196fb04049'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


