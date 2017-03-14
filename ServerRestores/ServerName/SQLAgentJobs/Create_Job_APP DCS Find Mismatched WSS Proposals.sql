USE [msdb]
GO

/****** Object:  Job [APP DCS Find Mismatched WSS Proposals]    Script Date: 08/29/2013 14:06:38 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [APPLICATION]    Script Date: 08/29/2013 14:06:38 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'APPLICATION' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'APPLICATION'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP DCS Find Mismatched WSS Proposals', 
		@enabled=0, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Finds creditor codes who are set to receive proposals via Creditor Web Services, but for whom no abstract creditor can be found in the WebsiteServices database. Normally the result of an incorrect SIC in DMS.

INTERFACES
C:\SQLFiles\DodgySICCodes.txt: C
DCSLive: R
SystemsHelpDesk
WebsiteServices: R

SUPPORT NOTES
Run in working hours? N
Leave the job to run on its next schedule in the event of failure.
', 
		@category_name=N'APPLICATION', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Exists?]    Script Date: 08/29/2013 14:06:38 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Exists?', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=1, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'if not exists(select
	*
from
	DCSSERVER.DCSLive.dbo.tblAssocCommDelivery acd
		inner join
	DCSSERVER.DCSLive.dbo.tblCreditor c
		on
			acd.ACD_AssociateID = c.CRID
		inner join
	DCSSERVER.DCSLive.dbo.tblCommPackDelivery cpd
		on
			acd.ACD_CommPackDeliveryID = cpd.CPD_ID
		inner join
	DCSSERVER.DCSLive.dbo.tblCommProductionQueue cpq
		on
			cpd.CPD_ProductionQueueID = cpq.PQ_ID
		left join
	dbo.Creditors wss
		on
			c.CR_DMSCode = wss.Code collate database_default and
			wss.AbstractCreditorID is not null
where
	PQ_MediumID=11 and
	wss.CreditorID is null and
	CURRENT_TIMESTAMP between acd.ACD_ValidFromDate and acd.ACD_ValidToDate
)
begin
	select * from NonExistentTable
end', 
		@database_name=N'WebsiteServices', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Export]    Script Date: 08/29/2013 14:06:38 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Export', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=4, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'print ''The following codes'''' proposals are being delivered through Website Services. However, their SICs do not match any known Website Services creditor''
select distinct
	c.CR_DMSCode
from
	DCSSERVER.DCSLive.dbo.tblAssocCommDelivery acd
		inner join
	DCSSERVER.DCSLive.dbo.tblCreditor c
		on
			acd.ACD_AssociateID = c.CRID
		inner join
	DCSSERVER.DCSLive.dbo.tblCommPackDelivery cpd
		on
			acd.ACD_CommPackDeliveryID = cpd.CPD_ID
		inner join
	DCSSERVER.DCSLive.dbo.tblCommProductionQueue cpq
		on
			cpd.CPD_ProductionQueueID = cpq.PQ_ID
		left join
	dbo.Creditors wss
		on
			c.CR_DMSCode = wss.Code collate database_default and
			wss.AbstractCreditorID is not null
where
	PQ_MediumID=11 and
	wss.CreditorID is null and
	CURRENT_TIMESTAMP between acd.ACD_ValidFromDate and acd.ACD_ValidToDate
', 
		@database_name=N'WebsiteServices', 
		@output_file_name=N'C:\SQLFiles\DodgySICCodes.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Report]    Script Date: 08/29/2013 14:06:38 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Report', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=4, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--exec dbo.job_fail_notification @OverrideTo=''davidk@stepchange.org'',@Cc=''davidk@stepchange.org'',@System=''DMS'',@Subsystem=''SICs'',@Message=''The attached codes represent a mismatch of SIC information between DMS and Website Services. Usually, this is because of an incorrectly set SIC in DMS'',@AttachFile=''C:\SQLFiles\DodgySICCodes.txt''', 
		@database_name=N'SystemsHelpDesk', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Errored]    Script Date: 08/29/2013 14:06:38 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Errored', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=2, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--exec dbo.job_fail_notification @System=''DMS'',@Subsystem=''SIC check'',@Message=''An error has occurred whilst attempting to determine if there is a SIC Mismatch between DMS and WSS''', 
		@database_name=N'SystemsHelpDesk', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'KeepEmOnTheirToes', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=62, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20080903, 
		@active_end_date=99991231, 
		@active_start_time=63000, 
		@active_end_time=235959, 
		@schedule_uid=N'dcd44bc8-6f79-445b-8eaf-22289f3fb5e9'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


