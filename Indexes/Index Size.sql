SELECT
    --i.name                  AS IndexName,
    ((SUM(s.used_page_count)* 8)/1024)   AS IndexSizeKB
FROM sys.dm_db_partition_stats  AS s 
JOIN sys.indexes                AS i
ON s.[object_id] = i.[object_id] AND s.index_id = i.index_id
WHERE s.[object_id] = object_id('dbo.payment_history')
--GROUP BY i.name
--ORDER BY i.name