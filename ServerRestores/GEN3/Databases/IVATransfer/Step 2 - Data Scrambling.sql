:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET ANSI_WARNINGS ON
GO
PRINT 'Step 2 - Scramble Data - IVATransfer'

USE IVATransfer
GO

DECLARE @InternalEmail VARCHAR(50)
DECLARE @ClientEmail VARCHAR(100)
DECLARE @ClientPhoneNoDay VARCHAR(50)
DECLARE @ClientPhoneNoHome VARCHAR(50)
DECLARE @ClientPhoneNoMobile VARCHAR(50)
DECLARE @DataScramble BIT
DECLARE @Environment VARCHAR(50)
DECLARE @Pipe NVARCHAR(1)
DECLARE @HouseNameorNumber VARCHAR (50)
DECLARE @AddressLine1 VARCHAR (50)
DECLARE @AddressLine2 VARCHAR (50)
DECLARE @PostTown VARCHAR (50)
DECLARE @Region VARCHAR (50)
DECLARE @PostCode VARCHAR (50)
DECLARE @DataRowCount INT
DECLARE @DataScrambleName INT -- 1 = Yes Scramble Name
DECLARE @DataScrambleAddress INT -- 1 = Yes Scramble Address

--SET DEFAULTS...
SET @InternalEmail = 'thisisadummyemail@notstepchange.co.na' --'no-reply@stepchange.org'
SET @ClientEmail = 'thisisadummyemail@notstepchange.co.na' --'no-reply@stepchange.org'
SET @ClientPhoneNoDay = '09999999999'
SET @ClientPhoneNoHome = '09999999999'
SET @ClientPhoneNoMobile = '09999999999'
SET @DataScramble = 1
SET @Environment = $(Environment)
SET @Pipe = '|'
SET @HouseNameorNumber = 'StepChange - Systems Department'
SET @AddressLine1 = 'Wade House'
SET @AddressLine2 = 'Merrion Centre'
SET @PostTown = 'Leeds'
SET @Region = 'Yorkshire'
SET @PostCode = 'LS2 8NG'
SET @DataRowCount = 0
SET @DataScrambleName = 1
SET @DataScrambleAddress = 1

--Read the specific settings if available...
SELECT	@InternalEmail = EDV.Email
		, @ClientEmail = EDV.ClientEmail
		, @ClientPhoneNoDay = EDV.TelNo
		, @ClientPhoneNoHome = EDV.TelNo
		, @ClientPhoneNoMobile = EDV.TelNo
		, @DataScramble = EDV.DataScramble
		, @HouseNameorNumber = EDV.HouseNameorNumber
		, @AddressLine1 = EDV.AddressLine1
		, @AddressLine2 = EDV.AddressLine2
		, @PostTown = EDV.PostTown
		, @Region = EDV.Region
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

		-- TABLE: dbo.IVAPerson
		UPDATE dbo.IVAPerson SET
		Surname = CASE WHEN Surname IS NOT NULL OR Surname <> '' THEN [tempdb].[dbo].[FN_ScrambleName](Surname,0) END

		COMMIT TRAN UpdateNames
	END

-- Scramble Client Address if required
	IF  @DataScrambleAddress = 1
	BEGIN
		-- TABLE: dbo.IVAClient
		UPDATE dbo.IVAClient
		SET AddressText = @HouseNameorNumber + @Pipe + @AddressLine1 + @Pipe + @AddressLine2
		 + @Pipe + @PostTown + @Pipe + @Region + @Pipe + @PostCode
		WHERE ISNULL(AddressText,'') <> ''

	END

		-- TABLE: dbo.IVAClient
		UPDATE dbo.IVAClient SET
		CCCSCounsellorEmail = CASE WHEN CCCSCounsellorEmail IS NOT NULL OR CCCSCounsellorEmail <> '' THEN @InternalEmail END, 
		EmailAddress = CASE WHEN EmailAddress IS NOT NULL OR EmailAddress <> '' THEN @ClientEmail END
  
		UPDATE  dbo.IVAClient
		SET     PhoneNoDay = CASE  
		WHEN PATINDEX('%[^0-9]%',PhoneNoDay)  =1 THEN SUBSTRING(PhoneNoDay,1,(PATINDEX('%[^0-9]%',PhoneNoDay))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](PhoneNoDay)),(PATINDEX('%[^0-9]%',PhoneNoDay))+2,(LEN(PhoneNoDay))) COLLATE DATABASE_DEFAULT
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](PhoneNoDay)),2,LEN(PhoneNoDay)-1) COLLATE DATABASE_DEFAULT
		END 
		WHERE PhoneNoDay IS NOT NULL AND REPLACE(PhoneNoDay,' ','') <> ''      
		
		UPDATE  dbo.IVAClient
		SET     PhoneNoHome = CASE  
		WHEN PATINDEX('%[^0-9]%',PhoneNoHome)  =1 THEN SUBSTRING(PhoneNoHome,1,(PATINDEX('%[^0-9]%',PhoneNoHome))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](PhoneNoHome)),(PATINDEX('%[^0-9]%',PhoneNoHome))+2,(LEN(PhoneNoHome))) COLLATE DATABASE_DEFAULT
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](PhoneNoHome)),2,LEN(PhoneNoHome)-1) COLLATE DATABASE_DEFAULT
		END
		WHERE PhoneNoHome IS NOT NULL AND REPLACE(PhoneNoHome,' ','') <> ''      
		
		UPDATE  dbo.IVAClient
		SET     PhoneNoMobile = CASE  
		WHEN PATINDEX('%[^0-9]%',PhoneNoMobile)  =1 THEN SUBSTRING(PhoneNoMobile,1,(PATINDEX('%[^0-9]%',PhoneNoMobile))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](PhoneNoMobile)),(PATINDEX('%[^0-9]%',PhoneNoMobile))+2,(LEN(PhoneNoMobile))) COLLATE DATABASE_DEFAULT
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](PhoneNoMobile)),2,LEN(PhoneNoMobile)-1) COLLATE DATABASE_DEFAULT
		END
		WHERE PhoneNoMobile IS NOT NULL AND REPLACE(PhoneNoMobile,' ','') <> ''      
		
		-- TABLE: dbo.IVAParameters
		UPDATE dbo.IVAParameters SET
		EmailOnAddressProbsTo = CASE WHEN EmailOnAddressProbsTo IS NOT NULL OR EmailOnAddressProbsTo <> '' THEN @InternalEmail END,
		EmailOnErrorTo = CASE WHEN EmailOnErrorTo IS NOT NULL OR EmailOnErrorTo <> '' THEN @InternalEmail END,
		EmailOnFailureTo = CASE WHEN EmailOnFailureTo IS NOT NULL OR EmailOnFailureTo <> '' THEN @InternalEmail END,
		EmailOnSuccessTo = CASE WHEN EmailOnSuccessTo IS NOT NULL OR EmailOnSuccessTo <> '' THEN @InternalEmail END

		-- Raise an error if no rows were selected from the Environment Data Values Table
		IF @DataRowCount = 0
		RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)

END
