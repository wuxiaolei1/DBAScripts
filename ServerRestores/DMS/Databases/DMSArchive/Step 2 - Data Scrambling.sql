:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
PRINT 'Step 2 - Scramble Data - DMSArchive'

USE DMSArchive
GO

SET XACT_ABORT ON ;

DECLARE @Email VARCHAR(50)
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
SET @Email = 'thisisadummyemail@notstepchange.co.na'
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
SET @AddressLine2 = null
SET @City = 'Leeds'
SET @State = 'Yorkshire'
SET @Zip = 'LS2 8NG'
SET @Environment = $(Environment)
SET @DataRowCount = 0
SET @DataScrambleName = 1
SET @DataScrambleAddress = 1

--Read the specific settings if available...
SELECT	@Email = EDV.Email
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
	
		--TABLE: dbo.client_phone
		UPDATE  dbo.client_phone
		SET     area_code = CASE  
		WHEN PATINDEX('%[^0-9]%',area_code)  =1 THEN SUBSTRING(area_code,1,(PATINDEX('%[^0-9]%',area_code))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](area_code)),(PATINDEX('%[^0-9]%',area_code))+2,(LEN(area_code)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](area_code)),2,LEN(area_code)-1)
		END
		WHERE area_code IS NOT NULL AND REPLACE(area_code,' ','') <> ''     
		
		UPDATE  dbo.client_phone
		SET     phone_number = CASE  
		WHEN PATINDEX('%[^0-9]%',phone_number)  =1 THEN SUBSTRING(phone_number,1,(PATINDEX('%[^0-9]%',phone_number))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](phone_number)),(PATINDEX('%[^0-9]%',phone_number))+2,(LEN(phone_number)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](phone_number)),2,LEN(phone_number)-1)
		END
		WHERE phone_number IS NOT NULL AND REPLACE(phone_number,' ','') <> ''  
		
		UPDATE  dbo.client_phone
		SET     extension = CASE  
		WHEN PATINDEX('%[^0-9]%',extension)  =1 THEN SUBSTRING(extension,1,(PATINDEX('%[^0-9]%',extension))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](extension)),(PATINDEX('%[^0-9]%',extension))+2,(LEN(extension)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](extension)),2,LEN(extension)-1)
		END
		WHERE extension IS NOT NULL AND REPLACE(extension,' ','') <> ''   
		
		--TABLE: dbo.person
		UPDATE	dbo.person SET
		home_email = CASE WHEN home_email IS NOT NULL OR home_email <> '' THEN @Email END,
		work_email = CASE WHEN work_email IS NOT NULL OR work_email <> '' THEN @Email END
		
		--TABLE: dbo.employer
		UPDATE  dbo.employer
		SET     phone = CASE  
		WHEN PATINDEX('%[^0-9]%',phone)  =1 THEN SUBSTRING(phone,1,(PATINDEX('%[^0-9]%',phone))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](phone)),(PATINDEX('%[^0-9]%',phone))+2,(LEN(phone)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](phone)),2,LEN(phone)-1)
		END
		WHERE phone IS NOT NULL AND REPLACE(phone,' ','') <> ''  
		
		UPDATE  dbo.employer
		SET     fax = CASE  
		WHEN PATINDEX('%[^0-9]%',fax)  =1 THEN SUBSTRING(fax,1,(PATINDEX('%[^0-9]%',fax))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](fax)),(PATINDEX('%[^0-9]%',fax))+2,(LEN(fax)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](fax)),2,LEN(fax)-1)
		END
		WHERE fax IS NOT NULL AND REPLACE(fax,' ','') <> ''  
		
		--TABLE: dbo.LocationDefaults
		UPDATE	dbo.LocationDefaults
		SET		Directions = @LocationDirections
		WHERE	ISNULL(Directions,'') <> ''

		--TABLE: dbo.creditor_address
		UPDATE	dbo.creditor_address
		SET		email = @CreditorAddressEmail
		WHERE	ISNULL(email,'') <> ''
		
		-- CREDITORS

		--TABLE: dbo.phone
		UPDATE  dbo.phone
		SET     area_code = CASE  
		WHEN PATINDEX('%[^0-9]%',area_code)  =1 THEN SUBSTRING(area_code,1,(PATINDEX('%[^0-9]%',area_code))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](area_code)),(PATINDEX('%[^0-9]%',area_code))+2,(LEN(area_code)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](area_code)),2,LEN(area_code)-1)
		END
		WHERE type = 'CR' AND area_code IS NOT NULL AND REPLACE(area_code,' ','') <> ''  
		
		UPDATE  dbo.phone
		SET     phone_number = CASE  
		WHEN PATINDEX('%[^0-9]%',phone_number)  =1 THEN SUBSTRING(phone_number,1,(PATINDEX('%[^0-9]%',phone_number))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](phone_number)),(PATINDEX('%[^0-9]%',phone_number))+2,(LEN(phone_number)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](phone_number)),2,LEN(phone_number)-1)
		END
		WHERE type = 'CR' AND phone_number IS NOT NULL AND REPLACE(phone_number,' ','') <> ''  
		
		UPDATE  dbo.phone
		SET     extension = CASE  
		WHEN PATINDEX('%[^0-9]%',extension)  =1 THEN SUBSTRING(extension,1,(PATINDEX('%[^0-9]%',extension))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](extension)),(PATINDEX('%[^0-9]%',extension))+2,(LEN(extension)))
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](extension)),2,LEN(extension)-1)
		END
		WHERE type = 'CR' AND extension IS NOT NULL AND REPLACE(extension,' ','') <> ''   


		-- INTERNAL EMAIL ADDRESES...
		UPDATE dbo.system_codes
		SET value = @Email
		WHERE value LIKE '%@%'

