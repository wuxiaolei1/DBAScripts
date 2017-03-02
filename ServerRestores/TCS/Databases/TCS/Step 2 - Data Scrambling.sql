:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
PRINT 'Step 2 - Scramble Data - TCS'

USE TCS
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
-- Scramble Client Names if required
		IF  @DataScrambleName = 1
		BEGIN
			BEGIN TRAN UpdateNames

			--TABLE: dbo.ClientDetails
			UPDATE dbo.ClientDetails SET
			Surname = CASE WHEN Surname IS NOT NULL OR Surname <> '' THEN [tempdb].[dbo].[FN_ScrambleName](Surname,0) END,
			PartnerSurname = CASE WHEN PartnerSurname IS NOT NULL OR PartnerSurname <> '' THEN [tempdb].[dbo].[FN_ScrambleName](PartnerSurname,0) END

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

-- Scramble Client Addresses if required
		IF  @DataScrambleAddress = 1
		BEGIN
			--TABLE: dbo.ClientDetails
			UPDATE dbo.ClientDetails SET
			HouseNumber = CASE WHEN HouseNumber IS NOT NULL OR HouseNumber <> '' THEN @HouseNumber END,
			HouseName = CASE WHEN HouseName IS NOT NULL OR HouseName <> '' THEN @HouseName END,
			AddressLine1 = CASE WHEN AddressLine1 IS NOT NULL OR AddressLine1 <> '' THEN @AddressLine1 END,
			AddressLine2 = CASE WHEN AddressLine2 IS NOT NULL OR AddressLine2 <> '' THEN @AddressLine2 END,
			AddressLine3 = CASE WHEN AddressLine3 IS NOT NULL OR AddressLine3 <> '' THEN @AddressLine3 END,
			AddressLine4 = CASE WHEN AddressLine4 IS NOT NULL OR AddressLine4 <> '' THEN @AddressLine4 END
		END
	
		--TABLE: dbo.ClientDetails
		UPDATE dbo.ClientDetails SET		
		Email = CASE WHEN Email IS NOT NULL AND Email <> '' THEN @ClientEmail END

		UPDATE dbo.ClientDetails SET		
		AlternativeEmail = CASE WHEN AlternativeEmail IS NOT NULL AND AlternativeEmail <> '' THEN @ClientEmail END

		UPDATE scd
		SET HomeTelNo = 
		CASE  
		WHEN PATINDEX('%[^0-9]%',HomeTelNo) =1 THEN SUBSTRING(HomeTelNo,1,(PATINDEX('%[^0-9]%',HomeTelNo))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](HomeTelNo)),(PATINDEX('%[^0-9]%',HomeTelNo))+2,(LEN(HomeTelNo)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](HomeTelNo)),2,LEN(HomeTelNo)-1)
		END
		from dbo.ClientDetails scd
		WHERE HomeTelNo IS NOT NULL AND REPLACE(HomeTelNo,' ','') <> ''

		UPDATE scd
		SET WorkTelNo = 
		CASE  
		WHEN PATINDEX('%[^0-9]%',WorkTelNo) =1 THEN SUBSTRING(WorkTelNo,1,(PATINDEX('%[^0-9]%',WorkTelNo))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](WorkTelNo)),(PATINDEX('%[^0-9]%',WorkTelNo))+2,(LEN(WorkTelNo)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](WorkTelNo)),2,LEN(WorkTelNo)-1)
		END
		from dbo.ClientDetails scd
		WHERE WorkTelNo IS NOT NULL AND REPLACE(WorkTelNo,' ','') <> ''

		UPDATE scd
		SET MobTelNo = 
		CASE  
		WHEN PATINDEX('%[^0-9]%',MobTelNo) =1 THEN SUBSTRING(MobTelNo,1,(PATINDEX('%[^0-9]%',MobTelNo))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](MobTelNo)),(PATINDEX('%[^0-9]%',MobTelNo))+2,(LEN(MobTelNo)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](MobTelNo)),2,LEN(MobTelNo)-1)
		END
		from dbo.ClientDetails scd
		WHERE MobTelNo IS NOT NULL AND REPLACE(MobTelNo,' ','') <> ''
		
		--TABLE: dbo.ExternalCommunicationTypes
		UPDATE dbo.ExternalCommunicationTypes
			SET InsertLocation = @InsertLocation
		--	,IncludeInsert = 1
		WHERE CommName = 'EC.InfoPack'

	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
	
END
