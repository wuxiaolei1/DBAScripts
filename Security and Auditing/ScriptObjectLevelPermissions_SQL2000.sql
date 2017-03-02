/* Desc:	This should be used to script out permissions on all non system
 *			objects. Ensure that the script is run from within the database
 *			you want to script the permissions from.
 * Author:	Tom Braham
 * Created:	01/06/2009
 *
 */
 
-- Select for SQL 2000 as no dmv is available
SELECT	(CASE sysprotects.protecttype
				WHEN 204 THEN 'GRANT'
				WHEN 205 THEN 'GRANT'
				WHEN 206 THEN 'DENY'
			   END )  
		+ SPACE(1) 
		+ CASE sysprotects.action
			   WHEN 26  THEN 'REFERENCES'
			   WHEN 178 THEN 'CREATE FUNCTION'
			   WHEN 193 THEN 'SELECT'
			   WHEN 195 THEN 'INSERT'
			   WHEN 196 THEN 'DELETE'
			   WHEN 197 THEN 'UPDATE'
			   WHEN 198 THEN 'CREATE TABLE'
			   WHEN 203 THEN 'CREATE DATABASE'
			   WHEN 207 THEN 'CREATE VIEW'
			   WHEN 222 THEN 'CREATE PROCEDURE'
			   WHEN 224 THEN 'EXECUTE'
			   WHEN 228 THEN 'BACKUP DATABASE'
			   WHEN 233 THEN 'CREATE DEFAULT'
			   WHEN 235 THEN 'BACKUP LOG'
			   WHEN 236 THEN 'CREATE RULE'
		  END 
		  + ' ON [' 
		  + USER_NAME(sysobjects.uid) + '].[' + sysobjects.[name] 
		  + '] TO ' 
		  + USER_NAME(syspermissions.grantee)
		  + CASE sysprotects.protecttype
			   WHEN 204 THEN ' WITH GRANT OPTION'
			   ELSE ''
			END   as 'SQL'
FROM	
	syspermissions
	INNER JOIN sysobjects 
		ON syspermissions.id = sysobjects.id
	INNER JOIN sysprotects 
		ON syspermissions.grantee = sysprotects.uid 
		AND sysobjects.id = sysprotects.id
WHERE	
	sysobjects.xtype <> 'S'
ORDER BY 
	USER_NAME(sysobjects.uid),
	sysobjects.[name],
	USER_NAME(syspermissions.grantee) 



        
        
   