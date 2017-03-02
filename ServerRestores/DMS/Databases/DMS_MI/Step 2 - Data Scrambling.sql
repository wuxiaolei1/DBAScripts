:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
PRINT 'Step 2 - Scramble Data - DMS_MI'

USE DMS_MI
GO

SET XACT_ABORT ON ;

DECLARE @ClientEmail VARCHAR(50)
		, @AreaCode VARCHAR(5)
		, @TelNo VARCHAR(20)
		, @Extension VARCHAR(10)
		, @Website VARCHAR(50)
		, @EmployerPhone VARCHAR(25)
		, @EmployerFax VARCHAR(25)
		, @LocationDirections VARCHAR(640)
		, @CreditorAddressEmail VARCHAR(80)
		, @CreditorPrefix VARCHAR(50)
		, @CountryCode VARCHAR(10)
		, @DataScramble BIT
		, @AddressLine1 VARCHAR(80)
		, @AddressLine2 VARCHAR(80)
		, @City VARCHAR(50)
		, @State VARCHAR(50)
		, @Zip VARCHAR(50)
		, @Environment VARCHAR(50)
		, @DataRowCount INT
		, @DataScrambleName INT -- 1 = Yes Scramble Name
		, @DataScrambleAddress INT -- 1 = Yes Scramble Address

--DEFAULTS...
SET @ClientEmail = 'thisisadummyemail@notstepchange.co.na'
SET @AreaCode = '0999'
SET @TelNo = '9999999'
SET @Extension = '99'
SET @Website = 'ws'
SET @EmployerPhone = '09999999999'
SET @EmployerFax = '09999999999'
SET @LocationDirections = 'NA'
SET @CreditorAddressEmail = 'thisisadummyemail@notstepchange.co.na'
SET @CreditorPrefix = 'NA'
SET @CountryCode = '0999'
SET @DataScramble = 1
SET @AddressLine1 = 'StepChange - Systems Department'
SET @AddressLine2 = 'Wade House'
SET @City = 'Leeds'
SET @State = 'Yorkshire'
SET @Zip = 'LS2 8NG'
SET @Environment = $(Environment)
SET @DataRowCount = 0
SET @DataScrambleName = 1
SET @DataScrambleAddress = 1

--Read the specific settings if available...
SELECT	@ClientEmail = EDV.ClientEmail
		, @AreaCode = EDV.AreaCode
		, @TelNo = EDV.TelNo
		, @Extension = EDV.Extension
		, @Website = EDV.Website
		, @EmployerPhone = EDV.TelNo
		, @EmployerFax = EDV.FaxNo
		, @LocationDirections = EDV.LocationDirections
		, @CreditorAddressEmail = EDV.Email
		, @CreditorPrefix = EDV.CreditorPrefix
		, @CountryCode = EDV.CountryCode
		, @DataScramble = EDV.DataScramble
		, @AddressLine1 = EDV.HouseNameOrNumber
		, @AddressLine2 = EDV.AddressLine2
		, @City = EDV.PostTown
		, @State = EDV.Region
		, @Zip = EDV.PostCode
		, @DataScrambleName = EDV.DataScrambleName
		, @DataScrambleAddress = EDV.DataScrambleAddress	

FROM EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE Environment = @Environment

SET @DataRowCount = @@Rowcount

IF @DataScramble = 1
BEGIN
	

/*--- Truncate MI Tables and Temp Tables ---*/
		
		TRUNCATE TABLE dbo.creditor
		TRUNCATE TABLE dbo.creditors_post_merge
		TRUNCATE TABLE dbo.tblMI_DMS_Client_Extract
		TRUNCATE TABLE dbo.tblMI_DMS_ClientCred_Extract
		TRUNCATE TABLE dbo.tblMI_DMS_ClientTrans_Extract
		TRUNCATE TABLE dbo.tblMI_DMS_Counsellor_Extract
		TRUNCATE TABLE dbo.tblMI_DMS_Creditor_Extract
		TRUNCATE TABLE dbo.tblMI_DMS_Message_Extract

	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
END
