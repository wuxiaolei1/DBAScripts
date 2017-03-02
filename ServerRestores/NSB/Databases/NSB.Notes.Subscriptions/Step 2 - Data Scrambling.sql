:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON

SET QUOTED_IDENTIFIER ON
go 

PRINT 'Step 2 - Scramble Data - [NSB.Notes.Subscriptions]'

USE [NSB.Notes.Subscriptions]
GO

TRUNCATE TABLE [dbo].[Subscription];
go 


