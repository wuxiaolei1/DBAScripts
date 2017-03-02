
SELECT STUFF(sql, 1, 4, 'REVOKE') sql FROM (
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
--ORDER BY 
--	OBJECT_SCHEMA_NAME(major_id),
--	OBJECT_NAME(major_id),
--	USER_NAME(grantee_principal_id)
) x WHERE sql LIKE 'DENY%' ORDER BY sql