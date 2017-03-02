:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
PRINT 'Step 2 - Scramble Data - ClientRetention'

USE ClientRetention
GO

DECLARE @ClientEmail VARCHAR(255)
		, @WebSite VARCHAR(255)
		, @TelNo VARCHAR(16)
		, @DataScramble BIT
		, @Environment VARCHAR(50)
		, @FirstName VARCHAR(50)
		, @MobileNo VARCHAR(50)
		, @FaxNo VARCHAR(50)
		, @DataRowCount INT
		, @DataScrambleName INT -- 1 = Yes Scramble Name
		, @DataScrambleAddress INT -- 1 = Yes Scramble Address

--SET DEFAULTS...
SET @ClientEmail = 'thisisadummyemail@notstepchange.co.na' --'no-reply@stepchange.org'
SET @WebSite = 'website.cccs.co.uk'
SET @TelNo = '09999999999'
SET @MobileNo = '09999999999'
SET @FaxNo = '09999999999'
SET @DataScramble = 1
SET @Environment = $(Environment)
SET @DataRowCount = 0
SET @DataScrambleName = 1
SET @DataScrambleAddress = 1

--Read the specific settings if available...
SELECT	@ClientEmail = EDV.ClientEmail
		, @WebSite = EDV.WebSite
		, @TelNo = EDV.TelNo
		, @MobileNo = EDV.MobileNo
		, @FaxNo = EDV.FaxNo
		, @DataScramble = EDV.DataScramble
		, @DataScrambleName = EDV.DataScrambleName
		, @DataScrambleAddress = EDV.DataScrambleAddress

FROM    EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE   Environment = @Environment

SET @DataRowCount = @@Rowcount

--Perform Updates
IF @DataScramble = 1

BEGIN

