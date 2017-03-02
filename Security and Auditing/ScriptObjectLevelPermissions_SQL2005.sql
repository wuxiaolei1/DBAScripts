/* Desc:	This should be used to script out permissions on all non system
 *			objects. Ensure that the script is run from within the database
 *			you want to script the permissions from.
 * Author:	Tom Braham
 * Created:	01/06/2009
 *
 */
 
-- Seperate select for SQL 2005 so that DMV can be used
-- ensuring all permissions are scripted
SELECT  sql = CASE state 
				WHEN 'G' THEN 'GRANT'
				WHEN 'D' THEN 'DENY'
				WHEN 'R' THEN 'REVOKE'
				WHEN 'W' THEN 'GRANT'
			   END
		+ SPACE(1)
		+ permission_name + ' ON ['
		+ OBJECT_SCHEMA_NAME(major_id) + '].[' + OBJECT_NAME(major_id)
		+ '] TO [' + USER_NAME(grantee_principal_id)
		+ CASE WHEN state = 'W' THEN '] WITH GRANT OPTION' 
			   ELSE ']'
		  END
FROM    
	sys.database_permissions 
WHERE   
	OBJECT_SCHEMA_NAME(major_id) <> 'SYS'
ORDER BY 
	OBJECT_SCHEMA_NAME(major_id),
	OBJECT_NAME(major_id),
	USER_NAME(grantee_principal_id)



	
	
	
	

        
        
        
   