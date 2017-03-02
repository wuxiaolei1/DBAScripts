SET NOCOUNT ON;

-- LIST OF DATABASES TO RUN THIS SCRIPT FOR ( ALL BY DEFAULT )

DECLARE @dbs TABLE (name SYSNAME NOT NULL);
INSERT @dbs (name)
SELECT name FROM master.sys.databases;
-- ADD FILTER HERE




-- CHECK DATABASE OPTIONS

;WITH correct_values (attribute, value) AS
(
-- Correct values
SELECT 'collation_name' AS attribute, N'Latin1_General_CI_AS' AS value UNION ALL
SELECT 'compatibility_level', CAST(((@@MICROSOFTVERSION / 0x01000000) * 10) AS NVARCHAR(100)) UNION ALL
SELECT 'is_ansi_null_default_on', N'False' UNION ALL
SELECT 'is_ansi_nulls_on', N'False' UNION ALL
SELECT 'is_ansi_padding_on', N'False' UNION ALL
SELECT 'is_ansi_warnings_on', N'False' UNION ALL
SELECT 'is_arithabort_on', N'False' UNION ALL
SELECT 'is_auto_close_on', N'False' UNION ALL
SELECT 'is_auto_create_stats_on', N'True' UNION ALL
SELECT 'is_auto_shrink_on', N'False' UNION ALL
SELECT 'is_auto_update_stats_async_on', N'False' UNION ALL
SELECT 'is_auto_update_stats_on', N'True' UNION ALL
SELECT 'is_broker_enabled', N'True' UNION ALL
SELECT 'is_concat_null_yields_null_on', N'False' UNION ALL
SELECT 'is_cursor_close_on_commit_on', N'False' UNION ALL
SELECT 'is_date_correlation_on', N'False' UNION ALL
SELECT 'is_local_cursor_default', N'False' UNION ALL
SELECT 'is_numeric_roundabort_on', N'False' UNION ALL
SELECT 'is_parameterization_forced', N'False' UNION ALL
SELECT 'is_quoted_identifier_on', N'False' UNION ALL
SELECT 'is_read_committed_snapshot_on', N'False' UNION ALL
SELECT 'is_read_only', N'False' UNION ALL
SELECT 'is_recursive_triggers_on', N'False' UNION ALL
SELECT 'is_trustworthy_on', N'False' UNION ALL
SELECT 'page_verify_option_desc', N'CHECKSUM' UNION ALL
SELECT 'snapshot_isolation_state', N'False' UNION ALL
SELECT 'user_access_desc', N'MULTI_USER'
),
actual_values (name, attribute, value) AS
(
-- Actual values
SELECT
name,
attribute,
CASE value WHEN 0 THEN N'False' ELSE N'True' END AS value
FROM
(SELECT
name,
is_ansi_null_default_on,
is_ansi_nulls_on,
is_ansi_padding_on,
is_ansi_warnings_on,
is_arithabort_on,
is_auto_close_on,
is_auto_create_stats_on,
is_auto_shrink_on,
is_auto_update_stats_async_on,
is_auto_update_stats_on,
is_broker_enabled,
is_concat_null_yields_null_on,
is_cursor_close_on_commit_on,
is_date_correlation_on,
is_local_cursor_default,
is_numeric_roundabort_on,
is_parameterization_forced,
is_quoted_identifier_on,
is_read_committed_snapshot_on,
is_read_only,
is_recursive_triggers_on,
is_trustworthy_on
FROM master.sys.databases
WHERE name IN (SELECT name FROM @dbs)
) switches
UNPIVOT (
value FOR attribute IN (
is_ansi_null_default_on,
is_ansi_nulls_on,
is_ansi_padding_on,
is_ansi_warnings_on,
is_arithabort_on,
is_auto_close_on,
is_auto_create_stats_on,
is_auto_shrink_on,
is_auto_update_stats_async_on,
is_auto_update_stats_on,
is_broker_enabled,
is_concat_null_yields_null_on,
is_cursor_close_on_commit_on,
is_date_correlation_on,
is_local_cursor_default,
is_numeric_roundabort_on,
is_parameterization_forced,
is_quoted_identifier_on,
is_read_committed_snapshot_on,
is_read_only,
is_recursive_triggers_on,
is_trustworthy_on)
) swunpivot
UNION ALL
SELECT name, 'collation_name' AS attribute, collation_name AS value
FROM master.sys.databases
WHERE name IN (SELECT name FROM @dbs)
UNION ALL
SELECT name, 'compatibility_level' AS attribute, CAST(compatibility_level AS NVARCHAR(100)) AS value
FROM master.sys.databases
WHERE name IN (SELECT name FROM @dbs)
UNION ALL
SELECT name, 'page_verify_option_desc' AS attribute, page_verify_option_desc COLLATE DATABASE_DEFAULT AS value
FROM master.sys.databases
WHERE name IN (SELECT name FROM @dbs)
UNION ALL
SELECT name, 'snapshot_isolation_state' AS attribute, CASE snapshot_isolation_state WHEN 0 THEN N'False' ELSE N'True' END AS value
FROM master.sys.databases
WHERE name IN (SELECT name FROM @dbs)
UNION ALL
SELECT name, 'user_access_desc' AS attribute, user_access_desc AS value
FROM master.sys.databases
WHERE name IN (SELECT name FROM @dbs)
)

SELECT name AS database_name, actual_values.attribute, correct_values.value AS correct_value, actual_values.value AS actual_value
FROM
	correct_values
		INNER JOIN
	actual_values
		ON actual_values.attribute = correct_values.attribute
