---------------------------------------
-- Stored Procedure sp_hexadecimal
---------------------------------------
 
USE master
GO
IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
    DROP PROCEDURE sp_hexadecimal
GO
CREATE PROCEDURE sp_hexadecimal
    @binvalue varbinary(256),
    @hexvalue varchar (514) OUTPUT
AS
    DECLARE @charvalue varchar (514)
    DECLARE @i int
    DECLARE @length int
    DECLARE @hexstring char(16)
    SELECT @charvalue = '0x'
    SELECT @i = 1
    SELECT @length = DATALENGTH (@binvalue)
    SELECT @hexstring = '0123456789ABCDEF'
    WHILE (@i <= @length)
    BEGIN
        DECLARE @tempint int
        DECLARE @firstint int
        DECLARE @secondint int
        SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
        SELECT @firstint = FLOOR(@tempint/16)
        SELECT @secondint = @tempint - (@firstint*16)
        SELECT @charvalue = @charvalue +
        SUBSTRING(@hexstring, @firstint+1, 1) +
        SUBSTRING(@hexstring, @secondint+1, 1)
        SELECT @i = @i + 1
    END
 
SELECT @hexvalue = @charvalue
GO




----------------------------------------------
--Login Pre-requisites 
----------------------------------------------
 
USE master
go
SET NOCOUNT ON 
DECLARE @login_name varchar(100)
SET @login_name = '<Login, varchar(100), >'
 
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @login_name AND type IN ('G','U','S'))
BEGIN 
          PRINT 'Please input valid login name'
          RETURN
END
 
DECLARE @login_sid varbinary(85)
SELECT @login_sid = sid FROM sys.server_principals WHERE name = @login_name
 
DECLARE @maxid int
IF OBJECT_ID('tempdb..#db_users') is not null
DROP TABLE #db_users 
SELECT id = identity(int,1,1), sql_cmd = 'SELECT '''+name+''', 
	* FROM ['+name+'].sys.database_principals' INTO #db_users FROM sys.sysdatabases
 
SELECT @maxid = @@ROWCOUNT
 
 
---------------------------------------------
--Retrieve hashed password and hashed sid 
---------------------------------------------
IF EXISTS (SELECT * FROM sys.server_principals WHERE type = 'S' and name = @login_name )
BEGIN 
          DECLARE @PWD_varbinary  varbinary (256)
          SET @PWD_varbinary = CAST( LOGINPROPERTY( @login_name, 'PasswordHash' ) AS varbinary (256) )
 
          DECLARE @SID_string varchar (514)
          DECLARE @PWD_string  varchar (514)
 
          EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT
          EXEC sp_hexadecimal @login_sid,     @SID_string OUT
END
--select @SID_string
--select @PWD_string
 
----------------------------------------------
--Login Properties
----------------------------------------------
PRINT '----------------------------------------------'
PRINT '--SET Login Properties'
PRINT '----------------------------------------------'
 
DECLARE @login_sqlcmd varchar(1000)
SET @login_sqlcmd = ''
SELECT @login_sqlcmd = '-- LOGIN ['+@login_name+'] IS '+case is_disabled WHEN 1 THEN 'DISABLED' ELSE 'ENABLED' 
	END FROM  sys.server_principals WHERE name = @login_name
 
 
IF EXISTS (SELECT * FROM sys.sql_logins WHERE name = @login_name)
BEGIN 
          SELECT @login_sqlcmd = @login_sqlcmd+ char(10)+'CREATE LOGIN '+ QUOTENAME(@login_name)+' 
				WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', 
				DEFAULT_DATABASE = ['+default_database_name+'], DEFAULT_LANGUAGE = ['+default_language_name+']' 
				FROM sys.server_principals WHERE name = @login_name
          SELECT @login_sqlcmd = @login_sqlcmd + ', CHECK_POLICY' + CASE is_policy_checked 
				WHEN 0 THEN '=OFF' ELSE '=ON' END FROM sys.sql_logins WHERE name = @login_name
          SELECT @login_sqlcmd = @login_sqlcmd + ', CHECK_EXPIRATION' + CASE is_expiration_checked 
				WHEN 0 THEN '=OFF' ELSE '=ON' END FROM sys.sql_logins WHERE name = @login_name
          SELECT @login_sqlcmd = @login_sqlcmd+ char(10)+'ALTER LOGIN ['+@login_name+'] 
				WITH DEFAULT_DATABASE = ['+default_database_name+'], 
				DEFAULT_LANGUAGE = ['+default_language_name+']' FROM sys.server_principals WHERE name = @login_name
END
ELSE
BEGIN 
          SELECT @login_sqlcmd = @login_sqlcmd+ char(10)+'CREATE LOGIN ' + QUOTENAME( @login_name ) + ' 
				FROM WINDOWS WITH DEFAULT_DATABASE = [' + default_database_name + ']' 
				FROM sys.server_principals WHERE name = @login_name
END
 
PRINT @login_sqlcmd 









USE master
GO
IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
    DROP PROCEDURE sp_hexadecimal
GO