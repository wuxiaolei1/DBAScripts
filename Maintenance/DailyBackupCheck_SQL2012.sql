USE [msdb]
GO
/****** Object:  Job [SERVERNAME_BackupCheck]    Script Date: 06/24/2008 11:20:27 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 06/24/2008 11:20:27 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SERVERNAME_BackupCheck', 
		@enabled=1, 
		@notify_level_eventlog=3, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Checks to ensure backups have occurred.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Complete Backups]    Script Date: 06/24/2008 11:20:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Complete Backups', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- ++ Checks job history tables and raises an error for
-- ++ Databases that have not been backed up in the last 24 hours.
-- ++ Created on: 06/12/2007.
-- ++ Created by: Paul Byers.
-- ++ Modified on: 07/01/2007.
-- ++ Modfied by: Paul Byers.
-- ++ Modified on: 10/05/2011.
-- ++ Modfied by: Tom Braham to include online databases only in the check.
-- ++ Modified on: 05/11/2014.
-- ++ Modfied by: Tom Braham to include preferred databases for SQL2012 only in the check.


SET NOCOUNT ON

DECLARE @DB VARCHAR (50),
		@ErrorString VARCHAR (500)

SET @ErrorString = ''''

DECLARE DB_CURSOR CURSOR FOR
--	traps databases that have not been backed up in 24 hours.
SELECT db.[name]
FROM master..sysdatabases db 
		INNER JOIN msdb..backupset bck ON db.[name] = bck.database_name 
WHERE db.[name] <> ''tempdb'' and bck.type = ''D'' 
AND DATABASEPROPERTYEX(db.[name],''Status'') = ''ONLINE''
/* ignore any databases that are not the preferred replica */
AND sys.fn_hadr_backup_is_preferred_replica(db.[name]) = 1
GROUP BY db.[name]
HAVING max(bck.backup_finish_date) < getdate() - 1

UNION
--	Traps databases that have never been backed up.
SELECT DISTINCT db.[name]
FROM master..sysdatabases db
WHERE db.[name] NOT IN (SELECT bck.database_name FROM msdb..backupset bck) AND db.[name] <> ''tempdb''
/* ignore any databases that are not the preferred replica */
AND sys.fn_hadr_backup_is_preferred_replica(db.[name]) = 1	


	OPEN DB_CURSOR
		FETCH NEXT FROM DB_CURSOR INTO @DB
		WHILE @@FETCH_STATUS = 0
			BEGIN 
				SET @ErrorString = @ErrorString + @DB + '' ''
				FETCH NEXT FROM DB_CURSOR INTO @DB
			END
		IF @ErrorString <> '' ''
		RAISERROR (''Database(s) %s    not backed up in last 24 hours. Check SQL Log for details'', 16, 1, @ErrorString) WITH LOG
	CLOSE DB_CURSOR
DEALLOCATE DB_CURSOR', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Transaction Log Backups]    Script Date: 06/24/2008 11:20:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Transaction Log Backups', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- ++ Checks job history tables and raises an error for
-- ++ Databases that have not had a tlog back up in the last 4 hours.
-- ++ Created on: 24/06/2008.
-- ++ Created by: Paul Byers.
-- ++ Modified on: 10/05/2011.
-- ++ Modfied by: Tom Braham to include online databases only in the check.
-- ++ Modified on: 05/11/2014.
-- ++ Modfied by: Tom Braham to include preferred databases for SQL2012 only in the check.

SET NOCOUNT ON

DECLARE @DB VARCHAR (50),
		@ErrorString VARCHAR (500)

SET @ErrorString = ''''

DECLARE DB_CURSOR CURSOR FOR
--	traps databases that have not been backed up in 24 hours.
SELECT 	DISTINCT
		db.[NAME] AS DB
FROM 	master.dbo.sysdatabases db
			INNER JOIN msdb..backupset bck ON db.[name] = bck.database_name 
WHERE	db.[name] <> ''tempdb'' 
		AND db.[name] <> ''SystemsHelpdesk'' 
		AND db.[name] <> ''model'' 
		AND DATABASEPROPERTYEX(db.NAME, ''Recovery'')  = ''FULL''
		AND DATABASEPROPERTYEX(db.[name],''Status'') = ''ONLINE''
		/* ignore any databases that are not the preferred replica */
		AND sys.fn_hadr_backup_is_preferred_replica(db.[name]) = 1
GROUP BY db.[name]
HAVING max(bck.backup_finish_date) < DATEADD(hh, -4, GETDATE())

UNION

--	Traps databases that have never been backed up.
SELECT DISTINCT db.[name]
FROM master..sysdatabases db
WHERE	DATABASEPROPERTYEX(db.NAME, ''Recovery'')  = ''FULL''
		AND db.[name] NOT IN (SELECT DISTINCT bck.database_name FROM msdb..backupset bck WHERE bck.type = ''L'') 
		AND db.[name] <> ''tempdb'' 
		AND db.[name] <> ''SystemsHelpdesk'' 
		AND db.[name] <> ''model'' 
		/* ignore any databases that are not the preferred replica */
		AND sys.fn_hadr_backup_is_preferred_replica(db.[name]) = 1


	OPEN DB_CURSOR
		FETCH NEXT FROM DB_CURSOR INTO @DB
		WHILE @@FETCH_STATUS = 0
			BEGIN 
				SET @ErrorString = @ErrorString + @DB + '' ''
				FETCH NEXT FROM DB_CURSOR INTO @DB
			END
		IF @ErrorString <> '' ''
		RAISERROR (''Database(s) %s    had no tlog back up in last 4 hours. Check SQL Log for details'', 16, 1, @ErrorString) WITH LOG
	CLOSE DB_CURSOR
DEALLOCATE DB_CURSOR', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'BackupCheckDaily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20071206, 
		@active_end_date=99991231, 
		@active_start_time=50000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
