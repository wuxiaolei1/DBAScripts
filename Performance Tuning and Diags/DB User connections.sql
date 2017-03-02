CREATE PROCEDURE dbo.DBUserConnections

AS

DECLARE @SAMPLETIME DATETIME

SET @SAMPLETIME = (SELECT GETDATE())

SELECT @SAMPLETIME

SELECT  cntr_value AS ServerUserConnections
		
FROM	sys.[dm_os_performance_counters] A
WHERE	[object_name] = 'SQLServer:General Statistics'
		AND counter_name = 'User Connections'


SELECT	COUNT(spid) AS DDUsers
FROM	master.dbo.sysprocesses
WHERE	dbid = '6' --directdebit
		AND LEFT ([program_name], 20) <> 'Microsoft SQL Server'



SELECT COUNT(spid) AS PDDUsers
FROM	master.dbo.sysprocesses
WHERE	dbid = '8' --pdd
		AND LEFT ([program_name], 20) <> 'Microsoft SQL Server'

SELECT	[program_name] AS Program
		,COUNT (spid) AS ProgramUsers
FROM	master.dbo.sysprocesses
WHERE	dbid = '6' --directdebit
		AND LEFT ([program_name], 20) <> 'Microsoft SQL Server'
GROUP BY [program_name]

SELECT	[program_name] AS Program
		,COUNT (spid) AS ProgramUsers
FROM	master.dbo.sysprocesses
WHERE	dbid = '8' --directdebit
		AND LEFT ([program_name], 20) <> 'Microsoft SQL Server'
GROUP BY [program_name]


