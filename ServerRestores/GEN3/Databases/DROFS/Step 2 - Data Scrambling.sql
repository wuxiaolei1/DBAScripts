:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET ANSI_WARNINGS ON
GO
PRINT 'Step 2 - Scramble Data - DROFS'

USE DROFS
GO

DECLARE @InternalEmail VARCHAR(100)
DECLARE @ClientEmail VARCHAR(100)
DECLARE @ClientTelNo VARCHAR(255)
DECLARE @DataScramble BIT
DECLARE @Environment VARCHAR(50)
DECLARE @HouseNameOrNumber VARCHAR(60)
DECLARE @AddressLine1 VARCHAR(60)
DECLARE @AddressLine2 VARCHAR(60)
DECLARE @AddressLine3 VARCHAR(60)
DECLARE @AddressLine4 VARCHAR(60)
DECLARE @PostCode VARCHAR(60)
DECLARE @DataRowCount INT
DECLARE @DataScrambleName INT -- 1 = Yes Scramble Name
DECLARE @DataScrambleAddress INT -- 1 = Yes Scramble Address

--SET DEFAULTS...
SET @InternalEmail = 'thisisadummyemail@notstepchange.co.na' --'no-reply@stepchange.org'
SET @ClientEmail = 'thisisadummyemail@notstepchange.co.na' --'no-reply@stepchange.org'
SET @ClientTelNo = '09999999999'
SET @DataScramble = 1
SET @Environment = $(Environment)
SET @HouseNameOrNumber = 'StepChange - Systems Department'
SET @AddressLine1 = 'Wade House'
SET @AddressLine2 = 'Merrion Centre'
SET @AddressLine3 = 'Leeds'
SET @AddressLine4 = 'Yorkshire'
SET @PostCode = 'LS2 8NG'
SET @DataRowCount = 0
SET @DataScrambleName = 1
SET @DataScrambleAddress = 1

--Read the specific settings if available...
SELECT	@InternalEmail = EDV.Email
		, @ClientEmail = EDV.ClientEmail
		, @ClientTelNo = EDV.TelNo
		, @DataScramble = EDV.DataScramble
		, @HouseNameOrNumber = EDV.HouseNameOrNumber
		, @AddressLine1 = EDV.AddressLine1
		, @AddressLine2 = EDV.AddressLine2
		, @AddressLine3 = EDV.PostTown
		, @AddressLine4 = EDV.Region
		, @PostCode = EDV.PostCode
		, @DataScrambleName = EDV.DataScrambleName
		, @DataScrambleAddress = EDV.DataScrambleAddress

FROM EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE Environment = @Environment

SET @DataRowCount = @@Rowcount

-- Perform Updates
IF @DataScramble = 1
BEGIN
-- Scramble Client Names if required
	IF  @DataScrambleName = 1
	BEGIN
		BEGIN TRAN UpdateNames

			UPDATE dbo.Clients 
			SET LastName =  [tempdb].[dbo].[FN_ScrambleName](LastName,0)
			WHERE ISNULL(LastName,'') <> ''

			--TABLE: dbo.ManualImport
			UPDATE dbo.ManualImport 
			SET LastName =  [tempdb].[dbo].[FN_ScrambleName](LastName,0)
			WHERE ISNULL(LastName,'') <> ''

			UPDATE dbo.ManualImport 
			SET PartnerLastName =  [tempdb].[dbo].[FN_ScrambleName](PartnerLastName,0)
			WHERE ISNULL(PartnerLastName,'') <> ''

			--TABLE: dbo.MigratedDROClients
			UPDATE dbo.MigratedDROClients 
			SET ClientName =  [tempdb].[dbo].[FN_ScrambleName](ClientName,1)
			WHERE ISNULL(ClientName,'') <> ''

			UPDATE dbo.MigratedDROClients 
			SET LastName =  [tempdb].[dbo].[FN_ScrambleName](LastName,0)
			WHERE ISNULL(LastName,'') <> ''

			--TABLE: dbo.NewDROClients
			UPDATE dbo.NewDROClients 
			SET LastName =  [tempdb].[dbo].[FN_ScrambleName](LastName,0)
			WHERE ISNULL(LastName,'') <> ''

			UPDATE dbo.NewDROClients 
			SET PartnerLastName =  [tempdb].[dbo].[FN_ScrambleName](PartnerLastName,0)
			WHERE ISNULL(PartnerLastName,'') <> ''


		COMMIT TRAN UpdateNames
	END

		-- Raise an error if no rows were selected from the Environment Data Values Table
		IF @DataRowCount = 0
		RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)

END
