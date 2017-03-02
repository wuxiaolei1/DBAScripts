select 
    i.name as IndexName, 
    o.name as TableName, 
    ic.key_ordinal as ColumnOrder,
    ic.is_included_column as IsIncluded, 
    co.[name] as ColumnName
from sys.indexes i 
join sys.objects o on i.object_id = o.object_id
join sys.index_columns ic on ic.object_id = i.object_id 
    and ic.index_id = i.index_id
join sys.columns co on co.object_id = i.object_id 
    and co.column_id = ic.column_id
where i.[type] = 2 
and i.is_unique = 0 
and i.is_primary_key = 0
and o.[type] = 'U'
--and ic.is_included_column = 0
order by o.[name], i.[name], ic.is_included_column, ic.key_ordinal
;
