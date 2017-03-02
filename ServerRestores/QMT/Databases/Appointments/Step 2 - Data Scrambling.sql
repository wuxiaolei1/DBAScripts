:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
PRINT 'Step 2 - Scramble Data - Appointments'

USE Appointments
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

			--TABLE: dbo.ReminderCommunications
			UPDATE dbo.ReminderCommunications 
			SET	ClientsCommunicationName = 
				CASE 
					WHEN ClientsCommunicationName IS NOT NULL OR ClientsCommunicationName <> '' 
					THEN [tempdb].[dbo].[FN_ScrambleName](ClientsCommunicationName,0) 
				END
				
			COMMIT TRAN UpdateNames
		END

-- Scramble Client Addresses if required
		/**** no address scrambling required ******
		IF  @DataScrambleAddress = 1
		BEGIN
			--TABLE: 
	
		END
		*****/
	
		--TABLE: dbo.ReminderCommunications
		UPDATE dbo.ReminderCommunications SET		
		EmailAddress = CASE WHEN EmailAddress IS NOT NULL OR EmailAddress <> '' THEN @ClientEmail END
  
		UPDATE  dbo.ReminderCommunications
		SET     MobilePhoneNumber = CASE  
		WHEN PATINDEX('%[^0-9]%',MobilePhoneNumber)  =1 THEN SUBSTRING(MobilePhoneNumber,1,(PATINDEX('%[^0-9]%',MobilePhoneNumber))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](MobilePhoneNumber)),(PATINDEX('%[^0-9]%',MobilePhoneNumber))+2,(LEN(MobilePhoneNumber)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](MobilePhoneNumber)),2,LEN(MobilePhoneNumber)-1)
		END
		WHERE MobilePhoneNumber IS NOT NULL AND REPLACE(MobilePhoneNumber,' ','') <> ''      

	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
	
END
