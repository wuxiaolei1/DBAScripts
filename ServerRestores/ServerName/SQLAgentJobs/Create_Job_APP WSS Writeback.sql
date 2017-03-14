USE [msdb]
GO

/****** Object:  Job [APP WSS Writeback]    Script Date: 08/29/2013 12:01:05 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [WebsiteServices]    Script Date: 08/29/2013 12:01:06 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'WebsiteServices' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'WebsiteServices'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP WSS Writeback', 
		@enabled=0, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Executes a batch file that writes information back to DMS and DCS from WebsiteServices

INTERFACES
WebsiteServices: R
DCSLive: CRU
DMS: CRU

SUPPORT NOTES
Leave to run at next scheduled occurance following failure
Errors should be escalated to application support

', 
		@category_name=N'WebsiteServices', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Prevent Writeback]    Script Date: 08/29/2013 12:01:06 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Prevent Writeback', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=1, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET nocount ON

DECLARE @batch_id VARCHAR(10)
   ,@bank_acct_code CHAR(1)

SET ROWCOUNT 1
SELECT  @batch_id = bh.batchid
FROM    LDSDMSPRO1DBA01.DMS.dbo.batch_header bh
        INNER JOIN LDSDMSPRO1DBA01.DMS.dbo.disbursement_history dh ON bh.batchid = dh.batchid
WHERE   bh.type = 4 AND
        bh.status = 10 AND
        dh.scope = 0

-- must have a bank acct code to pass to the stored procedure
-- picking the first one in the table
SELECT  @bank_acct_code = id
FROM    LDSDMSPRO1DBA01.DMS.dbo.bank_acct_file
SET ROWCOUNT 0


IF @batch_id IS NOT NULL AND
    @bank_acct_code IS NOT NULL 
    BEGIN

        SELECT  A
        FROM    NonExistentTable

    END
', 
		@database_name=N'WebsiteServices', 
		@output_file_name=N'C:\Applications\DMSWriteback\PreventWriteBack.txt', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DMS Writeback]    Script Date: 08/29/2013 12:01:06 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DMS Writeback', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=3, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'"C:\Applications\DMSWriteback\SQLDMSWriteback.bat"', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Fail notification]    Script Date: 08/29/2013 12:01:06 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Fail notification', 
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
	--exec dbo.job_fail_notification @System=''WebsiteServices'',@Subsystem=''Writeback'',@Message=''Writeback (WSS -> DCS/DMS) failed for an unknown reason. Please inform the business. Davidk will receive a detailed log''
	--exec dbo.job_fail_notification @OverrideTo=''davidk@stepchange.org'',@System=''WebsiteServices'',@Subsystem=''Writeback'',@Message=''Writeback failed'',@AttachFile=''C:\DMSWriteback.txt''
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
		@active_start_date=20090912, 
		@active_end_date=99991231, 
		@active_start_time=220500, 
		@active_end_time=235959, 
		@schedule_uid=N'3c3b398c-cb4f-4912-94db-d4c9c70b1dd1'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


