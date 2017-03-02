
/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 3 - Update Application Settings .sql"

--- */
--:on error exit
Print 'Step 3 Update Application Settings - DMS'

/*--- Licence Key Update ---*/

USE DMS
GO

DECLARE @class_id VARCHAR (50)
DECLARE @clsid VARCHAR (50)
DECLARE @cls_mode CHAR (1)

SELECT @class_id = class_id, @clsid = clsid, @cls_mode = cls_mode
FROM [EnviroDataLinkedServer].[EnviroData].[dbo].[DMSLicenceKeys]
WHERE ServerName = @@SERVERNAME

DELETE FROM dbo.external_objects
INSERT INTO dbo.external_objects (class_id, clsid, cls_mode)
VALUES (@class_id, @clsid, @cls_mode)
GO




/*--- Linked Server Permissions ---*/
USE DMS
GO
CREATE USER [DMSReader] FOR LOGIN [DMSReader]
exec sp_addrolemember  N'db_datareader', N'DMSReader'
GO

/*----Update DMS Plugin Details---*/
USE DMS
GO
UPDATE	bcr_dropdown_code
SET		value = 'ITApplicationSupport@stepchange.org'
WHERE	type = 'EMAIL'
and		code = 'SEND_TO'