:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON

SET QUOTED_IDENTIFIER ON
go 

PRINT 'Step 2 - Scramble Data - ClientHistoryAudit'

USE ClientHistoryAudit
GO

DECLARE @ClientEmail VARCHAR(255)
		, @HomeTelNo VARCHAR(16)
		, @WorkTelNo VARCHAR(16)
		, @MobTelNo VARCHAR(16)
		, @DataScramble BIT
		, @HouseNumber INT
		, @HouseName VARCHAR(50)
		, @AddressLine1 VARCHAR(255)
		, @AddressLine2 VARCHAR(255)
		, @AddressLine3 VARCHAR(255)
		, @AddressLine4 VARCHAR(255)
		, @PostCode VARCHAR(10)
		, @Environment VARCHAR(30)
		, @DataRowCount INT
		, @DataScrambleName INT -- 1 = Yes Scramble Name
		, @DataScrambleAddress INT -- 1 = Yes Scramble Address

--SET DEFAULTS...

SET @ClientEmail = 'thisisadummyemail@notstepchange.co.na' --'no-reply@stepchange.org'
SET @HomeTelNo = '09999999999'
SET @WorkTelNo = '09999999999'
SET @MobTelNo = '09999999999'
SET @DataScramble = 1
SET @HouseNumber = ''
SET @HouseName = 'StepChange - Systems Department'
SET @AddressLine1 = 'Wade House'
SET @AddressLine2 = 'Merrion Centre'
SET @AddressLine3 = ''
SET @AddressLine4 = 'Leeds'
SET @PostCode = 'LS2 8NG'
SET @Environment = $(Environment)
SET @DataRowCount = 0
SET @DataScrambleName = 1
SET @DataScrambleAddress = 1

--Read the specific settings if available...
SELECT	@ClientEmail = EDV.ClientEmail
		, @HomeTelNo = EDV.TelNo
		, @WorkTelNo = EDV.TelNo
		, @MobTelNo = EDV.MobileNo
		, @DataScramble = EDV.DataScramble
		, @HouseNumber = EDV.HouseNo
		, @HouseName = EDV.HouseName
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

			--TABLE: [Person].[Persons]
			UPDATE [Person].[Persons]
			SET AuditHistoryXML.modify('replace value of (/Person/@Surname)[1] with "Test"');

			UPDATE [Person].[Persons]
			SET AuditHistoryXML.modify('replace value of (/Person/@ClientFullName)[1] with "Test"');

			COMMIT TRAN UpdateNames
		END

-- Scramble Client Addresses if required
		IF  @DataScrambleAddress = 1
		BEGIN
			--TABLE: [Address].[Addresses]
			UPDATE [Address].[Addresses] 
			SET AuditHistoryXML.modify('replace value of (/Address/@AddressLine1)[1] with "Test line 1"');

			UPDATE [Address].[Addresses] 
			SET AuditHistoryXML.modify('replace value of (/Address/@AddressLine2)[1] with "Test line 2"');

			UPDATE [Address].[Addresses] 
			SET AuditHistoryXML.modify('replace value of (/Address/@AddressLine3)[1] with "Test line 3"');

			UPDATE [Address].[Addresses] 
			SET AuditHistoryXML.modify('replace value of (/Address/@AddressLine4)[1] with "Test line 4"');
			
			UPDATE [Address].[Addresses] 
			SET AuditHistoryXML.modify('replace value of (/Address/@Address)[1] with "Test Address"');
		END
	
		-- Scramble Emails
		--TABLE: [Person].[Emails]
		UPDATE [Person].[Emails] 	
		SET AuditHistoryXML.modify('replace value of (/Email/@Email)[1] with "Test@stepchange.org"');

		UPDATE [Person].[Emails] 	
		SET AuditHistoryXML.modify('replace value of (/Email/@EmailAddress)[1] with "Test@stepchange.org"');

		-- Scramble telephone numbers
		-- TABLE: [Person].[TelephoneNumbers]
		UPDATE [Person].[TelephoneNumbers] 
		SET AuditHistoryXML.modify('replace value of (/TelephoneNumber/@Number)[1] with "09999999999"');

		UPDATE [Person].[TelephoneNumbers] 
		SET AuditHistoryXML.modify('replace value of (/TelephoneNumber/@TelephoneNumberNumeric)[1] with "09999999999"');

		-- Scrmable third parties
		-- TABLE: [ThirdParty].[ThirdParties]
		UPDATE [ThirdParty].[ThirdParties]
		SET AuditHistoryXML.modify('replace value of (/ThirdParty/@ThirdParty)[1] with "Test"');

	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
	
END
