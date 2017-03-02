:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET ANSI_WARNINGS ON
GO
PRINT 'Step 2 - Scramble Data - WebsiteServices'

USE WebsiteServices
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

		--TABLE: dbo.Clients
		UPDATE dbo.Clients
		SET ClientNames = [tempdb].[dbo].[FN_ScrambleName](ClientNames,1)
		WHERE   ISNULL(ClientNames,'') <> ''

		UPDATE dbo.Users 
		SET FullName =  [tempdb].[dbo].[FN_ScrambleName](FullName,1)
		WHERE ISNULL(FullName,'') <> ''

		COMMIT TRAN UpdateNames
	END

-- Scramble Client Address if required
	IF  @DataScrambleAddress = 1
	BEGIN
		--TABLE: ClientServices.AddressChanges
		UPDATE ClientServices.AddressChanges SET
		HouseNameOrNumber = CASE WHEN HouseNameOrNumber IS NOT NULL OR HouseNameOrNumber <> '' THEN @HouseNameOrNumber END,
		AddressLine1 = CASE WHEN AddressLine1 IS NOT NULL OR AddressLine1 <> '' THEN @AddressLine1 END,
		AddressLine2 = CASE WHEN AddressLine2 IS NOT NULL OR AddressLine2 <> '' THEN @AddressLine2 END,
		AddressLine3 = CASE WHEN AddressLine3 IS NOT NULL OR AddressLine3 <> '' THEN @AddressLine3 END,
		AddressLine4 = CASE WHEN AddressLine4 IS NOT NULL OR AddressLine4 <> '' THEN @AddressLine4 END

		--TABLE: ClientServices.DebtTransfers
		UPDATE ClientServices.DebtTransfers SET
		AddressLine1 = CASE WHEN AddressLine1 IS NOT NULL OR AddressLine1 <> '' THEN @AddressLine1 END,
		AddressLine2 = CASE WHEN AddressLine2 IS NOT NULL OR AddressLine2 <> '' THEN @AddressLine2 END,
		AddressLine3 = CASE WHEN AddressLine3 IS NOT NULL OR AddressLine3 <> '' THEN @AddressLine3 END,
		AddressLine4 = CASE WHEN AddressLine4 IS NOT NULL OR AddressLine4 <> '' THEN @AddressLine4 END

		--TABLE: dbo.CreditorDebtTransfers
		UPDATE dbo.CreditorDebtTransfers SET
		AddressLine1 = CASE WHEN AddressLine1 IS NOT NULL OR AddressLine1 <> '' THEN @AddressLine1 END,
		AddressLine2 = CASE WHEN AddressLine2 IS NOT NULL OR AddressLine2 <> '' THEN @AddressLine2 END,
		AddressLine3 = CASE WHEN AddressLine3 IS NOT NULL OR AddressLine3 <> '' THEN @AddressLine3 END,
		AddressLine4 = CASE WHEN AddressLine4 IS NOT NULL OR AddressLine4 <> '' THEN @AddressLine4 END,
		PostCode = CASE WHEN PostCode IS NOT NULL OR PostCode <> '' THEN @PostCode END
		
		--TABLE: dbo.ClientAddresses
		UPDATE dbo.ClientAddresses SET
		AddressLine1 = CASE WHEN AddressLine1 IS NOT NULL OR AddressLine1 <> '' THEN @AddressLine1 + ' ' + 
		@AddressLine2 + ' ' + @AddressLine3 + ' ' + @AddressLine4 END
	END
		
		--TABLE: ClientServices.EmailChanges
		UPDATE ClientServices.EmailChanges SET
		OldEmailAddress = CASE WHEN OldEmailAddress IS NOT NULL OR OldEmailAddress <> '' THEN @ClientEmail END, 
		NewEmailAddress = CASE WHEN NewEmailAddress IS NOT NULL OR NewEmailAddress <> '' THEN 'NEW' + @ClientEmail END
		
		--TABLE: ClientServices.TelephoneChanges
		UPDATE  ClientServices.TelephoneChanges
		SET     TelephoneNumber = CASE  
		WHEN PATINDEX('%[^0-9]%',TelephoneNumber)  =1 THEN SUBSTRING(TelephoneNumber,1,(PATINDEX('%[^0-9]%',TelephoneNumber))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](TelephoneNumber)),(PATINDEX('%[^0-9]%',TelephoneNumber))+2,(LEN(TelephoneNumber)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](TelephoneNumber)),2,LEN(TelephoneNumber)-1)
		END
		WHERE TelephoneNumber IS NOT NULL AND REPLACE(TelephoneNumber,' ','') <> ''

		--TABLE: dbo.Users 
		UPDATE dbo.Users 
		SET EmailAddress= @InternalEmail
		WHERE ISNULL(EmailAddress,'') <> ''
		OR EmailAddress LIKE '%@stepchange.org'

		UPDATE dbo.Users 
		SET EmailAddress= @ClientEmail
		WHERE ISNULL(EmailAddress,'') <> ''
		OR EmailAddress NOT LIKE '%@stepchange.org'


		-- CREDITORS

		UPDATE CreditorServices.CreditorSLAs SET
		NotificationEmailAddress = CASE WHEN NotificationEmailAddress IS NOT NULL OR NotificationEmailAddress <> '' THEN @InternalEmail END,
		PreviousNotificationEmailAddress = CASE WHEN PreviousNotificationEmailAddress IS NOT NULL OR PreviousNotificationEmailAddress <> '' THEN @InternalEmail END       

		-- Raise an error if no rows were selected from the Environment Data Values Table
		IF @DataRowCount = 0
		RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)

END