-- Scramble Client Names if required
		IF  @DataScrambleName = 1
		BEGIN
			BEGIN TRAN UpdateNames
				
			--TABLE: dbo.person
			UPDATE	dbo.person SET
			last_name = CASE WHEN last_name IS NOT NULL OR last_name <> '' THEN [tempdb].[dbo].[FN_ScrambleName](last_name,0) END,
			maiden_name = CASE WHEN maiden_name IS NOT NULL OR maiden_name <> '' THEN [tempdb].[dbo].[FN_ScrambleName](maiden_name,0) END

			--TABLE: dbo.collection_aging_work_file
			UPDATE cawf
			SET cawf.client_name = UPPER(p.last_name + ', ' + p.first_name)
			FROM dbo.collection_aging_work_file cawf
			JOIN dbo.person p
			ON cawf.client_id  = p.client_id
			WHERE	ISNULL(client_name,'') <> ''

			--TABLE: dbo.collection_work_file
			UPDATE cwf
			SET cwf.client_name = UPPER(p.last_name + ', ' + p.first_name)
			FROM dbo.collection_work_file cwf
			JOIN dbo.person p
			ON cwf.client_id  = p.client_id
			WHERE	ISNULL(client_name,'') <> ''

			--TABLE: dbo.client_statement_hdr
			Update cshdr
			SET client_name =  p.first_name + ' ' + p.last_name
			FROM dbo.client_statement_hdr cshdr
			JOIN dbo.person p
			ON cshdr.client_id  = p.client_id
			WHERE	ISNULL(client_name,'') <> ''

			--TABLE: dbo.direct_debits
			Update dbo.direct_debits
			SET account_name = upper([tempdb].[dbo].[FN_ScrambleName](account_name,1))
			WHERE	ISNULL(account_name,'') <> ''

			COMMIT TRAN UpdateNames
		END

-- Scramble Client Addresses if required
		IF  @DataScrambleAddress = 1
		BEGIN
			--TABLE: dbo.client_address
			UPDATE dbo.client_address SET
			address1 = CASE WHEN address1 IS NOT NULL OR address1 <> '' THEN @AddressLine1 END, 
			address2 = CASE WHEN address2 IS NOT NULL OR address2 <> '' THEN @AddressLine2 END, 
			city = CASE WHEN city IS NOT NULL OR city <> '' THEN @city END, 
			[state] = CASE WHEN [state] IS NOT NULL OR [state] <> '' THEN @state END

			--TABLE: dbo.client_refund_assignment
			UPDATE dbo.client_refund_assignment SET
			address1 = CASE WHEN address1 IS NOT NULL OR address1 <> '' THEN @AddressLine1 END, 
			address2 = CASE WHEN address2 IS NOT NULL OR address2 <> '' THEN @AddressLine2 END, 
			city = CASE WHEN city IS NOT NULL OR city <> '' THEN @city END, 
			[state] = CASE WHEN [state] IS NOT NULL OR [state] <> '' THEN @state END, 
			country = CASE WHEN country IS NOT NULL OR country <> '' THEN @CountryCode END

			--TABLE: dbo.client_statement_hdr
			UPDATE dbo.client_statement_hdr SET
			address_1 = CASE WHEN address_1 IS NOT NULL OR address_1 <> '' THEN @AddressLine1 END, 
			address_2 = CASE WHEN address_2 IS NOT NULL OR address_2 <> '' THEN @AddressLine2 END, 
			address_3 = CASE WHEN address_3 IS NOT NULL OR address_3 <> '' THEN @city END
  
  
			-- CREDITORS
			
			--TABLE: dbo.creditor
			UPDATE dbo.creditor SET
			zip_sort_key = CASE WHEN zip_sort_key IS NOT NULL OR zip_sort_key <> '' THEN @zip END
			
			--TABLE: dbo.creditor_address
			UPDATE dbo.creditor_address SET
			address1 = CASE WHEN address1 IS NOT NULL OR address1 <> '' THEN @AddressLine1 END,
			address2 = CASE WHEN address2 IS NOT NULL OR address2 <> '' THEN @AddressLine2 END, 
			city = CASE WHEN city IS NOT NULL OR city <> '' THEN @city END,            
			[state] = CASE WHEN [state] IS NOT NULL OR [state] <> '' THEN @state END,           
			zip = CASE WHEN zip IS NOT NULL OR zip <> '' THEN @zip END,
			country = CASE WHEN country IS NOT NULL OR country <> '' THEN @CountryCode END
  
            --TABLE: dbo.creditors_post_merge
			UPDATE dbo.creditors_post_merge SET
            merged_address1 = CASE WHEN merged_address1 IS NOT NULL OR merged_address1 <> '' THEN @AddressLine1 END,
			merged_address2 = CASE WHEN merged_address2 IS NOT NULL OR merged_address2 <> '' THEN @AddressLine2 END, 
			merged_city = CASE WHEN merged_city IS NOT NULL OR merged_city <> '' THEN @city END,            
			merged_State = CASE WHEN merged_State IS NOT NULL OR merged_State <> '' THEN @state END,           
			merged_Zip = CASE WHEN merged_Zip IS NOT NULL OR merged_Zip <> '' THEN @zip END

			          
		END


	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
END
