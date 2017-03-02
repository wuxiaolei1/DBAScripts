SELECT
    j.name,
    h.run_status,
    durationHHMMSS = STUFF(STUFF(REPLACE(STR(h.run_duration,7,0),
        ' ','0'),4,0,':'),7,0,':'),
    [start_date] = CONVERT(DATETIME, RTRIM(run_date) + ' '
        + STUFF(STUFF(REPLACE(STR(RTRIM(h.run_time),6,0),
        ' ','0'),3,0,':'),6,0,':'))
FROM
    msdb.dbo.sysjobs AS j
INNER JOIN
    (
        SELECT job_id, instance_id --= MAX(instance_id)
            FROM msdb.dbo.sysjobhistory
            GROUP BY job_id
    ) AS l
    ON j.job_id = l.job_id
INNER JOIN
    msdb.dbo.sysjobhistory AS h
    ON h.job_id = l.job_id
    AND h.instance_id = l.instance_id
	WHERE name = 'APP DEBTREMEDY_LIVE CREATE_DCS_CLIENTS'
ORDER BY
    CONVERT(INT, h.run_duration) DESC,
    [start_date] DESC;

SELECT  sj.name,
    sjh.run_status,
    durationHHMMSS = STUFF(STUFF(REPLACE(STR(sjh.run_duration,7,0),
        ' ','0'),4,0,':'),7,0,':'),
    [start_date] = CONVERT(DATETIME, RTRIM(run_date) + ' '
        + STUFF(STUFF(REPLACE(STR(RTRIM(sjh.run_time),6,0),
        ' ','0'),3,0,':'),6,0,':'))
FROM dbo.sysjobs sj JOIN sysjobhistory sjh ON sj.job_id = sjh.job_id
WHERE name = 'APP DEBTREMEDY_LIVE CREATE_DCS_CLIENTS' AND step_id = 1
ORDER BY run_date desc, run_time desc

