USE [msdb]
GO

/****** Object:  Job [APP DRO Imported Client Report]    Script Date: 08/29/2013 14:16:31 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/29/2013 14:16:31 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP DRO Imported Client Report', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Reports on clients imported into the DROFS database and whether those clients have been auto non-proceeded.

INTERFACES
DROFS: R
msdb

SUPPORT NOTES
Run in working hours? N
Leave the job to run on its next schedule in the event of failure.
', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DRO Imported Client Report]    Script Date: 08/29/2013 14:16:31 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DRO Imported Client Report', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DROFS
GO

SELECT --DISTINCT
	C.DCSNumber
	--CAST(C.DCSNumber AS VARCHAR(15))
	-- + '', '' +
	--C.FirstName + '' '' + C.LastName 
	--,NDC.DateOffered
	--,C.NonProceedDate
	--,C.CreatedOnDate
FROM 
	dbo.Clients C
INNER JOIN --Only include if it is in the Clients table
	dbo.NewDROClients NDC
ON NDC.DCSNumber = C.DCSNumber
--AND DATEADD(dd, 0, DATEDIFF(dd, 0, C.CreatedOnDate)) = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))

INNER JOIN dbo.ImportBatch IB
ON NDC.BatchId = IB.BatchId
AND IB.BatchId = (SELECT MAX(BatchID) FROM dbo.ImportBatch)

--WHERE NDC.BatchID = (SELECT MAX(BatchID) FROM dbo.ImportBatch)
WHERE DATEADD(dd, 0, DATEDIFF(dd, 0, C.CreatedOnDate)) = DATEADD(dd, 0, DATEDIFF(dd, 0, IB.DateCreated))

--AND C.NonProceedDate IS NOT NULL

ORDER BY C.DCSNumber
', 
		@database_name=N'master', 
		@output_file_name=N'C:\Applications\DRO\DROClientList.txt', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Email Report]    Script Date: 08/29/2013 14:16:31 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Email Report', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
--		EXEC msdb.dbo.sp_send_dbmail
--				@profile_name  = N''DROMail''			
--				,@recipients	= ''clairer@stepchange.org; BirminghamTeamLeaders@stepchange.org;Simon.Franks-Allen@stepchange.org''
--				--,@copy_recipients = @CC
--				--,@blind_copy_recipients = @BCC
--				--,@importance = N''HIGH''
--				,@subject		= ''Clients Imported into DRO on last run''			
--				,@body_format	= N''TEXT''
--				,@body		= ''List of clients imported into DRO''
--				,@file_attachments	= ''C:\Applications\DRO\DROClientList.txt''
', 
		@database_name=N'master', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily Run', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120511, 
		@active_end_date=99991231, 
		@active_start_time=90000, 
		@active_end_time=235959, 
		@schedule_uid=N'16976156-a273-468c-92cb-49564a7d9b93'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


