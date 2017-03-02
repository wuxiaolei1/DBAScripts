SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Jef M
-- Create date: 20-Sept-2011
-- Description:	Collects Index usage statistics
-- =============================================

USE SystemsHelpDesk
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[IndexUsageStatCollector]')
                  AND TYPE IN (N'P',N'PC'))
  DROP PROCEDURE [dbo].[IndexUsageStatCollector]
GO

CREATE PROCEDURE IndexUsageStatCollector 
	-- Add the parameters for the stored procedure here
	--@DBID int = 0 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--	SELECT @DBID

    DECLARE	@dbName SYSNAME
    DECLARE @SQL NVARCHAR(2000)
	DECLARE	@RunTime AS DATETIME
	DECLARE @DBID INT
	DECLARE @last_service_start_date datetime
	DECLARE @last_data_persist_date datetime
	SET @RunTime = CURRENT_TIMESTAMP
	--TEMP TABLE TO HOLD RESULTS OF DYNAMIC SQL...
	DECLARE @IUS TABLE(
						DbID		INT, 
						TblID		INT, 
						IdxID		INT, 
						DbName		NVARCHAR(255), 
						TblName		NVARCHAR(255), 
						IdxName		NVARCHAR(255), 
						ServiceStartTime	DATETIME, 
						StatTime	DATETIME, 
						UserSeeks	BIGINT, 
						UserScans	BIGINT, 
						UserLookUps	BIGINT, 
						UserUpdates	BIGINT
						)

	--Determine last service restart date based upon tempdb creation date
	SELECT @last_service_start_date = SD.[create_date] 
		FROM sys.databases SD 
		WHERE SD.[name] = 'tempdb'


    DECLARE curAllDBs CURSOR  FOR
		SELECT name
		FROM MASTER.dbo.sysdatabases
		WHERE name NOT IN ('master','tempdb','model','msdb','SystemsHelpDesk')
		ORDER BY name

    OPEN curAllDBs
--    FETCH curAllDBs
--    INTO @dbName
	FETCH NEXT FROM curAllDBs INTO @dbName
    WHILE (@@FETCH_STATUS = 0) -- Loop through all db-s
	BEGIN
		--One line is recorded for each Database after each Server Restart

		--DB_NAME(S.[database_id])
		-- Build SQL statement
		SET @DBID = DB_ID(@dbName)

		--CREATE THE DYNAMIC SQL FOR EACH DATABASE...
		SET @SQL = 'SELECT S.[database_id], S.[OBJECT_ID], S.INDEX_ID, DB_NAME(S.[database_id]), O.name,' + char(13)
					 + 'I.[NAME], CURRENT_TIMESTAMP, USER_SEEKS, USER_SCANS, USER_LOOKUPS, USER_UPDATES ' + char(13)
			 + 'FROM ' + QuoteName(@dbName) + '.sys.dm_db_index_usage_stats S' + char(13)
					 + 'INNER JOIN ' + QuoteName(@dbName) + '.sys.indexes I' + char(13)
						 + 'ON I.[OBJECT_ID] = S.[OBJECT_ID]' + char(13)
						 + 'AND I.INDEX_ID = S.INDEX_ID' + char(13)
					 + 'INNER JOIN ' + QuoteName(@dbName) + '.sys.objects O' + char(13)
						 + 'ON O.[OBJECT_ID] = S.[OBJECT_ID]' + char(13)
						 + 'AND O.type = ''U''' + char(13)
			 + 'WHERE S.database_id = DB_ID(''' + @dbName + ''')'

		--INSERT DYNAMIC SQL INTO TEMPORARY TABLE
		DELETE FROM @IUS;

		INSERT INTO @IUS 
		(DbID, TblID, IdxID, DbName, TblName, IdxName, StatTime, UserSeeks, UserScans, UserLookUps, UserUpdates)
		EXEC (@SQL)

		UPDATE @IUS SET ServiceStartTime = @last_service_start_date

		PRINT @SQL -- Use it for debugging

		--Return the value for the last refresh date of the persisting table
		SELECT @last_data_persist_date = MAX(IUS.[StatTime]) 
			FROM [SystemsHelpDesk].[dbo].[IndexUsageStats] IUS
			WHERE IUS.DBName = @dbName

		--Take care of updated records first
		IF @last_service_start_date < @last_data_persist_date
			BEGIN
				--Service NOT restarted since last poll date
				--Therefore update row with latest counter set
				PRINT 'The latest persist date was ' + 
					CAST(@last_data_persist_date AS VARCHAR(50)) + 
					'; no restarts occurred since ' + 
					CAST(@last_service_start_date AS VARCHAR(50)) +
					'  (' + CAST(DATEDIFF(d, @last_service_start_date, @last_data_persist_date) AS VARCHAR(10)) + 
					' days ago.)'

				--UPDATE ANY EXISTING RECORDS...
				UPDATE IUS
				SET
					IUS.ServiceStartTime = IUS2.ServiceStartTime,
					IUS.StatTime = IUS2.StatTime,
					IUS.DbName = IUS2.DbName,
					IUS.TblName = IUS2.TblName,
					IUS.IdxName = IUS2.IdxName,
					IUS.UserSeeks = IUS2.UserSeeks,
					IUS.UserScans = IUS2.UserScans,
					IUS.UserLookUps = IUS2.UserLookUps,
					IUS.UserUpdates = IUS2.UserUpdates
				FROM (IndexUsageStats IUS INNER JOIN @IUS IUS2
				ON IUS2.DbID = IUS.DbID
				AND IUS2.TblID = IUS.TblID
				AND IUS2.IdxID = IUS.IdxID
				AND IUS.StatTime = @last_data_persist_date)
--				ONLY UPDATE FOR LATEST STATS... 

				--INSERT ANY NEW RECORDS (New Indexes)
				INSERT INTO IndexUsageStats
				(DbID, TblID, IdxID, DBName, TblName, IdxName, ServiceStartTime, StatTime, UserSeeks, UserScans, UserLookUps, UserUpdates)
				SELECT IUS.DbID, IUS.TblID, IUS.IdxID, IUS.DBName, IUS.TblName, IUS.IdxName, IUS.ServiceStartTime, IUS.StatTime, IUS.UserSeeks, IUS.UserScans, IUS.UserLookUps, IUS.UserUpdates 
				FROM (@IUS IUS LEFT JOIN IndexUsageStats IUS2
				ON IUS.DbID = IUS2.DbID
				AND IUS.TblID = IUS2.TblID
				AND IUS.IdxID = IUS2.IdxID)
				WHERE (IUS2.TblID IS NULL AND IUS2.IdxID IS NULL)

			END
			ELSE
			BEGIN
				--Service restarted since last poll date
				--Therefore start a new row...
				PRINT 'Lastest service restart occurred on ' + 
					CAST(@last_service_start_date AS VARCHAR(50)) + 
					' which is after the latest persist date of ' + 
					CAST(@last_data_persist_date AS VARCHAR(50))

				INSERT INTO IndexUsageStats 
				(DbID, TblID, IdxID, DBName, TblName, IdxName, ServiceStartTime, StatTime, UserSeeks, UserScans, UserLookUps, UserUpdates)
				SELECT DbID, TblID, IdxID, DBName, TblName, IdxName, ServiceStartTime, StatTime, UserSeeks, UserScans, UserLookUps, UserUpdates FROM @IUS

			END

		--FETCH curAllDBs INTO @dbName
		FETCH NEXT FROM curAllDBs INTO @dbName
	END -- while
	CLOSE curAllDBs
	DEALLOCATE curAllDBs

	-- Return results (success or not)

END

GO