WHERE actual_values.value <> correct_values.value
	OR (actual_values.value IS NULL AND correct_values.value IS NOT NULL)
	OR (actual_values.value IS NOT NULL AND correct_values.value IS NULL)

UNION ALL

SELECT name, '--------- OK ---------', '--------- OK ---------', '--------- OK ---------'
FROM master.sys.databases d
WHERE name IN (SELECT name FROM @dbs)
	AND NOT EXISTS (
SELECT 1
FROM
	correct_values
		INNER JOIN
	actual_values
		ON actual_values.attribute = correct_values.attribute
WHERE (actual_values.value <> correct_values.value
	OR (actual_values.value IS NULL AND correct_values.value IS NOT NULL)
	OR (actual_values.value IS NOT NULL AND correct_values.value IS NULL))
	AND name = d.name
)

ORDER BY name, actual_values.attribute;






-- ORPHANED USERS AND ROLES

IF OBJECT_ID(N'tempdb..##orphaned_users', N'U') IS NOT NULL
	DROP TABLE ##orphaned_users;
CREATE TABLE ##orphaned_users (database_name SYSNAME NULL, UserName SYSNAME, UserSID VARBINARY(85));

DECLARE @dbName SYSNAME
DECLARE curDBs CURSOR FOR
SELECT name
FROM @dbs
ORDER BY name
OPEN curDBs
FETCH NEXT FROM curDBs INTO @dbName
WHILE (@@FETCH_STATUS = 0)
BEGIN
EXEC (N'
USE [' + @dbName + '];
INSERT ##orphaned_users (UserName, UserSID)
EXEC sp_change_users_login @Action=''Report'';
UPDATE ##orphaned_users SET database_name = DB_NAME() WHERE database_name IS NULL;
'
)
FETCH NEXT FROM curDBs INTO @dbName
END
CLOSE curDBs
DEALLOCATE curDBs

SELECT database_name, UserName AS orphaned_user
FROM ##orphaned_users
ORDER BY database_name, orphaned_user

IF OBJECT_ID(N'tempdb..##orphaned_roles', N'U') IS NOT NULL
	DROP TABLE ##orphaned_roles;
CREATE TABLE ##orphaned_roles (database_name SYSNAME NULL, DBRole SYSNAME);

DECLARE curDBs CURSOR FOR
SELECT name
FROM @dbs
ORDER BY name
OPEN curDBs
FETCH NEXT FROM curDBs INTO @dbName
WHILE (@@FETCH_STATUS = 0)
BEGIN
EXEC (N'
USE [' + @dbName + '];
INSERT ##orphaned_roles (DBRole)
SELECT    sysusers.name AS DBRole
  FROM      sysusers
            LEFT JOIN sysmembers ON sysusers.uid = sysmembers.groupuid
  WHERE     sysmembers.groupuid IS NULL
            AND sysusers.issqlrole = 1
            AND sysusers.uid > 0
            AND LEFT(sysusers.name, 3) <> ''db_''
UPDATE ##orphaned_roles SET database_name = DB_NAME() WHERE database_name IS NULL;
')
FETCH NEXT FROM curDBs INTO @dbName
END
CLOSE curDBs
DEALLOCATE curDBs

SELECT database_name, DBRole AS orphaned_role
FROM ##orphaned_roles
ORDER BY database_name, orphaned_role





-- RECOVERY MODELS

SELECT name AS database_name, recovery_model_desc
FROM master.sys.databases
WHERE name IN (SELECT name FROM @dbs)
ORDER BY name





-- DDL AUDITING

IF OBJECT_ID(N'tempdb..##ddl_check', N'U') IS NOT NULL
	DROP TABLE ##ddl_check;
CREATE TABLE ##ddl_check (database_name SYSNAME NULL, ddl_audit_table_exists BIT NOT NULL, ddl_audit_job_step_exists BIT NOT NULL);

DECLARE curDBs CURSOR FOR
SELECT name
FROM @dbs
ORDER BY name
OPEN curDBs
FETCH NEXT FROM curDBs INTO @dbName
WHILE (@@FETCH_STATUS = 0)
BEGIN
EXEC (N'
DECLARE @table_exists BIT;
SET @table_exists = 0;
IF (OBJECT_ID(N''[' + @dbName + '].[Audit].[DDLEvents]'', N''U'') IS NOT NULL)
	SET @table_exists = 1;
DECLARE @job_step_exists BIT;
SET @job_step_exists = 0;
IF EXISTS(SELECT 1 FROM msdb.dbo.sysjobsteps
WHERE job_id = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name LIKE N''%DDLEvents%'')
AND CHARINDEX(N''' + @dbName + ''', step_name, 1) > 0)
	SET @job_step_exists = 1;
INSERT ##ddl_check (database_name, ddl_audit_table_exists, ddl_audit_job_step_exists)
VALUES (N''' + @dbName + ''', @table_exists, @job_step_exists)
')
FETCH NEXT FROM curDBs INTO @dbName
END
CLOSE curDBs
DEALLOCATE curDBs

SELECT database_name,
CASE ddl_audit_table_exists WHEN 0 THEN 'No' ELSE 'Yes' END AS ddl_audit_table_exists,
CASE ddl_audit_job_step_exists WHEN 0 THEN 'No' ELSE 'Yes' END AS ddl_audit_job_step_exists
FROM ##ddl_check
ORDER BY database_name
