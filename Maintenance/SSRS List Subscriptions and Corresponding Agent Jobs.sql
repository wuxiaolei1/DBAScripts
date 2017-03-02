SELECT
            b.name AS JobName
            , e.name
            , e.path
            , d.description
            , a.SubscriptionID
            , laststatus
            , eventtype
            , LastRunTime
            , date_created
            , date_modified
    FROM ReportServer.dbo.ReportSchedule a JOIN msdb.dbo.sysjobs b
            ON a.ScheduleID = b.name
            JOIN ReportServer.dbo.ReportSchedule c
            ON b.name = c.ScheduleID
            JOIN ReportServer.dbo.Subscriptions d
            ON c.SubscriptionID = d.SubscriptionID
            JOIN ReportServer.dbo.Catalog e
            ON d.report_oid = e.itemid
    WHERE b.name LIKE '%-%-%-%-%'