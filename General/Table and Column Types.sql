SELECT  s.name AS SchemaName
       ,t.name AS TableName
       ,c.name AS ColumnName
       ,c.max_length AS ColumnLength
       ,ty.name AS ColumnType
FROM    sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.types AS ty ON c.system_type_id = ty.system_type_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE   ty.name = 'uniqueidentifier'   
--WHERE   (ty.name = 'uniqueidentifier' OR ty.name = 'int') AND (c.name = 'ClientID' OR c.name = 'ClientIDInteger') -- 35 Columns
GROUP BY s.name
       ,t.name
       ,c.name
       ,c.max_length
       ,ty.name
ORDER BY t.name