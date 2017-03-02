USE [tempdb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N'[tempdb].[dbo].[FN_Replace0To8]', 'FN') IS NOT NULL
	SET NOEXEC ON;
GO
-- STUB
CREATE FUNCTION [dbo].[FN_Replace0To8] (@Number VARCHAR(16)) RETURNS VARCHAR(16) AS BEGIN RETURN (NULL); END;
GO
SET NOEXEC OFF;
GO
-- DEFINITION
ALTER FUNCTION [dbo].[FN_Replace0To8] (@Number VARCHAR(16))
RETURNS VARCHAR(16)
AS
BEGIN
	DECLARE @pos INT;

	WHILE @Number LIKE '%[0-8]%'
	BEGIN
		SET @pos = (SELECT PATINDEX('%[0-8]%', @Number));
		SET @Number = (SELECT REPLACE(@Number, SUBSTRING(@Number, @pos, 1), '9'));
	END;

	RETURN (@Number);

END;
GO

IF OBJECT_ID(N'[tempdb].[dbo].[FN_ScrambleName]', 'FN') IS NOT NULL
	SET NOEXEC ON;
GO
-- STUB
CREATE FUNCTION [dbo].[FN_ScrambleName] (@Name VARCHAR(255), @IsFullName BIT) RETURNS VARCHAR(255) AS BEGIN RETURN (NULL); END;
GO
SET NOEXEC OFF;
GO
-- DEFINITION
ALTER FUNCTION [dbo].[FN_ScrambleName] (@Name VARCHAR(255), @IsFullName BIT)
RETURNS VARCHAR(255)
AS 
BEGIN

DECLARE @SpaceIndex INT;
DECLARE @firstname VARCHAR(255);
DECLARE @surname VARCHAR(255);
DECLARE @returnname VARCHAR(255);

IF @IsFullName = 1
BEGIN
	SET @SpaceIndex = CAST((LEN(@name)) AS INT)- (CHARINDEX(' ',(REVERSE(@name))));
	SET @firstname = LEFT(@name,@SpaceIndex);
	SET @surname = RIGHT(@name,(LEN(@name)-@SpaceIndex));
END
ELSE
BEGIN
	SET @surname = @name;
END

-- Scramble 
SET @surname = REPLACE(@surname,'a','d');
SET @surname = REPLACE(@surname,'b','q');
SET @surname = REPLACE(@surname,'c','f');
SET @surname = REPLACE(@surname,'d','w');
SET @surname = REPLACE(@surname,'e','e');
SET @surname = REPLACE(@surname,'f','r');
SET @surname = REPLACE(@surname,'g','t');
SET @surname = REPLACE(@surname,'h','y');
SET @surname = REPLACE(@surname,'i','u');
SET @surname = REPLACE(@surname,'j','i');
SET @surname = REPLACE(@surname,'k','h');
SET @surname = REPLACE(@surname,'l','o');
SET @surname = REPLACE(@surname,'m','p');
SET @surname = REPLACE(@surname,'n','a');
SET @surname = REPLACE(@surname,'o','g');
SET @surname = REPLACE(@surname,'p','s');
SET @surname = REPLACE(@surname,'q','j');
SET @surname = REPLACE(@surname,'r','k');
SET @surname = REPLACE(@surname,'s','l');
SET @surname = REPLACE(@surname,'t','c');
SET @surname = REPLACE(@surname,'u','x');
SET @surname = REPLACE(@surname,'v','v');
SET @surname = REPLACE(@surname,'w','n');
SET @surname = REPLACE(@surname,'x','m');
SET @surname = REPLACE(@surname,'y','z');
SET @surname = REPLACE(@surname,'z','b');

IF LEN(@surname) > 1
BEGIN
	IF @IsFullName = 1
	BEGIN
		SET @surname = UPPER(LEFT(@surname,2)) + RIGHT(@surname,(LEN(@surname)-2));
	END
	ELSE
	BEGIN
  		SET @surname = UPPER(LEFT(@surname,1)) + RIGHT(@surname,(LEN(@surname)-1));
	END  
END
	
IF @IsFullName = 1
BEGIN
	SET @returnname = @firstname + @surname;
END
ELSE
BEGIN
	SET @returnname = @surname;
END;

RETURN(@returnname);

END
 


GO


