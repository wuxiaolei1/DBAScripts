DECLARE @sql NVARCHAR(4000)

SET @sql = '
USE ?; 

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = ''Audit'' 
                 AND  TABLE_NAME = ''DDLEvents'')
BEGIN
	PRINT @@servername 
	Print db_name()
	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = ''DDLEvents'' 
           AND  COLUMN_NAME = ''ChangeReference'')
	BEGIN
		ALTER TABLE Audit.DDLEvents ADD
		ChangeReference varchar(256) NULL
	END	
END
'

EXEC sp_MSForEachDB @sql;

SET @sql = '
USE ?; 

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = ''Audit'' 
                 AND  TABLE_NAME = ''DDLEvents'')
BEGIN

	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = ''DDLEvents'' 
           AND  COLUMN_NAME = ''ChangeReference'')
	BEGIN
		Update Audit.DDLEvents
		set ChangeReference = ''Historic''
	END	
END
'
EXEC sp_MSForEachDB @sql;