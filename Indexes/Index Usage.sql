SELECT b.name,* FROM sys.dm_db_index_usage_stats a
Join sys.indexes b on
a.[object_id] = b.[object_id] AND a.[Index_id] = b.[Index_id] 
WHERE database_id = DB_ID('DMS')
and a.object_id = OBJECT_ID('dbo.payment_history');