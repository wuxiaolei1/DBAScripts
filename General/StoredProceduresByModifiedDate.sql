--Checks date for stored procedure updates

SELECT  COUNT([object_id]) ,
        CONVERT (DATETIME, CONVERT (VARCHAR, [modify_date], 110))
FROM    [sys].[procedures]
GROUP BY CONVERT (DATETIME, CONVERT (VARCHAR, [modify_date], 110))
ORDER BY CONVERT (DATETIME, CONVERT (VARCHAR, [modify_date], 110)) DESC;

 