:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
PRINT 'Step 2 - Scramble Data - DotNetNuke'

USE DotNetNuke
GO

SET QUOTED_IDENTIFIER ON;

DECLARE @Email VARCHAR(64)
		, @DataScramble BIT
		, @Environment VARCHAR(30)
		, @DataRowCount INT

--SET DEFAULTS...
SET @Email = 'thisisadummyemail@notstepchange.co.na' --'no-reply@stepchange.org'
SET @DataScramble = 1
SET @Environment = $(Environment)
SET @DataRowCount = 0


--Read the specific settings if available...
SELECT	@Email = EDV.Email
		, @DataScramble = EDV.DataScramble
		
FROM EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE Environment = @Environment

SET @DataRowCount = @@Rowcount

-- Perform Updates
IF @DataScramble = 1
BEGIN
		-- Scramble Client Names if required
		BEGIN TRAN UpdateNames
		--TABLE: Archive.SENT_TRANSACTIONS_old
		update CccsContactMeRequests
		set ClientName = upper([tempdb].[dbo].[FN_ScrambleName](ClientName,1))
		Where isnull(ClientName,'') <> '';
		COMMIT TRAN UpdateNames
		
		UPDATE dbo.aspnet_Membership
		SET Email = @Email
		WHERE ISNULL(Email,'') <> ''

		UPDATE dbo.aspnet_Membership
		SET LoweredEmail = @Email
		WHERE ISNULL(LoweredEmail,'') <> ''

		UPDATE dbo.CccsEnquiryTypes
		SET EmailAddress = @Email
		WHERE ISNULL(EmailAddress,'') <> ''

		UPDATE dbo.DNNPRO_License
		SET Email = @Email
		WHERE ISNULL(Email,'') <> ''

		UPDATE dbo.HostSettings
		SET SettingValue = @Email
		WHERE SettingName = 'HostEmail'

		UPDATE dbo.ModuleSettings
		SET SettingValue = @Email
		WHERE SettingName = 'FromEmailAddress'

		UPDATE dbo.Packages
		SET Email = @Email
		WHERE ISNULL(Email,'') <> ''

		UPDATE dbo.Users
		SET Email = @Email
		WHERE ISNULL(Email,'') <> ''

		UPDATE dbo.Vendors
		SET Email = @Email
		WHERE ISNULL(Email,'') <> ''
				
		-- [dbo].[CccsContactMeRequests]
		UPDATE  [dbo].[CccsContactMeRequests]
		SET     ContactNo = CASE  
		WHEN PATINDEX('%[^0-9]%',ContactNo)  =1 THEN SUBSTRING(ContactNo,1,(PATINDEX('%[^0-9]%',ContactNo))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](ContactNo)),(PATINDEX('%[^0-9]%',ContactNo))+2,(LEN(ContactNo)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](ContactNo)),2,LEN(ContactNo)-1)
		END
		WHERE ContactNo IS NOT NULL AND REPLACE(ContactNo,' ','') <> ''

		UPDATE [dbo].[CccsContactMeRequests]
		SET [EmailAddress] = @Email
		WHERE [EmailAddress] IS NOT NULL AND REPLACE([EmailAddress],' ','') <> ''

	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
	
END

