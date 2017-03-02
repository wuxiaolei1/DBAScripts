:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
PRINT 'Step 2 - Scramble Data - CWS'

USE CWS
GO

DECLARE @ClientEmail VARCHAR(255)
		, @HomeTelNo VARCHAR(16)
		, @WorkTelNo VARCHAR(16)
		, @MobTelNo VARCHAR(16)
		, @DataScramble BIT
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
SET @AddressLine1 = 'StepChange - Systems Department'
SET @AddressLine2 = 'Wade House'
SET @AddressLine3 = 'Merrion Centre'
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
		, @AddressLine1 = EDV.HouseNameOrNumber
		, @AddressLine2 = EDV.AddressLine2
		, @AddressLine3 = EDV.PostTown
		, @AddressLine4 = EDV.Region
		, @PostCode = EDV.PostCode
		, @DataScrambleName = EDV.DataScrambleName
		, @DataScrambleAddress = EDV.DataScrambleAddress

FROM EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE Environment = @Environment

SET @DataRowCount = @@Rowcount

--Perform Updates
IF @DataScramble = 1
BEGIN

-- Scramble Client Names if required
	IF  @DataScrambleName = 1
	BEGIN
		BEGIN TRAN UpdateNames

		--TABLE: dbo.DirectDebits
		UPDATE [dbo].[DirectDebits]
		SET AccountName = UPPER(tempdb.dbo.[FN_ScrambleName](AccountName,1))
		WHERE ISNULL(AccountName, '') <> ''

		--TABLE: dbo.Clients
		UPDATE dbo.Clients SET
		FullNames = CASE 
						WHEN FullNames IS NOT NULL AND FullNames <> '' AND FullNames LIKE '% and %' 
							-- TB: breaks down joint client names to ensure both surnames are scrambled
							-- Will pass everything to the left of " and " as the first name to scramble, 
							-- followed by everything to the right. Then the name will be re-constructed
							THEN tempdb.dbo.[FN_ScrambleName](LEFT(Fullnames, CHARINDEX(' and ',fullNames)-1),1) + ' and ' + tempdb.dbo.[FN_ScrambleName](SUBSTRING(FullNames,CHARINDEX(' and ',fullNames) + 5,LEN(FullNames)),1) 
						 WHEN FullNames IS NOT NULL AND FullNames <> '' 
							THEN tempdb.dbo.[FN_ScrambleName](FullNames,1)
					END

		COMMIT TRAN UpdateNames
	END

-- Scramble Client Address if required
	IF  @DataScrambleAddress = 1
	BEGIN
		--TABLE: dbo.AccountTransferRequests
		UPDATE dbo.AccountTransferRequests SET
		AddressLine1 = CASE WHEN AddressLine1 IS NOT NULL OR AddressLine1 <> '' THEN @AddressLine1 END,
		AddressLine2 = CASE WHEN AddressLine2 IS NOT NULL OR AddressLine2 <> '' THEN @AddressLine2 END,
		AddressLine3 = CASE WHEN AddressLine3 IS NOT NULL OR AddressLine3 <> '' THEN @AddressLine3 END,
		AddressLine4 = CASE WHEN AddressLine4 IS NOT NULL OR AddressLine4 <> '' THEN @AddressLine4 END

		--TABLE: dbo.Addresses
		UPDATE dbo.Addresses SET
		AddressLine1 = CASE WHEN AddressLine1 IS NOT NULL OR AddressLine1 <> '' THEN @AddressLine1 END,
		AddressLine2 = CASE WHEN AddressLine2 IS NOT NULL OR AddressLine2 <> '' THEN @AddressLine2 END,
		AddressLine3 = CASE WHEN AddressLine3 IS NOT NULL OR AddressLine3 <> '' THEN @AddressLine3 END,
		AddressLine4 = CASE WHEN AddressLine4 IS NOT NULL OR AddressLine4 <> '' THEN @AddressLine4 END
	END

	--TABLE: dbo.Clients
	UPDATE dbo.Clients SET
	EmailAddress = CASE WHEN EmailAddress IS NOT NULL OR EmailAddress <> '' THEN @ClientEmail END
	
	--TABLE: dbo.EmailChangeRequests
	UPDATE dbo.EmailChangeRequests SET
	OldEmailAddress = CASE WHEN OldEmailAddress IS NOT NULL OR OldEmailAddress <> '' THEN @ClientEmail END, 
	NewEmailAddress = CASE WHEN NewEmailAddress IS NOT NULL OR NewEmailAddress <> '' THEN @ClientEmail END

	--TABLE: dbo.TelephoneNumberChangeRequests
	UPDATE  dbo.TelephoneNumberChangeRequests
	SET     OldNumber = CASE  
	WHEN PATINDEX('%[^0-9]%',OldNumber)  =1 THEN SUBSTRING(OldNumber,1,(PATINDEX('%[^0-9]%',OldNumber))) + '0'
	+ SUBSTRING((tempdb.dbo.fn_Replace0to8(OldNumber)),(PATINDEX('%[^0-9]%',OldNumber))+2,(LEN(OldNumber)))
	ELSE '0' + SUBSTRING((tempdb.dbo.fn_Replace0to8(OldNumber)),2,LEN(OldNumber)-1)
	END
	WHERE OldNumber IS NOT NULL AND REPLACE(OldNumber,' ','') <> ''  
	  
	UPDATE  dbo.TelephoneNumberChangeRequests
	SET     NewNumber = CASE  
	WHEN PATINDEX('%[^0-9]%',NewNumber)  =1 THEN SUBSTRING(NewNumber,1,(PATINDEX('%[^0-9]%',NewNumber))) + '0'
	+ SUBSTRING((tempdb.dbo.fn_Replace0to8(NewNumber)),(PATINDEX('%[^0-9]%',NewNumber))+2,(LEN(NewNumber)))
	ELSE '0' + SUBSTRING((tempdb.dbo.fn_Replace0to8(NewNumber)),2,LEN(NewNumber)-1)
	END
	WHERE NewNumber IS NOT NULL AND REPLACE(NewNumber,' ','') <> ''  
	
	--TABLE: dbo.TelephoneNumbers
	UPDATE  dbo.TelephoneNumbers
	SET     Number = CASE  
	WHEN PATINDEX('%[^0-9]%',Number)  =1 THEN SUBSTRING(Number,1,(PATINDEX('%[^0-9]%',Number))) + '0'
	+ SUBSTRING((tempdb.dbo.fn_Replace0to8(Number)),(PATINDEX('%[^0-9]%',Number))+2,(LEN(Number)))
	ELSE '0' + SUBSTRING((tempdb.dbo.fn_Replace0to8(Number)),2,LEN(Number)-1)
	END
	WHERE Number IS NOT NULL AND REPLACE(Number,' ','') <> ''  
	
	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)

END