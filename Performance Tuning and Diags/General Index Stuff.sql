-- View all indexes in database
select * from sys.indexes

-- View the physical stats on a table (fragmentation, fill level etc)
-- For example to view how many rows per page use: record_count/page_count as RowsPerPage
select * 
from sys.indexes i
join sys.dm_db_index_physical_stats(DB_ID('DCSLive'),
																		Object_ID('dbo.tblClient'),
																			null,null,'DETAILED') as ips
ON i.index_id = ips.index_id 
where i.object_id = object_id(N'dbo.tblClient')

-- It is always preferable to create an index an a column which has a high selectivity (close to 1 the better)
-- examples
-- Only a few distinct values
select count(distinct SexTypeID) as DistinctColValues
,count(SexTypeID) as NumberofRows
,(cast(count(distinct SexTypeID) as Decimal) / cast(count(SexTypeID) as Decimal)) as Selectivity
From dbo.tblClientPerson

-- Unique Columns
select count(distinct AssociateID) as DistinctColValues
,count(AssociateID) as NumberofRows
,(cast(count(distinct AssociateID) as Decimal) / cast(count(AssociateID) as Decimal)) as Selectivity
From dbo.tblClientPerson

/*
To recreate all indexes on a table use create Index with Drop_Existing on the clustered index
or use Alter Index Rebuild, if you use drop and create index it will rebuild the non-clustered 
indexes twice
*/

-- Index details on a specific table
exec sp_helpindex tblClientPerson