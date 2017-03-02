:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
USE TCS_MI
GO

SET NOCOUNT ON
Print 'Step 2 - Scramble Data - TCS_MI'

Truncate Table dbo.tblMI_TCS_Asset_Extract
Truncate Table dbo.tblMI_TCS_Budget_Extract
Truncate Table dbo.tblMI_TCS_Client_Extract
Truncate Table dbo.tblMI_TCS_Counselling_Extract
Truncate Table dbo.tblMI_TCS_Debt_Extract