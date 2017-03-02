:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET ANSI_WARNINGS ON
GO
PRINT 'Step 2 - Scramble Data - CPF_BACS'

USE CPF_BACS
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
SET @EMailAddress = 'Environments@stepchange.org' --'no-reply@stepchange.org'
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
	
		--TABLE:  DMS.Clients
		UPDATE DMS.Clients SET
		ClientName = CASE WHEN ClientName IS NOT NULL OR ClientName <> '' THEN [tempdb].[dbo].[FN_ScrambleName](ClientName,1) END,
		[PartnerName] = CASE WHEN [PartnerName] IS NOT NULL OR [PartnerName] <> '' THEN [tempdb].[dbo].[FN_ScrambleName]([PartnerName],1) END;

			COMMIT TRAN UpdateNames
	END

-- Scramble Client Address if required
	IF  @DataScrambleAddress = 1
	BEGIN
		--TABLE:  DMS.Clients
		UPDATE DMS.Clients SET
		HouseNameOrNumber = CASE WHEN HouseNameOrNumber IS NOT NULL OR HouseNameOrNumber <> '' THEN @HouseNameOrNumber END,
		address1 = CASE WHEN address1 IS NOT NULL OR address1 <> '' THEN @Address1 END, 
		address2 = CASE WHEN address2 IS NOT NULL OR address2 <> '' THEN @Address2 END, 
		address3 = CASE WHEN address3 IS NOT NULL OR address3 <> '' THEN @Address3 END, 
		PostTown = CASE WHEN PostTown IS NOT NULL OR PostTown <> '' THEN @PostTown END, 
		Region = CASE WHEN Region IS NOT NULL OR Region <> '' THEN @Region END, 
		Country = CASE WHEN Country IS NOT NULL OR Country <> '' THEN @Country END
  
		-- CREDITORS
  
		UPDATE DMS.CreditorAddresses SET
		Address1 = CASE WHEN Address1 IS NOT NULL OR Address1 <> '' THEN @HouseNameOrNumber END,
		Address2 = CASE WHEN Address2 IS NOT NULL OR Address2 <> '' THEN @Address2 END,      
		Address3 = CASE WHEN Address3 IS NOT NULL OR Address3 <> '' THEN @PostTown + ' ' + @Region + ' ' + @PostCode END      

	END

	UPDATE dbo.EmailAddresses
	SET emailaddress = @EMailAddress, Internal = 0

	/* Extra scrambling of email address added by TB on 12/11/14  at request of AlasdairC for new CPFBACS config tool release */
	UPDATE [dbo].[CpfBacsPending]
	SET [emailaddresses] = CASE WHEN [emailaddresses] IS NOT NULL THEN @EMailAddress ELSE [emailaddresses] END,
		[emailaddresses2] = CASE WHEN [emailaddresses2] IS NOT NULL THEN @EMailAddress ELSE [emailaddresses2] END;

	UPDATE [dbo].[CpfBacsPending_audit]
	SET [emailaddresses] = CASE WHEN [emailaddresses] IS NOT NULL THEN @EMailAddress ELSE [emailaddresses] END,
		[emailaddresses2] = CASE WHEN [emailaddresses2] IS NOT NULL THEN @EMailAddress ELSE [emailaddresses2] END;

	UPDATE [dbo].[CpfBacsPendingParameters]
 	SET		[VALUE] = @EMailAddress
	WHERE [key] in ('EMAIL_TLEM01', 'EMAIL_MAEM01', 'EMAIL_MAEM02');


	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
END
