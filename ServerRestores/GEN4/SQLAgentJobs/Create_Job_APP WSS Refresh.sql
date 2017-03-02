USE [msdb]
GO

/****** Object:  Job [APP WSS Refresh]    Script Date: 08/29/2013 12:00:51 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [WebsiteServices]    Script Date: 08/29/2013 12:00:51 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'WebsiteServices' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'WebsiteServices'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP WSS Refresh', 
		@enabled=0, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Updates Cred Web Services with latest client and creditor information from DCS & DMS

INTERFACES
WebsiteServices: CRUD
DCSLive: R
DMS: R

SUPPORT NOTES
Leave to run at next scheduled occurance following failure
Errors can be escalated to application support

', 
		@category_name=N'WebsiteServices', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Creditor Services - Data Refresh]    Script Date: 08/29/2013 12:00:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Creditor Services - Data Refresh', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=4, 
		@on_fail_step_id=3, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec CreditorServices.DataRefresh', 
		@database_name=N'WebsiteServices', 
		@output_file_name=N'C:\SQLFiles\WSSRefresh.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DocuTrieve]    Script Date: 08/29/2013 12:00:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DocuTrieve', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=4, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'"C:\Applications\DocuTrieve\DocuTrieveExtract.exe"', 
		@output_file_name=N'C:\Applications\DocuTrieve\docutrieve.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Fail notification (Refresh)]    Script Date: 08/29/2013 12:00:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Fail notification (Refresh)', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=2, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
	--exec dbo.job_fail_notification @System=''WebsiteServices'',@Subsystem=''Refresh'',@Message=''Refresh (DCS/DMS -> WSS) failed for an unknown reason. Please inform the business. Davidk will receive a detailed log'',@AttachFile=''C:\WSSRefresh.txt''
	--exec dbo.job_fail_notification @OverrideTo=''davidk@stepchange.org'',@System=''WebsiteServices'',@Subsystem=''Refresh'',@Message=''Refresh failed'',@AttachFile=''C:\WSSRefresh.txt''
', 
		@database_name=N'SystemsHelpdesk', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Fail notification (DocuTrieve)]    Script Date: 08/29/2013 12:00:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Fail notification (DocuTrieve)', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=2, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
	--exec dbo.job_fail_notification @System=''WebsiteServices'',@Subsystem=''Refresh'',@Message=''DocuTrieve extract for Client Authorities failed for an unknown reason. Please inform the business. Davidk will receive a detailed log''
	--exec dbo.job_fail_notification @OverrideTo=''davidk@stepchange.org'',@System=''WebsiteServices'',@Subsystem=''Refresh'',@Message=''DocuTrieve extract failed'',@AttachFile=''C:\DocuTrieve.txt''
', 
		@database_name=N'SystemsHelpdesk', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'1', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20100321, 
		@active_end_date=99991231, 
		@active_start_time=40000, 
		@active_end_time=235959, 
		@schedule_uid=N'36897ac0-e26d-44df-99ad-bf73e2d7a98c'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


