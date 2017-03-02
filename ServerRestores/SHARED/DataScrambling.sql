USE [tempdb]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID(N'[tempdb].[dbo].[FN_ScrambleName]', 'FN') IS NOT NULL
	SET NOEXEC ON;
GO
CREATE FUNCTION [dbo].[FN_ScrambleName] (@Name VARCHAR(255), @IsFullName BIT) RETURNS VARCHAR(255) AS BEGIN RETURN (NULL); END;
GO
SET NOEXEC OFF;
GO
ALTER FUNCTION [dbo].[FN_ScrambleName] (@Name VARCHAR(255), @IsFullName BIT)
RETURNS VARCHAR(255)
AS
BEGIN
	DECLARE @Forenames VARCHAR(255);
	IF @IsFullName = 1
		IF RTRIM(@Name) LIKE '% %' BEGIN
			SET @Forenames = LEFT(@Name, LEN(@Name) - CHARINDEX(' ', REVERSE(RTRIM(@Name))));
			SET @Name = RIGHT(@Name, LEN(@Name + '.') - LEN(@Forenames + '.') - 1);
		END ELSE
			SET @IsFullName = 0;
	SET @Name = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@Name,
		'a', 'd'), 'b', 'q'), 'c', 'f'), 'd', 'w'), 'e', 'r'), 'f', 'e'), 'g', 't'), 'h', 'y'), 'i', 'u'), 'j', 'i'), 'k', 'h'), 'l', 'o'), 'm', 'p'),
		'n', 'a'), 'o', 'g'), 'p', 's'), 'q', 'j'), 'r', 'k'), 's', 'l'), 't', 'c'), 'u', 'x'), 'v', 'n'), 'w', 'v'), 'x', 'm'), 'y', 'z'), 'z', 'b');
	IF @IsFullName = 1
		RETURN (@Forenames + ' ' + STUFF(@Name, 1, 1, UPPER(LEFT(@Name, 1))));
	RETURN (UPPER(LEFT(@Name, LEN(REVERSE(@Name) + '.') - LEN(REVERSE(@Name))))
		+ SUBSTRING(@Name, LEN(REVERSE(@Name) + '.') - LEN(REVERSE(@Name)) + 1, 255));
END;
GO
IF OBJECT_ID(N'[tempdb].[dbo].[FN_ScrambleTelNo]', 'FN') IS NOT NULL
	SET NOEXEC ON;
GO
CREATE FUNCTION [dbo].[FN_ScrambleTelNo] (@TelNo VARCHAR(16)) RETURNS VARCHAR(16) AS BEGIN RETURN (NULL); END;
GO
SET NOEXEC OFF;
GO
ALTER FUNCTION [dbo].[FN_ScrambleTelNo] (@TelNo VARCHAR(16))
RETURNS VARCHAR(16)
AS
BEGIN
	DECLARE @LeadDigit INT;
	SET @LeadDigit = PATINDEX('%[0-9]%', @TelNo);
	IF @LeadDigit > 0 BEGIN
		WHILE @TelNo LIKE '%[0-8]%' SET @TelNo = REPLACE(@TelNo, SUBSTRING(@TelNo, PATINDEX('%[0-8]%', @TelNo), 1), '9');
		SET @TelNo = STUFF(@TelNo, @LeadDigit, 1, '0');
	END;
	RETURN (@TelNo);
END;
GO
USE [$(DbName)]
GO
DECLARE	@Environment VARCHAR(4),
	@DataScramble BIT,
	@DataScrambleName BIT,
	@DataScrambleAddress BIT,
	@EmailAddress VARCHAR(50),
	@AddressLine1 VARCHAR(30),
	@AddressLine2 VARCHAR(30),
	@AddressLine3 VARCHAR(30),
	@AddressLine4 VARCHAR(30),
	@Town VARCHAR(30),
	@County VARCHAR(30),
	@Postcode VARCHAR(8),
	@Country VARCHAR(30);

IF '$(Environment)' = '.'
	SET @Environment = CASE
		WHEN @@SERVERNAME LIKE 'VM[0-9][0-9]%' OR @@SERVERNAME LIKE 'VMTR%' THEN LEFT(@@SERVERNAME, 4)
		WHEN @@SERVERNAME LIKE 'VM%DEV%' OR @@SERVERNAME LIKE 'VM%INT%' THEN 'DEV'
		WHEN @@SERVERNAME LIKE 'LDS%PEF%' OR @@SERVERNAME LIKE 'VM%PEF%' THEN 'PEF'
	END;
ELSE
	SET @Environment = '$(Environment)';
IF @Environment IS NULL
	RAISERROR (N'Could not determine the environment for data scrambling', 11, 1);
ELSE
BEGIN
	PRINT 'Environment = ' + @Environment;
	SELECT	@DataScramble = [DataScramble],
			@DataScrambleName = [DataScrambleName],
			@DataScrambleAddress = [DataScrambleAddress],
			@EmailAddress = [EmailAddress],
			@AddressLine1 = [AddressLine1],
			@AddressLine2 = [AddressLine2],
			@AddressLine3 = [AddressLine3],
			@AddressLine4 = [AddressLine4],
			@Town = [Town],
			@County = [County],
			@Postcode = [Postcode],
			@Country = [Country]
	FROM	[EnviroDataLinkedServer].[EnviroData].[dbo].[DataScrambling]
	WHERE	[Environment] = @Environment;
	IF @DataScramble IS NULL
		RAISERROR (N'''%s'' is not a recognised environment for data scrambling', 11, 1, @Environment);
	ELSE
	BEGIN
		PRINT
		'DataScramble = ' + CAST(@DataScramble AS CHAR(1)) + '
DataScrambleName = ' + CAST(@DataScrambleName AS CHAR(1)) + '
DataScrambleAddress = ' + CAST(@DataScrambleAddress AS CHAR(1)) + '
EmailAddress = ' + @EmailAddress + '
AddressLine1 = ' + @AddressLine1 + '
AddressLine2 = ' + @AddressLine2 + '
AddressLine3 = ' + @AddressLine3 + '
AddressLine4 = ' + @AddressLine4 + '
Town = ' + @Town + '
County = ' + @County + '
Postcode = ' + @Postcode + '
Country = ' + @Country;
	END;
END;
