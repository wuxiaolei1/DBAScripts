:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON

SET QUOTED_IDENTIFIER ON
go 

PRINT 'Step 2 - Scramble Data - [NSB.DCS.Sagas]'

USE [NSB.DCS.Sagas]
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
		, @InsertLocation VARCHAR(200)
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
SET @InsertLocation = '\\VMTESTERSAPP01\TCSPDFTemplates\selfhelppack.pdf'
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
/* Commented out as the details have been removed 
-- Scramble Client Names if required
		IF  @DataScrambleName = 1
		BEGIN
			BEGIN TRAN UpdateNames

			UPDATE [dbo].[PersonAddressDetailsCorrelation] SET
			Surname = CASE WHEN Surname IS NOT NULL OR Surname <> '' THEN [tempdb].[dbo].[FN_ScrambleName](Surname,0) END;

			COMMIT TRAN UpdateNames
ENDND

-- Scramble Client Addresses if required
		IF  @DataScrambleAddress = 1
		BEGIN
			UPDATE [dbo].[PersonAddressDetailsCorrelation] SET
			AddressLine1 = CASE WHEN AddressLine1 IS NOT NULL OR AddressLine1 <> '' THEN @AddressLine1 END,
			AddressLine2 = CASE WHEN AddressLine2 IS NOT NULL OR AddressLine2 <> '' THEN @AddressLine2 END,
			AddressLine3 = CASE WHEN AddressLine3 IS NOT NULL OR AddressLine3 <> '' THEN @AddressLine3 END,
			AddressLine4 = CASE WHEN AddressLine4 IS NOT NULL OR AddressLine4 <> '' THEN @AddressLine4 END
		END;
*/	
		--Contact details
		UPDATE [dbo].[ContactDetailsCorrelation]
		SET [ContactDetail] = 
			CASE	
				WHEN [ContactDetail] LIKE '%@%' THEN @ClientEmail
				WHEN PATINDEX('%[^0-9]%',ContactDetail) =1 THEN SUBSTRING(ContactDetail,1,(PATINDEX('%[^0-9]%',ContactDetail))) + '0'
					+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](ContactDetail)),(PATINDEX('%[^0-9]%',ContactDetail))+2,(LEN(ContactDetail)))
				ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](ContactDetail)),2,LEN(ContactDetail)-1)
			END 
		WHERE [ContactDetail] IS NOT NULL OR [ContactDetail] <> '';


		-- Third partoes
		UPDATE [dbo].[PersonAddressDetailsCorrelation] SET
		[ThirdPartyName] = [tempdb].[dbo].[FN_ScrambleName](ThirdPartyName,0)
		WHERE ThirdPartyName IS NOT NULL OR ThirdPartyName <> '';


	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
	
END
