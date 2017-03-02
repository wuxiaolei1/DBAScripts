:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON

SET QUOTED_IDENTIFIER ON
go 

PRINT 'Step 2 - Scramble Data - Client'

USE Client
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
			UPDATE [Person].[Persons] SET
			Surname = CASE WHEN Surname IS NOT NULL OR Surname <> '' THEN [tempdb].[dbo].[FN_ScrambleName](Surname,0) END;

			COMMIT TRAN UpdateNames
		END

-- Scramble Client Addresses if required
		IF  @DataScrambleAddress = 1
		BEGIN
			--TABLE: [Address].[Addresses]
			UPDATE [Address].[Addresses] SET
			AddressLine1 = CASE WHEN AddressLine1 IS NOT NULL OR AddressLine1 <> '' THEN @AddressLine1 END,
			AddressLine2 = CASE WHEN AddressLine2 IS NOT NULL OR AddressLine2 <> '' THEN @AddressLine2 END,
			AddressLine3 = CASE WHEN AddressLine3 IS NOT NULL OR AddressLine3 <> '' THEN @AddressLine3 END,
			AddressLine4 = CASE WHEN AddressLine4 IS NOT NULL OR AddressLine4 <> '' THEN @AddressLine4 END;

			-- Recalculate Hash values following update of all addresses.
			UPDATE Address.Addresses
			SET HashAddress = NEWID();
					--HASHBYTES('MD5'
					--,LOWER([Admin].RemoveNonAlphanumChars(
					--	COALESCE(AddressLine1,'') 
					--	+ COALESCE(AddressLine2,'') 
					--	+ COALESCE(AddressLine3,'')
					--	+ COALESCE(AddressLine4,'')
					--	+ COALESCE(Postcode, '')
					--	+ COALESCE(CAST(CountryID AS VARCHAR(5)), ''))));

		END
	
		-- Scramble Emails
		--TABLE: [Person].[Emails]
		UPDATE [Person].[Emails] SET		
		Email = CASE WHEN Email IS NOT NULL AND Email <> '' THEN @ClientEmail END;

		-- Scramble telephone numbers
		-- TABLE: [Person].[TelephoneNumbers]
		UPDATE t
		SET [TelephoneNumber] = 
		CASE  
		WHEN PATINDEX('%[^0-9]%',[TelephoneNumber]) =1 THEN SUBSTRING([TelephoneNumber],1,(PATINDEX('%[^0-9]%',[TelephoneNumber]))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8]([TelephoneNumber])),(PATINDEX('%[^0-9]%',[TelephoneNumber]))+2,(LEN([TelephoneNumber])))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8]([TelephoneNumber])),2,LEN([TelephoneNumber])-1)
		END		 
		from [Person].[TelephoneNumbers] T
		WHERE LEN([TelephoneNumber]) > 0;

		/* seperated out into two update statements due to an issue with the data, resulting in blank telephone numbers */
		UPDATE t
		SET 	[TelephoneNumberNumeric] = 
		CASE  
		WHEN PATINDEX('%[^0-9]%',[TelephoneNumberNumeric]) =1 THEN SUBSTRING([TelephoneNumberNumeric],1,(PATINDEX('%[^0-9]%',[TelephoneNumberNumeric]))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8]([TelephoneNumberNumeric])),(PATINDEX('%[^0-9]%',[TelephoneNumberNumeric]))+2,(LEN([TelephoneNumberNumeric])))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8]([TelephoneNumberNumeric])),2,LEN([TelephoneNumberNumeric])-1)
		END
		from [Person].[TelephoneNumbers] T
		WHERE LEN([TelephoneNumberNumeric]) > 0;

		-- Scrmable third parties
		-- TABLE: [ThirdParty].[ThirdParties]
		UPDATE [ThirdParty].[ThirdParties]
		SET [ThirdParty] = [tempdb].[dbo].[FN_ScrambleName](ThirdParty,0);

	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
	
END
