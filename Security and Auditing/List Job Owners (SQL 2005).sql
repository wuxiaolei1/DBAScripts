USE		msdb
GO
SELECT	sos.originating_server
		,sj.name
		,CASE WHEN sxl.name IS NULL
			THEN 'NOT KNOWN'
			ELSE sxl.name
		END AS owner
FROM	dbo.sysjobs sj
LEFT JOIN
		dbo.sysoriginatingservers sos
ON		sj.originating_server_id = sos.originating_server_id
LEFT JOIN
		master.sys.syslogins sxl
ON		sj.owner_sid = sxl.sid
GO
