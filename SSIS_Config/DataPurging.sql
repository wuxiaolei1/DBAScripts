IF OBJECT_ID(N'[dbo].[DataPurging]', N'P') IS NOT NULL
	DROP PROCEDURE [dbo].[DataPurging];
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*******************************************************************
* PURPOSE: SSIS configuration data purging
* NOTES: Inputs:
*        @MonthsToKeep (default = 12)
*        @DropForeignKeys (default = 0)
* AUTHOR: Andy Sargeant
* CREATED DATE: 15/03/15
* MODIFIED DETAILS
* DATE            AUTHOR                  CHGREF/DESCRIPTION
*-------------------------------------------------------------------
* 15/03/15        AS                      First build
*******************************************************************/
CREATE PROCEDURE [dbo].[DataPurging]
	@MonthsToKeep TINYINT = 12,
	@DropForeignKeys BIT = 0
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN TRY

		BEGIN TRANSACTION DataPurging

		-- 1. Drop the foreign keys:-

		-- FK_PackageErrorLog_PackageLog
		-- FK_PackageTaskLog_PackageLog
		-- FK_PackageVariableLog_PackageLog
		-- FK_PackageLog_BatchLog
		-- FK_PackageLog_PackageVersion
		-- FK_PackageVersion_Package

		IF @DropForeignKeys = 1 BEGIN

			IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PackageErrorLog_PackageLog]') AND parent_object_id = OBJECT_ID(N'[dbo].[PackageErrorLog]'))
				ALTER TABLE [dbo].[PackageErrorLog] DROP CONSTRAINT [FK_PackageErrorLog_PackageLog];

			IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PackageTaskLog_PackageLog]') AND parent_object_id = OBJECT_ID(N'[dbo].[PackageTaskLog]'))
				ALTER TABLE [dbo].[PackageTaskLog] DROP CONSTRAINT [FK_PackageTaskLog_PackageLog];

			IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PackageVariableLog_PackageLog]') AND parent_object_id = OBJECT_ID(N'[dbo].[PackageVariableLog]'))
				ALTER TABLE [dbo].[PackageVariableLog] DROP CONSTRAINT [FK_PackageVariableLog_PackageLog];

			IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PackageLog_BatchLog]') AND parent_object_id = OBJECT_ID(N'[dbo].[PackageLog]'))
				ALTER TABLE [dbo].[PackageLog] DROP CONSTRAINT [FK_PackageLog_BatchLog];

			IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PackageLog_PackageVersion]') AND parent_object_id = OBJECT_ID(N'[dbo].[PackageLog]'))
				ALTER TABLE [dbo].[PackageLog] DROP CONSTRAINT [FK_PackageLog_PackageVersion];

			IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PackageVersion_Package]') AND parent_object_id = OBJECT_ID(N'[dbo].[PackageVersion]'))
				ALTER TABLE [dbo].[PackageVersion] DROP CONSTRAINT [FK_PackageVersion_Package];

		END

		-- 2. Purge data from the following tables:-

		-- dbo.PackageErrorLog
		-- dbo.PackageTaskLog
		-- dbo.PackageVariableLog
		-- dbo.PackageLog
		-- dbo.PackageVersion
		-- dbo.BatchLog

		DECLARE @PurgeDateTime DATETIME;
		SET @PurgeDateTime = DATEADD(MONTH, -@MonthsToKeep, CURRENT_TIMESTAMP);

		IF OBJECT_ID(N'tempdb..#BatchLogIDs', N'U') IS NOT NULL
			DROP TABLE #BatchLogIDs;
		SELECT BatchLogID
		INTO #BatchLogIDs
		FROM dbo.BatchLog
		WHERE StartDateTime < @PurgeDateTime;

		IF OBJECT_ID(N'tempdb..#PackageLogIDs', N'U') IS NOT NULL
			DROP TABLE #PackageLogIDs;
		SELECT PackageLogID
		INTO #PackageLogIDs
		FROM dbo.PackageLog
		INNER JOIN #BatchLogIDs
		ON dbo.PackageLog.BatchLogID = #BatchLogIDs.BatchLogID;

		DELETE FROM dbo.PackageErrorLog
		FROM dbo.PackageErrorLog
		INNER JOIN #PackageLogIDs
		ON dbo.PackageErrorLog.PackageLogID = #PackageLogIDs.PackageLogID;

		DELETE FROM dbo.PackageTaskLog
		FROM dbo.PackageTaskLog
		INNER JOIN #PackageLogIDs
		ON dbo.PackageTaskLog.PackageLogID = #PackageLogIDs.PackageLogID;

		DELETE FROM dbo.PackageVariableLog
		FROM dbo.PackageVariableLog
		INNER JOIN #PackageLogIDs
		ON dbo.PackageVariableLog.PackageLogID = #PackageLogIDs.PackageLogID;

		DELETE FROM dbo.PackageLog
		FROM dbo.PackageLog
		INNER JOIN #PackageLogIDs
		ON dbo.PackageLog.PackageLogID = #PackageLogIDs.PackageLogID;

		DELETE FROM dbo.PackageVersion
		FROM dbo.PackageVersion
		INNER JOIN dbo.PackageLog
		ON dbo.PackageVersion.PackageVersionID = dbo.PackageLog.PackageVersionID
		INNER JOIN #PackageLogIDs
		ON dbo.PackageLog.PackageLogID = #PackageLogIDs.PackageLogID;

		DELETE FROM dbo.BatchLog
		FROM dbo.BatchLog
		INNER JOIN #BatchLogIDs
		ON dbo.BatchLog.BatchLogID = #BatchLogIDs.BatchLogID;

		-- 3. Recreate the foreign keys

		IF @DropForeignKeys = 1 BEGIN

			ALTER TABLE [dbo].[PackageErrorLog] WITH CHECK ADD CONSTRAINT [FK_PackageErrorLog_PackageLog] FOREIGN KEY([PackageLogID])
			REFERENCES [dbo].[PackageLog] ([PackageLogID]);

			ALTER TABLE [dbo].[PackageErrorLog] CHECK CONSTRAINT [FK_PackageErrorLog_PackageLog];

			ALTER TABLE [dbo].[PackageTaskLog] WITH CHECK ADD CONSTRAINT [FK_PackageTaskLog_PackageLog] FOREIGN KEY([PackageLogID])
			REFERENCES [dbo].[PackageLog] ([PackageLogID]);

			ALTER TABLE [dbo].[PackageTaskLog] CHECK CONSTRAINT [FK_PackageTaskLog_PackageLog];

			ALTER TABLE [dbo].[PackageVariableLog] WITH CHECK ADD CONSTRAINT [FK_PackageVariableLog_PackageLog] FOREIGN KEY([PackageLogID])
			REFERENCES [dbo].[PackageLog] ([PackageLogID]);

			ALTER TABLE [dbo].[PackageVariableLog] CHECK CONSTRAINT [FK_PackageVariableLog_PackageLog];

			ALTER TABLE [dbo].[PackageLog] WITH CHECK ADD CONSTRAINT [FK_PackageLog_BatchLog] FOREIGN KEY([BatchLogID])
			REFERENCES [dbo].[BatchLog] ([BatchLogID]);

			ALTER TABLE [dbo].[PackageLog] CHECK CONSTRAINT [FK_PackageLog_BatchLog];

			ALTER TABLE [dbo].[PackageLog] WITH CHECK ADD CONSTRAINT [FK_PackageLog_PackageVersion] FOREIGN KEY([PackageVersionID])
			REFERENCES [dbo].[PackageVersion] ([PackageVersionID]);

			ALTER TABLE [dbo].[PackageLog] CHECK CONSTRAINT [FK_PackageLog_PackageVersion];

			ALTER TABLE [dbo].[PackageVersion] WITH CHECK ADD CONSTRAINT [FK_PackageVersion_Package] FOREIGN KEY([PackageID])
			REFERENCES [dbo].[Package] ([PackageID]);

			ALTER TABLE [dbo].[PackageVersion] CHECK CONSTRAINT [FK_PackageVersion_Package];

		END

		COMMIT TRANSACTION DataPurging

		PRINT N'Data purging completed successfully.';

	END TRY

	BEGIN CATCH

		ROLLBACK TRANSACTION DataPurging

		PRINT N'Data purging failed.';
		PRINT ERROR_MESSAGE();

	END CATCH

END
GO
