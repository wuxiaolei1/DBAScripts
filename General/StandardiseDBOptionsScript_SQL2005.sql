/* Desc:	This should be used to check that all database options for databases
 *			hosted on a SQL 2005 server have the default options set. 
 *			This can be run in 2 modes,
 *			@CheckOnly = 1: to perform a check of the current options
 *			@CheckOnly = 0: to amend the current database options to the set standard
 *			!!The @CheckOnly and @DatabaseName must be set at the start of the script
 * Author:	Tom Braham
 * Created:	04/06/2009
 *
 */
 

DECLARE @DatabaseName NVARCHAR(128)
DECLARE @CheckOnly BIT

-- *** Change DATABASE NAME here ***
SELECT @DatabaseName = '<DATABASE_NAME>'

-- *** Change CHECK ONLY field here ***
-- *** 1: to perform a check only   ***
-- *** 0: make changes to DB        ***
SELECT @CheckOnly = 1


DECLARE @DFLT_compatibility_level TINYINT
DECLARE @DFLT_collation_name VARCHAR(50)
DECLARE @DFLT_auto_close_on CHAR(3)
DECLARE @DFLT_auto_create_stats_on CHAR(3)
DECLARE @DFLT_auto_shrink_on CHAR(3)
DECLARE @DFLT_auto_update_stats_on CHAR(3)
DECLARE @DFLT_auto_update_stats_async_on CHAR(3)
DECLARE @DFLT_cursor_close_on_commit_on CHAR(3)
DECLARE @DFLT_local_cursor_default VARCHAR(6)
DECLARE @DFLT_ansi_null_default_on CHAR(3)
DECLARE @DFLT_ansi_nulls_on CHAR(3)
DECLARE @DFLT_ansi_padding_on CHAR(3)
DECLARE @DFLT_ansi_warnings_on CHAR(3)
DECLARE @DFLT_arithabort_on CHAR(3)
DECLARE @DFLT_concat_null_yields_null_on CHAR(3)
DECLARE @DFLT_date_correlation_on CHAR(3)
DECLARE @DFLT_numeric_roundabort_on CHAR(3)
DECLARE @DFLT_parameterization_forced CHAR(6)
DECLARE @DFLT_quoted_identifier_on CHAR(3)
DECLARE @DFLT_recursive_triggers_on CHAR(3)
DECLARE @DFLT_page_verify_option  VARCHAR(20)
DECLARE @DFLT_read_only VARCHAR(10)
DECLARE @DFLT_user_access VARCHAR(15)
DECLARE @DFLT_Recovery_Model VARCHAR(12)
DECLARE @DFLT_owner VARCHAR(50)

-- All standard options are set here
SELECT @DFLT_compatibility_level			= 90
SELECT @DFLT_collation_name					= 'Latin1_General_CI_AS'
SELECT @DFLT_auto_close_on					= 'OFF'
SELECT @DFLT_auto_create_stats_on			= 'ON'
SELECT @DFLT_auto_shrink_on					= 'OFF'
SELECT @DFLT_auto_update_stats_on			= 'ON'
SELECT @DFLT_auto_update_stats_async_on		= 'OFF'
SELECT @DFLT_cursor_close_on_commit_on		= 'OFF'
SELECT @DFLT_local_cursor_default			= 'GLOBAL'
SELECT @DFLT_ansi_null_default_on			= 'OFF'
SELECT @DFLT_ansi_nulls_on					= 'OFF'
SELECT @DFLT_ansi_padding_on				= 'OFF'
SELECT @DFLT_ansi_warnings_on				= 'OFF'
SELECT @DFLT_arithabort_on					= 'OFF'
SELECT @DFLT_concat_null_yields_null_on		= 'OFF'
SELECT @DFLT_date_correlation_on			= 'OFF'
SELECT @DFLT_numeric_roundabort_on			= 'OFF'
SELECT @DFLT_parameterization_forced		= 'SIMPLE'
SELECT @DFLT_quoted_identifier_on			= 'OFF'
SELECT @DFLT_recursive_triggers_on			= 'OFF'
SELECT @DFLT_page_verify_option 			= 'CHECKSUM'
SELECT @DFLT_read_only						= 'READ_WRITE'
SELECT @DFLT_user_access					= 'MULTI_USER'
SELECT @DFLT_Recovery_Model					= 'FULL'
SELECT @DFLT_owner							= 'sa'


