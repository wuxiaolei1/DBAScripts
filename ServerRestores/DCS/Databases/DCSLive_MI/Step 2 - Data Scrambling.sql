:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
PRINT 'Step 2 - Data Scramble - DCSLive_MI'
USE DCSLive_MI
GO

SET XACT_ABORT ON ;

DECLARE @ClientTelNo VARCHAR(20)
		, @ClientEmail VARCHAR(50)
		, @Website VARCHAR(50)
		, @NetSendUser VARCHAR(30)
		, @CommsSendEmails BIT
		, @SendXLlProcFileTo VARCHAR(50)
		, @CommsServer1 VARCHAR(30)
		, @CommsServer2 VARCHAR(30)
		, @AppointmentMobTel VARCHAR(255)
		, @RefEmail VARCHAR(50)
		, @RefTelNo VARCHAR(20)
		, @ScrambleData BIT
		, @HouseNameorNumber VARCHAR(50)
		, @AddressLine1 VARCHAR(30)
		, @AddressLine2 VARCHAR(30)
		, @AddressLine3 VARCHAR(30)
		, @AddressLine4 VARCHAR(30)
		, @PostTown VARCHAR(30)
		, @Region VARCHAR(30)
		, @Postcode VARCHAR(15)
		, @Country INT
		, @Environment VARCHAR(15)
		, @DataRowCount INT
		, @DataScrambleName INT -- 1 = Yes Scramble Name
		, @DataScrambleAddress INT -- 1 = Yes Scramble Address

--SET DEFAULTS...
SET @ClientTelNo = '09999999999'
SET @ClientEmail = 'thisisadummyemail@notstepchange.co.na' --'no-reply@stepchange.org'
SET @Website = 'ws'
SET @netSendUser = 'thisisadummyemail'
SET @CommsSendEmails = 0
SET @SendXLlProcFileTo = 'thisisadummyemail@notstepchange.co.na' --'@stepchange.org'
SET @CommsServer1 = '\\LDSCOMPRO1APP01'
SET @CommsServer2 = '\\LDSCOMPRO1APP02'
SET @AppointmentMobTel = '09999999999'
SET @RefEmail = 'thisisadummyemail@notstepchange.co.na' --'no-reply@stepchange.org'
SET @RefTelNo = '09999999999'
SET @ScrambleData = 1
SET @HouseNameorNumber = 'StepChange - Systems Department'
SET @AddressLine1 = ''
SET @AddressLine2 = 'Wade House'
SET @AddressLine3 = null
SET @AddressLine4 = ''
SET @PostTown = 'Leeds'
SET @Region = 'Yorkshire'
SET @Postcode = 'LS2 8NG'
SET @Country = 826
SET @Environment = $(Environment)
SET @DataRowCount = 0
SET @DataScrambleName = 1
SET @DataScrambleAddress = 1

--Read the specific settings if available...
SELECT	@ClientTelNo = EDV.TelNo
		, @ClientEmail = EDV.ClientEmail
		, @Website = EDV.Website
		, @netSendUser = EDV.netSendUser
		, @CommsSendEmails = EDV.CommsSendEmails
		, @SendXLlProcFileTo = EDV.SendXLlProcFileTo
		, @CommsServer1 = EDV.CommsServer1
		, @CommsServer2 = EDV.CommsServer2
		, @AppointmentMobTel = EDV.MobileNo
		, @RefEmail = EDV.Email
		, @RefTelNo = EDV.TelNo
		, @ScrambleData = EDV.DataScramble
		, @HouseNameorNumber = EDV.HouseNameorNumber
		, @AddressLine1 = EDV.AddressLine1
		, @AddressLine2 = EDV.AddressLine2
		, @AddressLine3 = EDV.AddressLine3
		, @AddressLine4 = EDV.AddressLine4
		, @PostTown = EDV.PostTown
		, @Region = EDV.Region
		, @Postcode = EDV.PostCode
		, @Country = EDV.CountryCode
		, @DataScrambleName = EDV.DataScrambleName
		, @DataScrambleAddress = EDV.DataScrambleAddress		

FROM EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE Environment = @Environment

SET @DataRowCount = @@Rowcount

IF @ScrambleData = 1
BEGIN
	PRINT 'Starting data scrambling @ ...'
	PRINT GETDATE()
	-- No need to scramble just truncate all the tables as they will be rebuilt	

	/* Truncate MI Tables */
		TRUNCATE TABLE dbo.tblMI_DCS_ApptAvailability_Extract
		TRUNCATE TABLE dbo.tblMI_DCS_ApptResult_Extract
		TRUNCATE TABLE dbo.tblMI_DCS_ApptsCalendar_Extract
		TRUNCATE TABLE dbo.tblMI_DCS_ApptsUnallocated_Extract
		TRUNCATE TABLE dbo.tblMI_DCS_ApptsUnavailableEffected_Extract
		TRUNCATE TABLE dbo.tblMI_DCS_AssetLiability_Extract
		TRUNCATE TABLE dbo.tblMI_DCS_Budget_Extract
		TRUNCATE TABLE dbo.tblMI_DCS_BudgetClientInfo_Extract
		TRUNCATE TABLE dbo.tblMI_DCS_BudgetDebtReason_Extract
		TRUNCATE TABLE dbo.tblMI_DCS_Client
		TRUNCATE TABLE dbo.tblMI_DCS_Client_TPO
		TRUNCATE TABLE dbo.tblMI_DCS_Counselling_Extract
		TRUNCATE TABLE dbo.tblMI_DCS_DC_Extract_ClientCODetails
		TRUNCATE TABLE dbo.tblMI_DCS_DC_Extract_ClientContact
		TRUNCATE TABLE dbo.tblMI_DCS_DC_Extract_ClientContact_NamedAssociate
		TRUNCATE TABLE dbo.tblMI_DCS_DC_Extract_ClientDetails
		TRUNCATE TABLE dbo.tblMI_DCS_DC_Extract_ClientPartnerDetails
		TRUNCATE TABLE dbo.tblMI_DCS_DC_Extract_ClientThirdPartyDetails
		TRUNCATE TABLE dbo.tblMI_DCS_Debt_Extract
		TRUNCATE TABLE dbo.tblMI_DCS_IdealWeek
   /* End of Truncate MI Tables */

		PRINT 'Scrambling completed successfully at ...'
		PRINT GETDATE()

	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
END

