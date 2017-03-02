-- SQL 2005 - space used by tables/indexes

-- shows index and data space including totals
WITH    table_space_usage ( SCHEMA_NAME, table_name, index_name, used, reserved, ind_rows, tbl_rows )
          AS ( SELECT   s.NAME,
                        o.NAME,
                        COALESCE(i.NAME, 'HEAP'),
                        p.used_page_count * 8,
                        p.reserved_page_count * 8,
                        p.ROW_count,
                        CASE WHEN i.index_id IN ( 0, 1 ) then p.ROW_count
                             ELSE 0
                        END
               FROM     sys.dm_db_partition_stats p
                        INNER JOIN sys.objects o ON o.OBJECT_ID = p.OBJECT_ID
                        INNER JOIN sys.schemas s ON s.SCHEMA_ID = o.SCHEMA_ID
                        LEFT JOIN sys.indexes i ON i.OBJECT_ID = p.OBJECT_ID
                                                   AND i.index_id = p.index_id
               WHERE    o.type_desc = 'USER_TABLE'
                        AND o.is_ms_shipped = 0
             )
    SELECT  t.SCHEMA_NAME,
            t.TABLE_name,
            t.index_name,
            SUM(t.used) AS Used_in_KB,
            SUM(t.reserved) AS Reserved_in_KB,
            CASE GROUPING(t.index_name)
              WHEN 0 THEN SUM(t.ind_rows)
              ELSE SUM(t.tbl_rows)
            END AS ROWS
    FROM    table_space_usage AS t
    GROUP BY t.SCHEMA_NAME,
            t.TABLE_name,
            t.index_name
            WITH rollup
    ORDER BY GROUPING(t.SCHEMA_NAME),
            t.SCHEMA_NAME,
            GROUPING(t.TABLE_name),
            t.TABLE_name,
            GROUPING(t.index_name),
            t.index_name
