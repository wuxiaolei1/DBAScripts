-- Lists the jobs that were running within a specified time window
-- (as long as the duration was more than 0 seconds)

USE [PerformanceDataWarehouse]
GO

DECLARE @StartTime DATETIME = '2015-06-20T08:00:00.000'
DECLARE @EndTime DATETIME = '2015-06-20T20:00:00.000'

SELECT *
FROM (
	SELECT DISTINCT [server], [jobname] FROM [JobStats].[StepHistoryRecord]
	WHERE [RunDateTime] >= DATEADD(DAY, -1, @StartTime)
			AND [RunDateTime] < @EndTime
) j
WHERE [JobStats].[GetJobVisSegment] (j.[server], j.[jobname], @StartTime, @EndTime) > 0
ORDER BY [server], [jobname]