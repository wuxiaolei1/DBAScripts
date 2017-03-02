SELECT 	[NAME] 
FROM 	dbo.syslogins
WHERE 	sysadmin = 1		
		AND	[NAME] <> 'CCCSNT\Systems DBA Team'
		AND [NAME] <> 'sa'
		AND RIGHT ([NAME], 5) <> 'MSSQL'
		AND RIGHT ([NAME], 5) <> 'Agent'
		AND RIGHT ([NAME], 11) <> 'MSSQLSERVER'
		
