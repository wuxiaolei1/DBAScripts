USE [msdb]
GO

/****** Object:  Job [APP DebtRemedy Purge Client PAPs]    Script Date: 04/02/2016 13:23:40 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 04/02/2016 13:23:40 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'APP DebtRemedy Purge Client PAPs', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'SUMMARY
Outputs Non-Proceed WebReference Clients that have not logged in for 12 months for PAP purging

INTERFACES
DebtRemedy: R
DISK: W

SUPPORT NOTES
Run in working hours? Y
Re-run on failure', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Archive and Delete Extracts]    Script Date: 04/02/2016 13:23:41 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Archive and Delete Extracts', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @prevAdvancedOptions INT;
DECLARE @prevXpCmdshell INT;

SELECT  @prevAdvancedOptions = CAST(value_in_use AS INT)
FROM    sys.configurations
WHERE   name = ''show advanced options'';
SELECT  @prevXpCmdshell = CAST(value_in_use AS INT)
FROM    sys.configurations
WHERE   name = ''xp_cmdshell'';

IF ( @prevAdvancedOptions = 0 )
    BEGIN
        EXEC sp_configure ''show advanced options'', 1;
        RECONFIGURE;
    END;

IF ( @prevXpCmdshell = 0 )
    BEGIN
        EXEC sp_configure ''xp_cmdshell'', 1;
        RECONFIGURE;
    END;

/* do work */
DECLARE @sqlCommand VARCHAR(8000);

set @sqlCommand = ''move "E:\SQLOutput\PAPRetention\*.csv" "E:\SQLOutput\PAPRetention\Archive"''

EXEC master..xp_cmdshell @sqlCommand;

set @sqlCommand = ''forfiles -p "E:\SQLOutput\PAPRetention\Archive" -s -m *.csv -d -90 -c "cmd /c del @path"''

EXEC master..xp_cmdshell @sqlCommand;

-- Set it back
IF ( @prevXpCmdshell = 0 )
    BEGIN
        EXEC sp_configure ''xp_cmdshell'', 0;
        RECONFIGURE;
    END;

IF ( @prevAdvancedOptions = 0 )
    BEGIN
        EXEC sp_configure ''show advanced options'', 0;
        RECONFIGURE;
    END;', 
		@database_name=N'master', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Create PAP Drops File]    Script Date: 04/02/2016 13:23:41 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Create PAP Drops File', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @prevAdvancedOptions INT;
DECLARE @prevXpCmdshell INT;

SELECT  @prevAdvancedOptions = CAST(value_in_use AS INT)
FROM    sys.configurations
WHERE   name = ''show advanced options'';
SELECT  @prevXpCmdshell = CAST(value_in_use AS INT)
FROM    sys.configurations
WHERE   name = ''xp_cmdshell'';

IF ( @prevAdvancedOptions = 0 )
    BEGIN
        EXEC sp_configure ''show advanced options'', 1;
        RECONFIGURE;
    END;

IF ( @prevXpCmdshell = 0 )
    BEGIN
        EXEC sp_configure ''xp_cmdshell'', 1;
        RECONFIGURE;
    END;

/* do work */
DECLARE @sqlCommand VARCHAR(8000);
DECLARE @filePath VARCHAR(100);
DECLARE @fileName VARCHAR(100);

SET @filePath = ''E:\SQLOutput\PAPRetention\'';

SET @fileName = ''DebtRemedyPAPDrops'' + +CONVERT(VARCHAR, GETDATE(), 112) + ''.csv'';

SET @sqlCommand = ''SQLCMD -S @@SERVERNAME -E -d DebtRemedy_Live -q "SET NOCOUNT ON UPDATE [dbo].[Clients] SET [CommsPurged] = 1 OUTPUT [Inserted].[VCNumberAdorned], [Inserted].[LastLoginTime] WHERE LastLoginTime < DATEADD(YEAR, -1, GETDATE()) AND CommsPurged IS NULL AND DCSNumber IS NULL;" -o "'' + @filePath + @fileName + ''" -s","''; 

PRINT @sqlCommand;

EXEC master..xp_cmdshell @sqlCommand;

-- Set it back
IF ( @prevXpCmdshell = 0 )
    BEGIN
        EXEC sp_configure ''xp_cmdshell'', 0;
        RECONFIGURE;
    END;

IF ( @prevAdvancedOptions = 0 )
    BEGIN
        EXEC sp_configure ''show advanced options'', 0;
        RECONFIGURE;
    END;', 
		@database_name=N'master', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20150909, 
		@active_end_date=99991231, 
		@active_start_time=70000, 
		@active_end_time=235959, 
		@schedule_uid=N'7819fceb-5e39-44d6-b607-2bea0946bd2a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


