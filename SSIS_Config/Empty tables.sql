USE [SSIS_Config]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PackageErrorLog_PackageLog]') AND parent_object_id = OBJECT_ID(N'[dbo].[PackageErrorLog]'))
ALTER TABLE [dbo].[PackageErrorLog] DROP CONSTRAINT [FK_PackageErrorLog_PackageLog]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PackageLog_BatchLog]') AND parent_object_id = OBJECT_ID(N'[dbo].[PackageLog]'))
ALTER TABLE [dbo].[PackageLog] DROP CONSTRAINT [FK_PackageLog_BatchLog]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PackageLog_PackageVersion]') AND parent_object_id = OBJECT_ID(N'[dbo].[PackageLog]'))
ALTER TABLE [dbo].[PackageLog] DROP CONSTRAINT [FK_PackageLog_PackageVersion]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PackageTaskLog_PackageLog]') AND parent_object_id = OBJECT_ID(N'[dbo].[PackageTaskLog]'))
ALTER TABLE [dbo].[PackageTaskLog] DROP CONSTRAINT [FK_PackageTaskLog_PackageLog]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PackageVariableLog_PackageLog]') AND parent_object_id = OBJECT_ID(N'[dbo].[PackageVariableLog]'))
ALTER TABLE [dbo].[PackageVariableLog] DROP CONSTRAINT [FK_PackageVariableLog_PackageLog]
GO



TRUNCATE TABLE dbo.BatchLog
GO
TRUNCATE TABLE dbo.PackageErrorLog
GO
TRUNCATE TABLE dbo.PackageLog
GO
TRUNCATE TABLE dbo.PackageTaskLog
GO
TRUNCATE TABLE dbo.PackageVariableLog
GO
TRUNCATE TABLE dbo.PackageVersion
GO



ALTER TABLE [dbo].[PackageErrorLog]  WITH CHECK ADD  CONSTRAINT [FK_PackageErrorLog_PackageLog] FOREIGN KEY([PackageLogID])
REFERENCES [dbo].[PackageLog] ([PackageLogID])
GO

ALTER TABLE [dbo].[PackageErrorLog] CHECK CONSTRAINT [FK_PackageErrorLog_PackageLog]
GO

ALTER TABLE [dbo].[PackageLog]  WITH CHECK ADD  CONSTRAINT [FK_PackageLog_BatchLog] FOREIGN KEY([BatchLogID])
REFERENCES [dbo].[BatchLog] ([BatchLogID])
GO

ALTER TABLE [dbo].[PackageLog] CHECK CONSTRAINT [FK_PackageLog_BatchLog]
GO

ALTER TABLE [dbo].[PackageLog]  WITH CHECK ADD  CONSTRAINT [FK_PackageLog_PackageVersion] FOREIGN KEY([PackageVersionID])
REFERENCES [dbo].[PackageVersion] ([PackageVersionID])
GO

ALTER TABLE [dbo].[PackageLog] CHECK CONSTRAINT [FK_PackageLog_PackageVersion]
GO

ALTER TABLE [dbo].[PackageTaskLog]  WITH CHECK ADD  CONSTRAINT [FK_PackageTaskLog_PackageLog] FOREIGN KEY([PackageLogID])
REFERENCES [dbo].[PackageLog] ([PackageLogID])
GO

ALTER TABLE [dbo].[PackageTaskLog] CHECK CONSTRAINT [FK_PackageTaskLog_PackageLog]
GO

ALTER TABLE [dbo].[PackageVariableLog]  WITH CHECK ADD  CONSTRAINT [FK_PackageVariableLog_PackageLog] FOREIGN KEY([PackageLogID])
REFERENCES [dbo].[PackageLog] ([PackageLogID])
GO

ALTER TABLE [dbo].[PackageVariableLog] CHECK CONSTRAINT [FK_PackageVariableLog_PackageLog]
GO




IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_PackageVersion_Package]') AND parent_object_id = OBJECT_ID(N'[dbo].[PackageVersion]'))
ALTER TABLE [dbo].[PackageVersion] DROP CONSTRAINT [FK_PackageVersion_Package]
GO

TRUNCATE TABLE dbo.Package
GO

ALTER TABLE [dbo].[PackageVersion]  WITH CHECK ADD  CONSTRAINT [FK_PackageVersion_Package] FOREIGN KEY([PackageID])
REFERENCES [dbo].[Package] ([PackageID])
GO

ALTER TABLE [dbo].[PackageVersion] CHECK CONSTRAINT [FK_PackageVersion_Package]
GO

