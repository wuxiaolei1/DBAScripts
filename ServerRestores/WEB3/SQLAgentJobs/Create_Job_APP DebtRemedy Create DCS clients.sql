USE [msdb]
GO

/****** Object:  Job [APP DebtRemedy Create DCS clients]    Script Date: 04/02/2016 13:20:52 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [APPLICATION]    Script Date: 04/02/2016 13:20:53 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'APPLICATION' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'APPLICATION'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP DebtRemedy Create DCS clients', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Creates clients within the DCS database

INTERFACES
DebtRemedy_Live: C/R/U/D
DCS: C/R/U
SystemsHelpdesk
msdb

SUPPORT NOTES
Run in working hours? Y
Job runs every 15 mins
Impact for failures is that client details will not appear in the DCS database, resulting in a delay to sending client communications. Clients should receive comms within a certain response time, therefore failures should be investigated as a priority
An email will be sent to service desk if a failure occurs

- Remov', 
		@category_name=N'APPLICATION', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [exec SP]    Script Date: 04/02/2016 13:20:53 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'exec SP', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=2, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF EXISTS (SELECT * FROM dcs.FailedTransfers)
BEGIN
	PRINT ''Error Row/s Deleted:''
	SELECT * FROM dcs.FailedTransfers
	DELETE FROM dcs.FailedTransfers
END

EXEC DCS.TransferClients', 
		@database_name=N'DebtRemedy_Live', 
		@output_file_name=N'C:\SQLOutput\CreateDCSSolutionsClients_Output.txt', 
		@flags=10
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Fail notification (Writeback)]    Script Date: 04/02/2016 13:20:53 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Fail notification (Writeback)', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=2, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
	exec dbo.job_fail_notification @BCC=''systemsapplicationsupport@stepchange.org'',@OverrideTo=''systemssqladmin@stepchange.org'',@System=''Debt Remedy'',@Subsystem=''Writeback'',@Message=''Writeback failed for an unknown reason. Please inform the business. Systems Application Support will review a detailed log''
', 
		@database_name=N'SystemsHelpDesk', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Frequent', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20060817, 
		@active_end_date=99991231, 
		@active_start_time=61700, 
		@active_end_time=215959, 
		@schedule_uid=N'febaead2-c628-4358-bf51-294fec94618c'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


