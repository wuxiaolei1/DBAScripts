:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
PRINT 'Step 2 - Scramble Data - CCCSIFACE'

USE CCCSIFACE
GO

DECLARE @ClientEmail VARCHAR(255)
		, @ClientPhoneNo VARCHAR(16)
		, @ClientSMSNo VARCHAR(16)
		, @DataScramble BIT
		, @Environment VARCHAR(50)
		, @HouseNameOrNumber VARCHAR(50)
		, @AddressLine1 VARCHAR(100)
		, @AddressLine2 VARCHAR(100)
		, @PostTown VARCHAR(100)
		, @Region VARCHAR(100)
		, @PostCode VARCHAR(8)
		, @Comma VARCHAR(5)
		, @DataRowCount INT
		, @DataScrambleName INT -- 1 = Yes Scramble Name
		, @DataScrambleAddress INT -- 1 = Yes Scramble Address

--SET DEFAULTS...
SET @ClientEmail = 'thisisadummyemail@notstepchange.co.na'
 --'no-reply@stepchange.org'
SET @ClientPhoneNo = '09999999999'
SET @ClientSMSNo = '09999999999'
SET @DataScramble = 1
SET @Environment = $(Environment)
SET @HouseNameOrNumber = 'StepChange - Systems Department'
SET @AddressLine1 = 'Wade House'
SET @AddressLine2 = 'Merrion Centre'
SET @PostTown = 'Leeds'
SET @Region = 'Yorkshire'
SET @PostCode = 'LS2 8NG'
SET @DataRowCount = 0
SET @DataScrambleName = 1
SET @DataScrambleAddress = 1
SET @Comma = ', '

--Read the specific settings if available...
SELECT  @ClientEmail = EDV.ClientEmail
        , @ClientPhoneNo = EDV.TelNo
        , @ClientSMSNo = EDV.MobileNo
        , @DataScramble = EDV.DataScramble
		, @HouseNameOrNumber = ISNULL(EDV.HouseNameOrNumber,'')
		, @AddressLine1 = ISNULL(EDV.AddressLine1,'')
		, @AddressLine2 = ISNULL(EDV.AddressLine2,'')
		, @PostTown = ISNULL(EDV.PostTown,'')
		, @Region = ISNULL(EDV.Region,'')
		, @PostCode = ISNULL( EDV.PostCode,'')
		, @DataScrambleName = EDV.DataScrambleName
		, @DataScrambleAddress = EDV.DataScrambleAddress	

FROM    EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE   Environment = @Environment

SET @DataRowCount = @@Rowcount

