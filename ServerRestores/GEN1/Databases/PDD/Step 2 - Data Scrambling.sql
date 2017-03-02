:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
Print 'Step 2 - Scramble Data - PDD'
USE PDD
GO

DECLARE @ClientEmail varchar(64)
		, @TelNo varchar(32)
		, @DataScramble bit
		, @FaxNo VARCHAR(16)
		, @AddressLine1 varchar(60)
		, @AddressLine2 varchar(60)
		, @AddressLine3 varchar(60)
		, @Town varchar(60)
		, @County varchar(60)
		, @PostCode varchar(60)
		, @Country varchar(60)
		, @Environment VARCHAR(30)
		, @DataRowCount INT
		, @DataScrambleAddress INT -- 1 = Yes Scramble Address

--SET DEFAULTS...
SET @ClientEmail = 'thisisadummyemail@notstepchange.co.na' --'no-reply@stepchange.org'
SET @TelNo = '09999999999'
SET @FaxNo = '09999999999'
SET @DataScramble = 1
SET @AddressLine1 = 'StepChange - Systems Department'
SET @AddressLine2 = 'Wade House'
SET @AddressLine3 = 'Merrion Centre'
SET @Town = 'Leeds'
SET @County = 'Yorkshire'
SET @PostCode = 'LS2 8NG'
SET @Country = 'UK'
SET @Environment = $(Environment)
SET @DataRowCount = 0
SET @DataScrambleAddress = 1

--Read the specific settings if available...
SELECT	@ClientEmail = EDV.ClientEmail
		, @TelNo = EDV.TelNo
		, @FaxNo = EDV.FaxNo
		, @DataScramble = EDV.DataScramble
		, @AddressLine1 = EDV.HouseNameorNumber
		, @AddressLine2 = EDV.AddressLine1
		, @AddressLine3 = EDV.AddressLine2
		, @Town = EDV.PostTown
		, @County = EDV.Region
		, @Country = EDV.Country
		, @PostCode = EDV.PostCode
		, @DataScrambleAddress = EDV.DataScrambleAddress

FROM EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE Environment = @Environment

SET @DataRowCount = @@Rowcount

--Perform Updates
IF @DataScramble = 1
BEGIN
	-- Scramble Client Address if required
	IF  @DataScrambleAddress = 1
	BEGIN
		--TABLE: dbo.DdeContactUpdateFailure
		UPDATE dbo.DdeContactUpdateFailure SET
		Street1 =  CASE WHEN Street1 IS NOT NULL OR Street1 <> '' THEN @AddressLine1 END,
		Street2 =  CASE WHEN Street2 IS NOT NULL OR Street2 <> '' THEN @AddressLine2 END,
		Street3 =  CASE WHEN Street3 IS NOT NULL OR Street3 <> '' THEN @AddressLine3 END,
		Town =  CASE WHEN Town IS NOT NULL OR Town <> '' THEN @Town END,
		County =  CASE WHEN County IS NOT NULL OR County <> '' THEN @County END,
		Country =  CASE WHEN Country IS NOT NULL OR Country <> '' THEN @Country END
	END
	
	--TABLE: dbo.DdeContactUpdateFailure
	UPDATE dbo.DdeContactUpdateFailure SET
	Email = CASE WHEN Email IS NOT NULL OR Email <> '' THEN @ClientEmail END
    
	UPDATE  dbo.DdeContactUpdateFailure
	SET     Telephone = CASE  
	WHEN PATINDEX('%[^0-9]%',Telephone)  =1 THEN SUBSTRING(Telephone,1,(PATINDEX('%[^0-9]%',Telephone))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](Telephone)),(PATINDEX('%[^0-9]%',Telephone))+2,(LEN(Telephone)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](Telephone)),2,LEN(Telephone)-1)
	END
	WHERE Telephone IS NOT NULL AND REPLACE(Telephone,' ','') <> ''
	    
	UPDATE  dbo.DdeContactUpdateFailure
	SET     Fax = CASE  
	WHEN PATINDEX('%[^0-9]%',Fax)  =1 THEN SUBSTRING(Fax,1,(PATINDEX('%[^0-9]%',Fax))) + '0'
	+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](Fax)),(PATINDEX('%[^0-9]%',Fax))+2,(LEN(Fax)))
	ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](Fax)),2,LEN(Fax)-1)
	END
	WHERE Fax IS NOT NULL AND REPLACE(Fax,' ','') <> ''

	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
			
END

