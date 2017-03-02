USE [master]
GO

SELECT	CAST(SERVERPROPERTY('MachineName') AS NVARCHAR(128)) + '.' + NAME AS 'Name',
		NAME AS 'Actual DB Name',
		RTRIM(REPLACE(LEFT(@@VERSION,26), '  ', ' ')) AS 'SQL Product',
		SERVERPROPERTY ('edition') AS 'Edition',
		SERVERPROPERTY('productversion') AS 'Version',
		'Database' AS 'Class',
		ISNULL(SERVERPROPERTY('InstanceName'),'Default') AS 'Instance',
		CASE 
			WHEN @@VERSION LIKE '%X86%' THEN '32-bit'
			WHEN @@VERSION LIKE '%X64%' THEN '64-bit'
			ELSE 'Unknown'
		END as 'SQL Version',
		SERVERPROPERTY ('productlevel') AS 'Product Level',
		cmptlevel AS 'Compatibility Level',
		@@VERSION AS ServerOSAndSQLVersion
FROM sysdatabases
WHERE [name] NOT IN (
				'master',
				'model',
				'tempdb',
				'msdb',
				'SystemsHelpDesk',
				'distribution')
order by 1
