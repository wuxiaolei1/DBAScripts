:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET ANSI_WARNINGS ON
GO
PRINT 'Step 2 - Scramble Data - CreditReportsAudit'

USE CreditReportsAudit
GO

DECLARE @Environment VARCHAR(50) 
DECLARE @EMailAddress VARCHAR(255)
DECLARE @DataScramble BIT
DECLARE @HouseNameOrNumber VARCHAR(50)
DECLARE @Address1 VARCHAR(35)
DECLARE @Address2 VARCHAR(35)
DECLARE @Address3 VARCHAR(35)
DECLARE @PostTown VARCHAR(35)
DECLARE @Region VARCHAR(35)
DECLARE @PostCode VARCHAR(35)
DECLARE @Country VARCHAR(35)
DECLARE @DataRowCount INT
DECLARE @DataScrambleName INT -- 1 = Yes Scramble Name
DECLARE @DataScrambleAddress INT -- 1 = Yes Scramble Address

--SET DEFAULTS...
SET @EMailAddress = 'thisisadummyemail@notstepchange.co.na' --'no-reply@stepchange.org'
SET @DataScramble = 1
SET @Environment = $(Environment)
SET @HouseNameOrNumber = 'StepChange - Systems Department'
SET @Address1 = 'Wade House'
SET @Address2 = 'Merrion Centre'
SET @Address3 = ''
SET @PostTown = 'Leeds'
SET @Region = 'Yorkshire'
SET @PostCode = 'LS2 8NG'
SET @Country = ''
SET @DataRowCount = 0
SET @DataScrambleName = 1
SET @DataScrambleAddress = 1

--Read the specific settings if available...
SELECT	@EMailAddress = EDV.ClientEmail
		, @DataScramble = EDV.DataScramble
		, @HouseNameOrNumber = EDV.HouseNameOrNumber
		, @Address1 = EDV.AddressLine1
		, @Address2 = EDV.AddressLine2
		, @Address3 = EDV.AddressLine3
		, @PostTown = EDV.PostTown
		, @Region = EDV.Region
		, @PostCode = EDV.PostCode
		, @Country = EDV.Country
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
	
		--TABLE:  dbo.Audit
		UPDATE dbo.Audit SET
		ClientSurname = CASE WHEN ClientSurname IS NOT NULL OR ClientSurname <> '' THEN [tempdb].[dbo].[FN_ScrambleName](ClientSurname,0) END,
		PartnerSurname = CASE WHEN PartnerSurname IS NOT NULL OR PartnerSurname <> '' THEN [tempdb].[dbo].[FN_ScrambleName](PartnerSurname,0) END

			COMMIT TRAN UpdateNames
	END

-- Scramble Client Address if required
	IF  @DataScrambleAddress = 1
	BEGIN
		--TABLE:  dbo.Audit
		UPDATE dbo.Audit SET
		CurrentAddress = CASE WHEN CurrentAddress IS NOT NULL OR CurrentAddress <> '' THEN @Address1 END
	END
	
	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
END
