USE [msdb]
GO

/****** Object:  Job [APP DRO ClientImport]    Script Date: 08/29/2013 14:10:07 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 08/29/2013 14:10:07 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP DRO ClientImport', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Imports DRO candidate clients from TCS and Debt Remedy into staging tables in the DROFS database ready for business rule processing.

INTERFACES
DCSLive: R
DebtRemedy_Live: R
DROFS: C
TCS: R

SUPPORT NOTES
Run in working hours? N
Leave the job to run on its next schedule in the event of failure.
', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ClientImport]    Script Date: 08/29/2013 14:10:07 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ClientImport', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'SSIS', 
		@command=N'/SQL "\DROImportPackage" /SERVER VM11GENPRODBA03 /CONNECTION DCS;"\"Data Source=VM11DCSSERVER;User ID=DROUser;Initial Catalog=DCSLive;Provider=SQLNCLI.1;Persist Security Info=True;\"" /CONNECTION DR;"\"Data Source=VM11WEBPRODBA03;User ID=DROUser;Initial Catalog=DebtRemedy_Live;Provider=SQLNCLI.1;Persist Security Info=True;\"" /CONNECTION DROFS;"\"Data Source=VM11GENPRODBA03;Initial Catalog=CCCS.DROFS;Provider=SQLNCLI10.1;Integrated Security=SSPI;\"" /CONNECTION TCS;"\"Data Source=VM11TCSPRODBA01;User ID=DROUser;Initial Catalog=TCS;Provider=SQLNCLI.1;Persist Security Info=True;\"" /CHECKPOINTING OFF /REPORTING E', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DRO Import Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120723, 
		@active_end_date=99991231, 
		@active_start_time=230000, 
		@active_end_time=235959, 
		@schedule_uid=N'8430eaeb-c192-47cf-800d-7e9fd76deca8'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


