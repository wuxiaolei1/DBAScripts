USE		msdb
GO
SELECT	sj.originating_server
		,sj.name
		,CASE WHEN sxl.name IS NULL
			THEN 'NOT KNOWN'
			ELSE sxl.name
		END AS owner
FROM	dbo.sysjobs sj
LEFT JOIN
		master.dbo.sysxlogins sxl
ON		sj.owner_sid = sxl.sid
GO