-- Scramble Client Names if required
	IF  @DataScrambleName = 1
	BEGIN
		BEGIN TRAN UpdateNames

		--TABLE: dbo.DCS_Clients
		UPDATE dbo.DCS_Clients SET
		ClientLastName = CASE WHEN ClientLastName IS NOT NULL OR ClientLastName <> '' THEN [tempdb].[dbo].[FN_ScrambleName](ClientLastName,0) END,
		PartnerLastName = CASE WHEN PartnerLastName IS NOT NULL OR PartnerLastName <> '' THEN [tempdb].[dbo].[FN_ScrambleName](PartnerLastName,0) END

		COMMIT TRAN UpdateNames
	END

	--TABLE: dbo.DCS_ContactDetails
	UPDATE DCS_ContactDetails SET 
	HomeEmail = CASE WHEN HomeEmail IS NOT NULL OR HomeEmail <> '' THEN @ClientEmail END,
	WorkEmail = CASE WHEN WorkEmail IS NOT NULL OR WorkEmail <> '' THEN @ClientEmail END,
	OrgWebsite = CASE WHEN OrgWebsite IS NOT NULL OR OrgWebsite <> '' THEN @WebSite END,
	OrgEmail = CASE WHEN OrgEmail IS NOT NULL OR OrgEmail <> '' THEN @ClientEmail END
  
	UPDATE  dbo.DCS_ContactDetails
	SET     HomeTel = CASE  
	WHEN PATINDEX('%[^0-9]%',HomeTel)  =1 THEN SUBSTRING(HomeTel,1,(PATINDEX('%[^0-9]%',HomeTel))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](HomeTel)),(PATINDEX('%[^0-9]%',HomeTel))+2,(LEN(HomeTel)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](HomeTel)),2,LEN(HomeTel)-1)
	END
	WHERE HomeTel IS NOT NULL AND REPLACE(HomeTel,' ','') <> ''  
	
	UPDATE  dbo.DCS_ContactDetails
	SET     WorkTel = CASE  
	WHEN PATINDEX('%[^0-9]%',WorkTel)  =1 THEN SUBSTRING(WorkTel,1,(PATINDEX('%[^0-9]%',WorkTel))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](WorkTel)),(PATINDEX('%[^0-9]%',WorkTel))+2,(LEN(WorkTel)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](WorkTel)),2,LEN(WorkTel)-1)
	END
	WHERE WorkTel IS NOT NULL AND REPLACE(WorkTel,' ','') <> ''  
		
	UPDATE  dbo.DCS_ContactDetails
	SET     HomeFax = CASE  
	WHEN PATINDEX('%[^0-9]%',HomeFax)  =1 THEN SUBSTRING(HomeFax,1,(PATINDEX('%[^0-9]%',HomeFax))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](HomeFax)),(PATINDEX('%[^0-9]%',HomeFax))+2,(LEN(HomeFax)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](HomeFax)),2,LEN(HomeFax)-1)
	END
	WHERE HomeFax IS NOT NULL AND REPLACE(HomeFax,' ','') <> ''  
		
	UPDATE  dbo.DCS_ContactDetails
	SET     WorkFax = CASE  
	WHEN PATINDEX('%[^0-9]%',WorkFax)  =1 THEN SUBSTRING(WorkFax,1,(PATINDEX('%[^0-9]%',WorkFax))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](WorkFax)),(PATINDEX('%[^0-9]%',WorkFax))+2,(LEN(WorkFax)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](WorkFax)),2,LEN(WorkFax)-1)
	END
	WHERE WorkFax IS NOT NULL AND REPLACE(WorkFax,' ','') <> ''  
	
	UPDATE  dbo.DCS_ContactDetails
	SET     PersonalMobTel = CASE  
	WHEN PATINDEX('%[^0-9]%',PersonalMobTel)  =1 THEN SUBSTRING(PersonalMobTel,1,(PATINDEX('%[^0-9]%',PersonalMobTel))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](PersonalMobTel)),(PATINDEX('%[^0-9]%',PersonalMobTel))+2,(LEN(PersonalMobTel)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](PersonalMobTel)),2,LEN(PersonalMobTel)-1)
	END
	WHERE PersonalMobTel IS NOT NULL AND REPLACE(PersonalMobTel,' ','') <> ''  
	
	UPDATE  dbo.DCS_ContactDetails
	SET     WorkMobTel = CASE  
	WHEN PATINDEX('%[^0-9]%',WorkMobTel)  =1 THEN SUBSTRING(WorkMobTel,1,(PATINDEX('%[^0-9]%',WorkMobTel))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](WorkMobTel)),(PATINDEX('%[^0-9]%',WorkMobTel))+2,(LEN(WorkMobTel)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](WorkMobTel)),2,LEN(WorkMobTel)-1)
	END
	WHERE WorkMobTel IS NOT NULL AND REPLACE(WorkMobTel,' ','') <> ''  
	
	UPDATE  dbo.DCS_ContactDetails
	SET     CareOfTel = CASE  
	WHEN PATINDEX('%[^0-9]%',CareOfTel)  =1 THEN SUBSTRING(CareOfTel,1,(PATINDEX('%[^0-9]%',CareOfTel))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](CareOfTel)),(PATINDEX('%[^0-9]%',CareOfTel))+2,(LEN(CareOfTel)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](CareOfTel)),2,LEN(CareOfTel)-1)
	END
	WHERE CareOfTel IS NOT NULL AND REPLACE(CareOfTel,' ','') <> ''  
	
	UPDATE  dbo.DCS_ContactDetails
	SET     ThirdPartyTel = CASE  
	WHEN PATINDEX('%[^0-9]%',ThirdPartyTel)  =1 THEN SUBSTRING(ThirdPartyTel,1,(PATINDEX('%[^0-9]%',ThirdPartyTel))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](ThirdPartyTel)),(PATINDEX('%[^0-9]%',ThirdPartyTel))+2,(LEN(ThirdPartyTel)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](ThirdPartyTel)),2,LEN(ThirdPartyTel)-1)
	END
	WHERE ThirdPartyTel IS NOT NULL AND REPLACE(ThirdPartyTel,' ','') <> ''  
	
	UPDATE  dbo.DCS_ContactDetails
	SET     OrgTel = CASE  
	WHEN PATINDEX('%[^0-9]%',OrgTel)  =1 THEN SUBSTRING(OrgTel,1,(PATINDEX('%[^0-9]%',OrgTel))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](OrgTel)),(PATINDEX('%[^0-9]%',OrgTel))+2,(LEN(OrgTel)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](OrgTel)),2,LEN(OrgTel)-1)
	END
	WHERE OrgTel IS NOT NULL AND REPLACE(OrgTel,' ','') <> ''  


	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
	
END