DECLARE @compatibility_level TINYINT
DECLARE @collation_name VARCHAR(50)
DECLARE @is_auto_close_on BIT
DECLARE @is_auto_create_stats_on BIT
DECLARE @is_auto_shrink_on BIT
DECLARE @is_auto_update_stats_on BIT
DECLARE @is_auto_update_stats_async_on BIT
DECLARE @is_cursor_close_on_commit_on BIT
DECLARE @is_local_cursor_default BIT
DECLARE @is_ansi_null_default_on BIT
DECLARE @is_ansi_nulls_on BIT
DECLARE @is_ansi_padding_on BIT
DECLARE @is_ansi_warnings_on BIT
DECLARE @is_arithabort_on BIT
DECLARE @is_concat_null_yields_null_on BIT
DECLARE @is_date_correlation_on BIT
DECLARE @is_numeric_roundabort_on BIT
DECLARE @is_parameterization_forced BIT
DECLARE @is_quoted_identifier_on BIT
DECLARE @is_recursive_triggers_on BIT
DECLARE @page_verify_option TINYINT
DECLARE @is_read_only BIT
DECLARE @user_access TINYINT
DECLARE @sql NVARCHAR(4000)
DECLARE @Recovery_Model VARCHAR(12)
DECLARE @owner VARCHAR(50)

IF @CheckOnly = 1
	PRINT '-- Checking Database options only --'
ELSE
	PRINT '-- Checking and Amending Database Options --'

IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = @DatabaseName)
BEGIN
	SELECT  @compatibility_level  = sysdbs.compatibility_level,
			@collation_name  = sysdbs.collation_name,
			@is_auto_close_on  = sysdbs.is_auto_close_on,
			@is_auto_create_stats_on  = sysdbs.is_auto_create_stats_on,
			@is_auto_shrink_on  = sysdbs.is_auto_shrink_on,
			@is_auto_update_stats_on  = sysdbs.is_auto_update_stats_on,
			@is_auto_update_stats_async_on  = sysdbs.is_auto_update_stats_async_on,
			@is_cursor_close_on_commit_on  = sysdbs.is_cursor_close_on_commit_on,
			@is_local_cursor_default  = sysdbs.is_local_cursor_default,
			@is_ansi_null_default_on  = sysdbs.is_ansi_null_default_on,
			@is_ansi_nulls_on  = sysdbs.is_ansi_nulls_on,
			@is_ansi_padding_on  = sysdbs.is_ansi_padding_on,
			@is_ansi_warnings_on  = sysdbs.is_ansi_warnings_on,
			@is_arithabort_on  = sysdbs.is_arithabort_on,
			@is_concat_null_yields_null_on  = sysdbs.is_concat_null_yields_null_on,
			@is_date_correlation_on  = sysdbs.is_date_correlation_on,
			@is_numeric_roundabort_on  = sysdbs.is_numeric_roundabort_on,
			@is_parameterization_forced  = sysdbs.is_parameterization_forced,
			@is_quoted_identifier_on  = sysdbs.is_quoted_identifier_on,
			@is_recursive_triggers_on  = sysdbs.is_recursive_triggers_on,
			@page_verify_option  = sysdbs.page_verify_option,
			@is_read_only  = sysdbs.is_read_only,
			@user_access  = sysdbs.user_access,
			@owner = sysl.[name],
			@Recovery_Model = sysdbs.recovery_model_desc
	FROM    sys.databases sysdbs
			INNER JOIN sys.syslogins sysl ON sysdbs.owner_sid = sysl.sid
	WHERE   sysdbs.[name] = @DatabaseName 


	-- check Read Only Status
	IF @is_read_only <> CASE	WHEN @DFLT_read_only = 'READ_WRITE' THEN 0
								WHEN @DFLT_read_only = 'READ_ONLY' THEN 1
								ELSE 1
						END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database Read Only set incorrectly. Current value is ' + CASE @is_read_only
																								WHEN 0 THEN 'OFF'
																								WHEN 1 THEN 'ON'
																							END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ' + @DFLT_read_only + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ' + @DFLT_read_only 
			EXEC(@sql)
			PRINT ' Changed Read Only from ' + CONVERT(CHAR(1),@is_read_only) + ' to ' + @DFLT_read_only 
		END
	END
	ELSE	
		PRINT 'Database Read Only OK'
		
	-- Check compatibility level
	IF @compatibility_level <> @DFLT_compatibility_level
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database Compatibility level set incorrectly. Current value is ' + CONVERT(VARCHAR(2),@compatibility_level)
		END
		ELSE
		BEGIN
			EXEC dbo.sp_dbcmptlevel @dbname=@DatabaseName, @new_cmptlevel=@DFLT_compatibility_level
			PRINT ' Changed Compatibility Level from ' + CONVERT(VARCHAR(2),@compatibility_level) + ' to ' + CONVERT(VARCHAR(2),@DFLT_compatibility_level)
		END	
	END
	ELSE	
		PRINT 'Database Compatibility level OK'

	-- check collation
	IF @collation_name <> @DFLT_collation_name
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database Collation set incorrectly. Current value is ' + @collation_name
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' COLLATE ' + @DFLT_collation_name
			EXEC(@sql)
			PRINT ' Changed Collation from ' + @collation_name + ' to ' + @DFLT_collation_name
		END
	END
	ELSE
		PRINT 'Database Collation OK'

	-- check auto close
	IF @is_auto_close_on <>	CASE	
								WHEN @DFLT_auto_close_on = 'OFF' THEN 0
								WHEN @DFLT_auto_close_on = 'ON' THEN 1
							END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database Auto Close set incorrectly. Current value is ' + CASE @is_auto_close_on
																								WHEN 0 THEN 'OFF'
																								WHEN 1 THEN 'ON'
																							END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET AUTO_CLOSE ' + @DFLT_auto_close_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET AUTO_CLOSE ' + @DFLT_auto_close_on 
			EXEC(@sql)
			PRINT ' Changed Auto Close from ' + CONVERT(CHAR(1),@is_auto_close_on) + ' to ' + @DFLT_auto_close_on
		END
	END
	ELSE	
		PRINT 'Database Auto CLOSE OK'

	-- check auto create stats
	IF @is_auto_create_stats_on <>	CASE	
										WHEN @DFLT_auto_create_stats_on = 'OFF' THEN 0
										WHEN @DFLT_auto_create_stats_on = 'ON' THEN 1
									END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database Auto CREATE Stats set incorrectly. Current value is ' + CASE @is_auto_create_stats_on
																									WHEN 0 THEN 'OFF'
																									WHEN 1 THEN 'ON'
																								  END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET AUTO_CREATE_STATISTICS ' + @DFLT_auto_create_stats_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET AUTO_CREATE_STATISTICS ' + @DFLT_auto_create_stats_on
			EXEC(@sql)
			PRINT ' Changed Auto Create Stats from ' + CONVERT(CHAR(1),@is_auto_create_stats_on) + ' to ' + @DFLT_auto_create_stats_on
		END
	END
	ELSE	
		PRINT 'Database Auto CREATE Stats OK'

	-- check auto shrink
	IF @is_auto_shrink_on <>	CASE	
									WHEN @DFLT_auto_shrink_on = 'OFF' THEN 0
									WHEN @DFLT_auto_shrink_on = 'ON' THEN 1
								END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database Auto Shrink set incorrectly. Current value is ' + CASE @is_auto_shrink_on
																								WHEN 0 THEN 'OFF'
																								WHEN 1 THEN 'ON'
																							END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET AUTO_SHRINK ' + @DFLT_auto_shrink_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET AUTO_SHRINK ' + @DFLT_auto_shrink_on
			EXEC(@sql)
			PRINT ' Changed Auto Shrink from ' + CONVERT(CHAR(1),@is_auto_shrink_on) + ' to ' + @DFLT_auto_shrink_on
		END
	END
	ELSE	
		PRINT 'Database Auto Shrink OK'

	-- check auto update stats
	IF @is_auto_update_stats_on <>	CASE	
										WHEN @DFLT_auto_update_stats_on = 'OFF' THEN 0
										WHEN @DFLT_auto_update_stats_on = 'ON' THEN 1
									END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database Auto update Stats set incorrectly. Current value is ' + CASE @is_auto_update_stats_on
																									WHEN 0 THEN 'OFF'
																									WHEN 1 THEN 'ON'
																								  END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET AUTO_UPDATE_STATISTICS ' + @DFLT_auto_update_stats_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET AUTO_UPDATE_STATISTICS ' + @DFLT_auto_update_stats_on
			EXEC(@sql)
			PRINT ' Changed Auto update Stats from ' + CONVERT(CHAR(1),@is_auto_update_stats_on) + ' to ' + @DFLT_auto_update_stats_on
		END
	END
	ELSE	
		PRINT 'Database Auto update Stats OK'

	-- check auto update stats async
	IF @is_auto_update_stats_async_on <>CASE	
											WHEN @DFLT_auto_update_stats_async_on = 'OFF' THEN 0
											WHEN @DFLT_auto_update_stats_async_on = 'ON' THEN 1
										END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database Auto update Stats async set incorrectly. Current value is ' + CASE @is_auto_update_stats_async_on
																											WHEN 0 THEN 'OFF'
																											WHEN 1 THEN 'ON'
																										END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET AUTO_UPDATE_STATISTICS_ASYNC ' + @DFLT_auto_update_stats_async_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET AUTO_UPDATE_STATISTICS_ASYNC ' + @DFLT_auto_update_stats_async_on
			EXEC(@sql)
			PRINT ' Changed Auto update Stats async from ' + CONVERT(CHAR(1),@is_auto_update_stats_async_on) + ' to ' + @DFLT_auto_update_stats_async_on
		END
	END
	ELSE	
		PRINT 'Database Auto update Stats async OK'

	-- check cursor close on commit
	IF @is_cursor_close_on_commit_on <>	CASE	
											WHEN @DFLT_cursor_close_on_commit_on = 'OFF' THEN 0
											WHEN @DFLT_cursor_close_on_commit_on = 'ON' THEN 1
										END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database cursor close on commit set incorrectly. Current value is ' + CASE @is_cursor_close_on_commit_on
																											WHEN 0 THEN 'OFF'
																											WHEN 1 THEN 'ON'
																										END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET CURSOR_CLOSE_ON_COMMIT ' + @DFLT_cursor_close_on_commit_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET CURSOR_CLOSE_ON_COMMIT ' + @DFLT_cursor_close_on_commit_on
			EXEC(@sql)
			PRINT ' Changed cursor close on commit from ' + CONVERT(CHAR(1),@is_cursor_close_on_commit_on) + ' to ' + @DFLT_cursor_close_on_commit_on
		END
	END
	ELSE	
		PRINT 'Database cursor close on commit OK'


	-- check default cursor 
	IF @is_local_cursor_default <>	CASE	
										WHEN @DFLT_local_cursor_default = 'GLOBAL' THEN 0
										WHEN @DFLT_local_cursor_default = 'LOCAL' THEN 1
									END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database default cursor set incorrectly. Current value is ' + CASE @is_local_cursor_default
																									WHEN 0 THEN 'GLOBAL'
																									WHEN 1 THEN 'LOCAL'
																								END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET CURSOR_DEFAULT ' + @DFLT_local_cursor_default + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET CURSOR_DEFAULT ' + @DFLT_local_cursor_default
			EXEC(@sql)
			PRINT ' Changed default cursor from ' + CONVERT(CHAR(1),@is_local_cursor_default) + ' to ' + @DFLT_local_cursor_default
		END
	END
	ELSE	
		PRINT 'Database default cursor OK'
		

	-- check ansi null default
	IF @is_ansi_null_default_on <>	CASE	
										WHEN @DFLT_ansi_null_default_on = 'OFF' THEN 0
										WHEN @DFLT_ansi_null_default_on = 'ON' THEN 1
									END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database ansi null default set incorrectly. Current value is ' + CASE @is_ansi_null_default_on
																									WHEN 0 THEN 'OFF'
																									WHEN 1 THEN 'ON'
																								  END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ANSI_NULL_DEFAULT ' + @DFLT_ansi_null_default_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ANSI_NULL_DEFAULT ' + @DFLT_ansi_null_default_on
			EXEC(@sql)
			PRINT ' Changed ansi null default from ' + CONVERT(CHAR(1),@is_ansi_null_default_on) + ' to ' + @DFLT_ansi_null_default_on
		END
	END
	ELSE	
		PRINT 'Database ansi null default OK'

	-- check ansi nulls
	IF @is_ansi_nulls_on <>	CASE	
								WHEN @DFLT_ansi_nulls_on = 'OFF' THEN 0
								WHEN @DFLT_ansi_nulls_on = 'ON' THEN 1
							END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database ansi nulls set incorrectly. Current value is ' + CASE @is_ansi_nulls_on
																								WHEN 0 THEN 'OFF'
																								WHEN 1 THEN 'ON'
																							END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ANSI_NULLS ' + @DFLT_ansi_nulls_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ANSI_NULLS ' + @DFLT_ansi_nulls_on
			EXEC(@sql)
			PRINT ' Changed ansi nulls from ' + CONVERT(CHAR(1),@is_ansi_nulls_on) + ' to ' + @DFLT_ansi_nulls_on
		END
	END
	ELSE	
		PRINT 'Database ansi nulls OK'
		
	-- check ansi padding
	IF @is_ansi_padding_on <>	CASE	
									WHEN @DFLT_ansi_padding_on = 'OFF' THEN 0
									WHEN @DFLT_ansi_padding_on = 'ON' THEN 1
								END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database ansi padding set incorrectly. Current value is ' + CASE @is_ansi_padding_on
																								WHEN 0 THEN 'OFF'
																								WHEN 1 THEN 'ON'
																							 END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ANSI_PADDING ' + @DFLT_ansi_padding_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ANSI_PADDING ' + @DFLT_ansi_padding_on
			EXEC(@sql)
			PRINT ' Changed ansi padding from ' + CONVERT(CHAR(1),@is_ansi_padding_on) + ' to ' + @DFLT_ansi_padding_on
		END
	END
	ELSE	
		PRINT 'Database ansi padding OK'

	-- check ansi warnings
	IF @is_ansi_warnings_on <>	CASE	
									WHEN @DFLT_ansi_padding_on = 'OFF' THEN 0
									WHEN @DFLT_ansi_padding_on = 'ON' THEN 1
								END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database ansi warnings set incorrectly. Current value is ' + CASE @is_ansi_warnings_on
																								WHEN 0 THEN 'OFF'
																								WHEN 1 THEN 'ON'
																							  END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ANSI_WARNINGS ' + @DFLT_ansi_warnings_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ANSI_WARNINGS ' + @DFLT_ansi_warnings_on
			EXEC(@sql)
			PRINT ' Changed ansi warnings from ' + CONVERT(CHAR(1),@is_ansi_warnings_on) + ' to ' + @DFLT_ansi_warnings_on
		END
	END
	ELSE	
		PRINT 'Database ansi warnings OK'

	-- check ARITHABORT
	IF @is_arithabort_on <>	CASE	
								WHEN @DFLT_arithabort_on = 'OFF' THEN 0
								WHEN @DFLT_arithabort_on = 'ON' THEN 1
							END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database ARITHABORT set incorrectly. Current value is ' + CASE @is_arithabort_on
																								WHEN 0 THEN 'OFF'
																								WHEN 1 THEN 'ON'
																							END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ARITHABORT ' + @DFLT_arithabort_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ARITHABORT ' + @DFLT_arithabort_on
			EXEC(@sql)
			PRINT ' Changed ARITHABORT from ' + CONVERT(CHAR(1),@is_arithabort_on) + ' to ' + @DFLT_arithabort_on
		END
	END
	ELSE	
		PRINT 'Database ARITHABORT OK'

	-- check CONCAT_NULL_YIELDS_NULL
	IF @is_concat_null_yields_null_on <>	CASE	
												WHEN @DFLT_concat_null_yields_null_on = 'OFF' THEN 0
												WHEN @DFLT_concat_null_yields_null_on = 'ON' THEN 1
											END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database CONCAT_NULL_YIELDS_NULL set incorrectly. Current value is ' + CASE @is_concat_null_yields_null_on
																											WHEN 0 THEN 'OFF'
																											WHEN 1 THEN 'ON'
																										END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET CONCAT_NULL_YIELDS_NULL ' + @DFLT_concat_null_yields_null_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET CONCAT_NULL_YIELDS_NULL ' + @DFLT_concat_null_yields_null_on
			EXEC(@sql)
			PRINT ' Changed CONCAT_NULL_YIELDS_NULL from ' + CONVERT(CHAR(1),@is_concat_null_yields_null_on) + ' to ' + @DFLT_concat_null_yields_null_on
		END
	END
	ELSE	
		PRINT 'Database CONCAT_NULL_YIELDS_NULL OK'

	-- check DATE_CORRELATION_OPTIMIZATION
	IF @is_date_correlation_on <>	CASE	
										WHEN @DFLT_date_correlation_on = 'OFF' THEN 0
										WHEN @DFLT_date_correlation_on = 'ON' THEN 1
									END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database DATE_CORRELATION_OPTIMIZATION set incorrectly. Current value is ' + CASE @is_date_correlation_on
																												WHEN 0 THEN 'OFF'
																												WHEN 1 THEN 'ON'
																											  END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET DATE_CORRELATION_OPTIMIZATION ' + @DFLT_date_correlation_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET DATE_CORRELATION_OPTIMIZATION ' + @DFLT_date_correlation_on
			EXEC(@sql)
			PRINT ' Changed DATE_CORRELATION_OPTIMIZATION from ' + CONVERT(CHAR(1),@is_date_correlation_on) + ' to ' + @DFLT_date_correlation_on
		END
	END
	ELSE	
		PRINT 'Database DATE_CORRELATION_OPTIMIZATION OK'

	-- check NUMERIC_ROUNDABORT
	IF @is_numeric_roundabort_on <>	CASE	
										WHEN @DFLT_numeric_roundabort_on = 'OFF' THEN 0
										WHEN @DFLT_numeric_roundabort_on = 'ON' THEN 1
									END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database NUMERIC_ROUNDABORT set incorrectly. Current value is ' + CASE @is_numeric_roundabort_on
																										WHEN 0 THEN 'OFF'
																										WHEN 1 THEN 'ON'
																								   END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET NUMERIC_ROUNDABORT ' + @DFLT_numeric_roundabort_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET NUMERIC_ROUNDABORT ' + @DFLT_numeric_roundabort_on
			EXEC(@sql)
			PRINT ' Changed NUMERIC_ROUNDABORT from ' + CONVERT(CHAR(1),@is_numeric_roundabort_on) + ' to ' + @DFLT_numeric_roundabort_on
		END
	END
	ELSE	
		PRINT 'Database NUMERIC_ROUNDABORT OK'

	-- check PARAMETERIZATION
	IF @is_parameterization_forced <>	CASE	
											WHEN @DFLT_parameterization_forced = 'SIMPLE' THEN 0
											WHEN @DFLT_parameterization_forced = 'FORCED' THEN 1
										END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database PARAMETERIZATION set incorrectly. Current value is ' + CASE @is_parameterization_forced
																									WHEN 0 THEN 'SIMPLE'
																									WHEN 1 THEN 'FORCED'
																								 END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET PARAMETERIZATION ' + @DFLT_parameterization_forced + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET PARAMETERIZATION ' + @DFLT_parameterization_forced
			EXEC(@sql)
			PRINT ' Changed PARAMETERIZATION from ' + CONVERT(CHAR(1),@is_parameterization_forced) + ' to ' + @DFLT_parameterization_forced
		END
	END
	ELSE	
		PRINT 'Database PARAMETERIZATION OK'

	-- check QUOTED_IDENTIFIER
	IF @is_quoted_identifier_on <>	CASE	
										WHEN @DFLT_quoted_identifier_on = 'OFF' THEN 0
										WHEN @DFLT_quoted_identifier_on = 'ON' THEN 1
									END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database QUOTED_IDENTIFIER set incorrectly. Current value is ' + CASE @is_quoted_identifier_on
																										WHEN 0 THEN 'OFF'
																										WHEN 1 THEN 'ON'
																								  END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET QUOTED_IDENTIFIER ' + @DFLT_quoted_identifier_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET QUOTED_IDENTIFIER ' + @DFLT_quoted_identifier_on
			EXEC(@sql)
			PRINT ' Changed QUOTED_IDENTIFIER from ' + CONVERT(CHAR(1),@is_quoted_identifier_on) + ' to ' + @DFLT_quoted_identifier_on
		END
	END
	ELSE	
		PRINT 'Database QUOTED_IDENTIFIER OK'

	-- check RECURSIVE_TRIGGERS
	IF @is_recursive_triggers_on <>	CASE	
										WHEN @DFLT_recursive_triggers_on = 'OFF' THEN 0
										WHEN @DFLT_recursive_triggers_on = 'ON' THEN 1
									END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database RECURSIVE_TRIGGERS set incorrectly. Current value is ' + CASE @is_recursive_triggers_on
																										WHEN 0 THEN 'OFF'
																										WHEN 1 THEN 'ON'
																								   END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET RECURSIVE_TRIGGERS ' + @DFLT_recursive_triggers_on + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET RECURSIVE_TRIGGERS ' + @DFLT_recursive_triggers_on
			EXEC(@sql)
			PRINT ' Changed RECURSIVE_TRIGGERS from ' + CONVERT(CHAR(1),@is_recursive_triggers_on) + ' to ' + @DFLT_recursive_triggers_on
		END
	END
	ELSE	
		PRINT 'Database RECURSIVE_TRIGGERS OK'
		
	-- check User Access
	IF @user_access <>	CASE	
							WHEN @DFLT_user_access = 'MULTI_USER' THEN 0
							WHEN @DFLT_user_access = 'SINGLE_USER' THEN 1
							WHEN @DFLT_user_access = 'RESTRICTED_USER' THEN 2
						END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database User Access set incorrectly. Current value is ' + CASE @user_access 
																								WHEN 0 THEN 'MULTI_USER' 
																								WHEN 1 THEN 'SINGLE_USER' 
																								WHEN 2 THEN 'RESTRICTED_USER' 
																							END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ' + @DFLT_user_access + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET ' + @DFLT_user_access
			EXEC(@sql)
			PRINT ' Changed User Access from ' + CONVERT(CHAR(1),@user_access) + ' to ' + @DFLT_user_access
		END
	END
	ELSE	
		PRINT 'Database User Access OK'
		
	-- check Page verification
	IF @page_verify_option <>	CASE	
									WHEN @DFLT_page_verify_option = 'NONE' THEN 0
									WHEN @DFLT_page_verify_option = 'TORN_PAGE_DETECTION' THEN 1
									WHEN @DFLT_page_verify_option = 'CHECKSUM' THEN 2
								END
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database Page verification set incorrectly. Current value is ' +  CASE @page_verify_option
																										WHEN 0 THEN 'NONE'
																										WHEN 1 THEN 'TORN_PAGE_DETECTION'
																										WHEN 2 THEN 'CHECKSUM' 
																									END
		END
		ELSE
		BEGIN
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET PAGE_VERIFY ' + @DFLT_page_verify_option + ' WITH NO_WAIT'
			EXEC(@sql)
			SELECT @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET PAGE_VERIFY ' + @DFLT_page_verify_option
			EXEC(@sql)
			PRINT ' Changed Page verification from ' + CONVERT(CHAR(3),@page_verify_option) + ' to ' + @DFLT_page_verify_option
		END
	END
	ELSE	
		PRINT 'Database Page verification OK'


	-- check database recovery model
	IF @Recovery_model <> @DFLT_Recovery_Model
	BEGIN
		PRINT '*** ERROR *** Database Recovery Model set incorrectly. Current value is ' + @Recovery_model
		PRINT 'Database Recovery Model must be changed manually'
	END
	ELSE	
		PRINT 'Database Recover Model OK, recovery model is ' + @Recovery_model
		
	-- check database owner
	IF @owner <> @DFLT_owner OR @owner IS NULL
	BEGIN
		IF @CheckOnly = 1
		BEGIN
			PRINT '*** ERROR *** Database owner set incorrectly. Current value is ' +  ISNULL(@owner, 'unknown')
		END
		ELSE
		BEGIN
			SELECT @sql = 'EXEC ' + @DatabaseName + '.dbo.sp_changedbowner @loginame = ' + CHAR(39) + @DFLT_owner + CHAR(39) + ', @map = false;' 
			EXEC(@sql)
			PRINT ' Changed database owner from ' + @owner + ' to ' + @DFLT_owner
		END
	END
	ELSE	
		PRINT 'Database owner OK'
		
END
ELSE
BEGIN
	PRINT 'Database ' + @DatabaseName + ' not found'
END

PRINT '-- End of Database options check --'
-------------------