--Perform Updates
IF @DataScramble = 1 
    BEGIN
		--TABLE: dbo.DMP_TBL_CLIENT_MASTER
        UPDATE  dbo.DMP_TBL_CLIENT_MASTER SET
        CLIENT_EMAIL = CASE WHEN CLIENT_EMAIL IS NOT NULL OR CLIENT_EMAIL <> '' THEN @ClientEmail END

		UPDATE  dbo.DMP_TBL_CLIENT_MASTER
		SET     SMS_NUM = CASE  
		WHEN PATINDEX('%[^0-9]%',SMS_NUM)  =1 THEN SUBSTRING(SMS_NUM,1,(PATINDEX('%[^0-9]%',SMS_NUM))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](SMS_NUM)),(PATINDEX('%[^0-9]%',SMS_NUM))+2,(LEN(SMS_NUM)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](SMS_NUM)),2,LEN(SMS_NUM)-1)
		END
		WHERE SMS_NUM IS NOT NULL AND REPLACE(SMS_NUM,' ','') <> ''

		UPDATE  dbo.DMP_TBL_CLIENT_MASTER
		SET     CLIENT_PHONE = CASE  
		WHEN PATINDEX('%[^0-9]%',CLIENT_PHONE)  =1 THEN SUBSTRING(CLIENT_PHONE,1,(PATINDEX('%[^0-9]%',CLIENT_PHONE))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](CLIENT_PHONE)),(PATINDEX('%[^0-9]%',CLIENT_PHONE))+2,(LEN(CLIENT_PHONE)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](CLIENT_PHONE)),2,LEN(CLIENT_PHONE)-1)
		END
		WHERE CLIENT_PHONE IS NOT NULL AND REPLACE(CLIENT_PHONE,' ','') <> ''
						
		--TABLE: dbo.DMP_TBL_DCS_UPLOAD_COMM
		UPDATE  dbo.DMP_TBL_DCS_UPLOAD_COMM
		SET     PHONE_NUM = CASE  
		WHEN PATINDEX('%[^0-9]%',PHONE_NUM)  =1 THEN SUBSTRING(PHONE_NUM,1,(PATINDEX('%[^0-9]%',PHONE_NUM))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](PHONE_NUM)),(PATINDEX('%[^0-9]%',PHONE_NUM))+2,(LEN(PHONE_NUM)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](PHONE_NUM)),2,LEN(PHONE_NUM)-1)
		END
		WHERE PHONE_NUM IS NOT NULL AND REPLACE(PHONE_NUM,' ','') <> ''

		--TABLE: dbo.INT_DMP_CHANGE
        UPDATE  INT_DMP_CHANGE SET
        EMAIL_ADD = CASE WHEN EMAIL_ADD IS NOT NULL OR EMAIL_ADD <> '' THEN @ClientEmail END
		
		UPDATE  dbo.INT_DMP_CHANGE
		SET     SMS_NUM = CASE  
		WHEN PATINDEX('%[^0-9]%',SMS_NUM)  =1 THEN SUBSTRING(SMS_NUM,1,(PATINDEX('%[^0-9]%',SMS_NUM))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](SMS_NUM)),(PATINDEX('%[^0-9]%',SMS_NUM))+2,(LEN(SMS_NUM)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](SMS_NUM)),2,LEN(SMS_NUM)-1)
		END
		WHERE SMS_NUM IS NOT NULL AND REPLACE(SMS_NUM,' ','') <> ''

		UPDATE  dbo.INT_DMP_CHANGE
		SET     PHONE_NUM = CASE  
		WHEN PATINDEX('%[^0-9]%',PHONE_NUM)  =1 THEN SUBSTRING(PHONE_NUM,1,(PATINDEX('%[^0-9]%',PHONE_NUM))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](PHONE_NUM)),(PATINDEX('%[^0-9]%',PHONE_NUM))+2,(LEN(PHONE_NUM)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](PHONE_NUM)),2,LEN(PHONE_NUM)-1)
		END
		WHERE PHONE_NUM IS NOT NULL AND REPLACE(PHONE_NUM,' ','') <> ''

-- Scramble Client Names if required
		IF  @DataScrambleName = 1
		BEGIN
			BEGIN TRAN UpdateNames

			--TABLE: dbo.DMP_TBL_CLIENT_MASTER
			UPDATE  dbo.DMP_TBL_CLIENT_MASTER SET
			CLIENT_NAME = CASE WHEN CLIENT_NAME  IS NOT NULL OR CLIENT_NAME <> '' THEN [tempdb].[dbo].[FN_ScrambleName](CLIENT_NAME,1) END

			--TABLE: dbo.INT_DMP_CHANGE
			UPDATE  INT_DMP_CHANGE SET
			CLIENT_NAME = CASE WHEN CLIENT_NAME IS NOT NULL OR CLIENT_NAME <> '' THEN [tempdb].[dbo].[FN_ScrambleName](CLIENT_NAME,1) END

			COMMIT TRAN UpdateNames
		END

-- Scramble Client Addresses if required
		IF  @DataScrambleAddress = 1
		BEGIN
			--TABLE: dbo.DMP_TBL_CLIENT_MASTER
			UPDATE  dbo.DMP_TBL_CLIENT_MASTER SET
			CLIENT_ADDRESS =  CASE WHEN CLIENT_ADDRESS  IS NOT NULL OR CLIENT_ADDRESS <> '' THEN @HouseNameOrNumber + @Comma + @AddressLine1 + @Comma + @AddressLine2 + @Comma + @PostTown + @Region + @Comma + @PostCode END
			
			--TABLE: dbo.INT_DMP_CHANGE
			UPDATE  INT_DMP_CHANGE SET
			[ADDRESS] =  CASE WHEN [ADDRESS]  IS NOT NULL OR [ADDRESS] <> '' THEN @HouseNameOrNumber + @Comma + @AddressLine1 + @Comma + @AddressLine2 + @Comma + @PostTown + @Region + @Comma + @PostCode END
		END

		-- Raise an error if no rows were selected from the Environment Data Values Table
		IF @DataRowCount = 0
		RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
	END