SELECT
OBJECT_NAME(i.object_id) AS TableName
,i.name AS TableIndexName
,phystat.avg_fragmentation_in_percent
,page_count
FROM
sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') phystat 
inner JOIN sys.indexes i
ON i.object_id = phystat.object_id
AND i.index_id = phystat.index_id WHERE phystat.avg_fragmentation_in_percent > 10
and Page_Count > 128 --128 Pages = Approx 1MB
Order by 3 desc