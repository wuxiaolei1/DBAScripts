
/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 3 - Update Application Settings .sql"

--- */
:on error exit
Print 'Step 3 - Update Application Settings - '

USE DocuTrieve
GO

DECLARE @DBServer NVARCHAR(20)

SET @DBServer = LEFT(@@SERVERNAME, 4) + 'GENPRODBA03'


UPDATE [DocuTrieve].[dbo].[TextReference]
SET Value = '\\ldsfileproapp01\systems\non-live\imaging'
WHERE id = 1

UPDATE [DocuTrieve].[dbo].[TextReference]
SET Value = '\\' + @DBServer + '\DocuTrieve$'
WHERE id = 3

UPDATE [DocuTrieve].[dbo].[TextReference]
SET Value = 'Data Source=' +  LEFT(@@SERVERNAME, 4) + 'DMSPRODBA01;Initial Catalog=DMS;Integrated Security=SSPI;'
WHERE ID = 4

-- N/A