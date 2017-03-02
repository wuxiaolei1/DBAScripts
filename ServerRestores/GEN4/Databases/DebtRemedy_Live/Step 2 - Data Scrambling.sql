:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET ANSI_WARNINGS ON
GO
PRINT 'Step 2 - Scramble Data - DebtRemedy_Live'

USE DEBTREMEDY_Live
GO

SET XACT_ABORT ON ;

DECLARE @ClientEmail VARCHAR(255)
DECLARE @HomeTelNo VARCHAR(16)
DECLARE @WorkTelNo VARCHAR(16)
DECLARE @MobTelNo VARCHAR(16)
DECLARE @DataScramble BIT
DECLARE @HouseNumber INT
DECLARE @HouseName VARCHAR(50)
DECLARE @PostCode VARCHAR(8)
DECLARE @AddressLine1 VARCHAR(100)
DECLARE @AddressLine2 VARCHAR(100)
DECLARE @AddressLine3 VARCHAR(100)
DECLARE @AddressLine4 VARCHAR(100)
DECLARE @Environment VARCHAR(30)
DECLARE @DataRowCount INT
DECLARE @DataScrambleName INT -- 1 = Yes Scramble Name
DECLARE @DataScrambleAddress INT -- 1 = Yes Scramble Address

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
SET @AddressLine3 = 'Leeds'
SET @AddressLine4 = 'Yorkshire'
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

		-- TABLE: dbo.ClientDetails
		UPDATE dbo.ClientDetails SET
		Surname = CASE WHEN Surname IS NOT NULL OR Surname <> '' THEN [tempdb].[dbo].[FN_ScrambleName](Surname,0) END, 
		PartnerSurname = CASE WHEN PartnerSurname IS NOT NULL OR PartnerSurname <> '' THEN [tempdb].[dbo].[FN_ScrambleName](PartnerSurname,0) END

		UPDATE dbo.CallBacks 
		SET ClientName = CASE WHEN ClientName IS NOT NULL OR ClientName <> '' THEN [tempdb].[dbo].[FN_ScrambleName](ClientName,1) END

		-- AS, 24/08/2015, Split Solutions - scramble client and partner last names in the XML

		UPDATE dbo.SplitBudgets
		SET BudgetXml = 
		CONVERT(XML, STUFF(CONVERT(NVARCHAR(MAX), BudgetXml),
		CHARINDEX(' LastName="', CONVERT(NVARCHAR(MAX), BudgetXml),
		CHARINDEX('<ClientDetail ', CONVERT(NVARCHAR(MAX), BudgetXml))) + 11, LEN(ScrambledLastName), ScrambledLastName))
		FROM dbo.SplitBudgets b
		INNER JOIN (
			SELECT SplitBudgetID,
				[tempdb].[dbo].[FN_ScrambleName](BudgetXml.value('(/Client/ClientDetail/@LastName)[1]', 'nvarchar(255)'), 0) AS ScrambledLastName
			FROM dbo.SplitBudgets
			WHERE ISNULL(BudgetXml.value('(/Client/ClientDetail/@LastName)[1]', 'nvarchar(255)'), '') <> ''
		) s ON s.SplitBudgetID = b.SplitBudgetID

		UPDATE dbo.SplitBudgets
		SET BudgetXml = 
		CONVERT(XML, STUFF(CONVERT(NVARCHAR(MAX), BudgetXml),
		CHARINDEX(' LastName="', CONVERT(NVARCHAR(MAX), BudgetXml),
		CHARINDEX('<PartnerDetail ', CONVERT(NVARCHAR(MAX), BudgetXml))) + 11, LEN(ScrambledLastName), ScrambledLastName))
		FROM dbo.SplitBudgets b
		INNER JOIN (
			SELECT SplitBudgetID,
				[tempdb].[dbo].[FN_ScrambleName](BudgetXml.value('(/Client/PartnerDetail/@LastName)[1]', 'nvarchar(255)'), 0) AS ScrambledLastName
			FROM dbo.SplitBudgets
			WHERE ISNULL(BudgetXml.value('(/Client/PartnerDetail/@LastName)[1]', 'nvarchar(255)'), '') <> ''
		) s ON s.SplitBudgetID = b.SplitBudgetID

		--MI table
		UPDATE [dbo].[MI_SplitBudgets_Xml]
		SET BudgetXml = 
		CONVERT(XML, STUFF(CONVERT(NVARCHAR(MAX), BudgetXml),
		CHARINDEX(' LastName="', CONVERT(NVARCHAR(MAX), BudgetXml),
		CHARINDEX('<ClientDetail ', CONVERT(NVARCHAR(MAX), BudgetXml))) + 11, LEN(ScrambledLastName), ScrambledLastName))
		FROM [dbo].[MI_SplitBudgets_Xml] b
		INNER JOIN (
			SELECT ID,
				[tempdb].[dbo].[FN_ScrambleName](BudgetXml.value('(/Client/ClientDetail/@LastName)[1]', 'nvarchar(255)'), 0) AS ScrambledLastName
			FROM [dbo].[MI_SplitBudgets_Xml]
			WHERE ISNULL(BudgetXml.value('(/Client/ClientDetail/@LastName)[1]', 'nvarchar(255)'), '') <> ''
		) s ON s.ID = b.ID

		UPDATE [dbo].[MI_SplitBudgets_Xml]
		SET BudgetXml = 
		CONVERT(XML, STUFF(CONVERT(NVARCHAR(MAX), BudgetXml),
		CHARINDEX(' LastName="', CONVERT(NVARCHAR(MAX), BudgetXml),
		CHARINDEX('<PartnerDetail ', CONVERT(NVARCHAR(MAX), BudgetXml))) + 11, LEN(ScrambledLastName), ScrambledLastName))
		FROM [dbo].[MI_SplitBudgets_Xml] b
		INNER JOIN (
			SELECT ID,
				[tempdb].[dbo].[FN_ScrambleName](BudgetXml.value('(/Client/PartnerDetail/@LastName)[1]', 'nvarchar(255)'), 0) AS ScrambledLastName
			FROM [dbo].[MI_SplitBudgets_Xml]
			WHERE ISNULL(BudgetXml.value('(/Client/PartnerDetail/@LastName)[1]', 'nvarchar(255)'), '') <> ''
		) s ON s.ID = b.ID

		-----------------------------------------

		COMMIT TRAN UpdateNames
	END

