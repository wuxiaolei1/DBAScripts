:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON

SET QUOTED_IDENTIFIER ON
go 

PRINT 'Step 2 - Scramble Data - [NSB.Client.Subscriptions]'

USE [NSB.Client.Subscriptions]
GO

TRUNCATE TABLE [dbo].[Subscription];
GO 