-- Scramble Client Address if required
	IF  @DataScrambleAddress = 1
	BEGIN
		-- TABLE: dbo.ClientDetails
		UPDATE dbo.ClientDetails SET
		HouseNumber = CASE WHEN HouseNumber IS NOT NULL OR HouseNumber <> '' THEN @HouseNumber END, 
		HouseName = CASE WHEN HouseName IS NOT NULL OR HouseName <> '' THEN @HouseName END, 
		AddressLine1 = CASE WHEN AddressLine1 IS NOT NULL OR AddressLine1 <> '' THEN @AddressLine1 END, 
		AddressLine2 = CASE WHEN AddressLine2 IS NOT NULL OR AddressLine2 <> '' THEN @AddressLine2 END, 
		AddressLine3 = CASE WHEN AddressLine3 IS NOT NULL OR AddressLine3 <> '' THEN @AddressLine3 END, 
		AddressLine4 = CASE WHEN AddressLine4 IS NOT NULL OR AddressLine4 <> '' THEN @AddressLine4 END
	END

	-- TABLE: dbo.VCProperties
	UPDATE dbo.VCProperties SET
	CharValue = '"UAT Debt Remedy (testing only)" <druat@stepchange.org>"'
	WHERE PropertyName = 'P.DebtRemedyEmail'

	-- TABLE: dbo.ClientDetails
	UPDATE dbo.ClientDetails SET
	email = CASE WHEN email IS NOT NULL OR email <> '' THEN @ClientEmail END 
	
	UPDATE  dbo.ClientDetails
	SET     HomeTelNo = CASE  
	WHEN PATINDEX('%[^0-9]%',HomeTelNo)  =1 THEN SUBSTRING(HomeTelNo,1,(PATINDEX('%[^0-9]%',HomeTelNo))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](HomeTelNo)),(PATINDEX('%[^0-9]%',HomeTelNo))+2,(LEN(HomeTelNo)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](HomeTelNo)),2,LEN(HomeTelNo)-1)
	END
	WHERE HomeTelNo IS NOT NULL AND REPLACE(HomeTelNo,' ','') <> ''
	
	UPDATE  dbo.ClientDetails
	SET     WorkTelNo = CASE  
	WHEN PATINDEX('%[^0-9]%',WorkTelNo)  =1 THEN SUBSTRING(WorkTelNo,1,(PATINDEX('%[^0-9]%',WorkTelNo))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](WorkTelNo)),(PATINDEX('%[^0-9]%',WorkTelNo))+2,(LEN(WorkTelNo)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](WorkTelNo)),2,LEN(WorkTelNo)-1)
	END
	WHERE WorkTelNo IS NOT NULL AND REPLACE(WorkTelNo,' ','') <> ''
	
	UPDATE  dbo.ClientDetails
	SET     MobTelNo = CASE  
	WHEN PATINDEX('%[^0-9]%',MobTelNo)  =1 THEN SUBSTRING(MobTelNo,1,(PATINDEX('%[^0-9]%',MobTelNo))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](MobTelNo)),(PATINDEX('%[^0-9]%',MobTelNo))+2,(LEN(MobTelNo)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](MobTelNo)),2,LEN(MobTelNo)-1)
	END
	WHERE MobTelNo IS NOT NULL AND REPLACE(MobTelNo,' ','') <> ''

	UPDATE dbo.CallBacks 
	SET EmailAddress = CASE WHEN EmailAddress IS NOT NULL OR EmailAddress <> '' THEN @ClientEmail END

	UPDATE dbo.CallBacks 
	SET ContactNo = CASE WHEN ContactNo IS NOT NULL OR ContactNo <> '' THEN @HomeTelNo END

	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
END




