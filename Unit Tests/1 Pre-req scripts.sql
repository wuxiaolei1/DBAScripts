CREATE SCHEMA [Admin];
GO


GO

CREATE VIEW [Admin].[DependencyToFrom]
AS
    SELECT  [s1].[name] AS [from_schema] ,
            [o1].[name] AS [from_table] ,
            [s2].[name] AS [to_schema] ,
            [o2].[name] AS [to_table]
    FROM    [sys].[foreign_keys] [fk]
    INNER JOIN [sys].[objects] [o1] ON [fk].[parent_object_id] = [o1].[object_id]
    INNER JOIN [sys].[schemas] [s1] ON [o1].[schema_id] = [s1].[schema_id]
    INNER JOIN [sys].[objects] [o2] ON [fk].[referenced_object_id] = [o2].[object_id]
    INNER JOIN [sys].[schemas] [s2] ON [o2].[schema_id] = [s2].[schema_id]
    WHERE   NOT ([s1].[name] = [s2].[name]
                 AND [o1].[name] = [o2].[name]
                );

GO





CREATE VIEW [Admin].[DatabaseObjects]
AS
    SELECT  [rtn].[objType] ,
            CONVERT(VARCHAR(255), [rtn].[objName]) AS [Expr1]
    FROM    (
             SELECT 'database' AS [objType] ,
                    'Client' AS [objName]
             UNION
             SELECT [sch].[ObjType] ,
                    [sch].[ObjName]
             FROM   (
                     SELECT TOP (100) PERCENT
                            'schema' AS [ObjType] ,
                            [CATALOG_NAME] + '.' + [SCHEMA_NAME] AS [ObjName] ,
                            [CATALOG_NAME] ,
                            [SCHEMA_NAME] ,
                            [SCHEMA_OWNER] ,
                            [DEFAULT_CHARACTER_SET_CATALOG] ,
                            [DEFAULT_CHARACTER_SET_SCHEMA] ,
                            [DEFAULT_CHARACTER_SET_NAME]
                     FROM   [INFORMATION_SCHEMA].[SCHEMATA]
                     WHERE  ([SCHEMA_OWNER] = 'dbo')
                            AND ([SCHEMA_NAME] <> 'dbo')
                     ORDER BY [CATALOG_NAME] ,
                            [SCHEMA_NAME]
                    ) AS [sch]
             UNION
             SELECT [TB].[objType] ,
                    [TB].[objName]
             FROM   (
                     SELECT TOP (100) PERCENT
                            LOWER(REPLACE([TABLE_TYPE], 'base ', '')) AS [objType] ,
                            [TABLE_CATALOG] + '.' + [TABLE_SCHEMA] + '.'
                            + [TABLE_NAME] AS [objName]
                     FROM   [INFORMATION_SCHEMA].[TABLES]
                     WHERE  ([TABLE_NAME] NOT LIKE 'sys%')
                     ORDER BY [TABLE_CATALOG] ,
                            [TABLE_SCHEMA] ,
                            [TABLE_NAME]
                    ) AS [TB]
             UNION
             SELECT [col].[ObjType] ,
                    [col].[ObjName]
             FROM   (
                     SELECT TOP (100) PERCENT
                            'Column' AS [ObjType] ,
                            [TABLE_CATALOG] + '.' + [TABLE_SCHEMA] + '.'
                            + [TABLE_NAME] + '.' + [COLUMN_NAME] AS [ObjName]
                     FROM   [INFORMATION_SCHEMA].[COLUMNS]
                     ORDER BY [TABLE_CATALOG] ,
                            [TABLE_SCHEMA] ,
                            [TABLE_NAME] ,
                            [COLUMN_NAME] ,
                            [ORDINAL_POSITION]
                    ) AS [col]
             UNION
             SELECT [cc].[ObjType] ,
                    [cc].[ObjName]
             FROM   (
                     SELECT TOP (100) PERCENT
                            'Check Constraint' AS [ObjType] ,
                            [a].[TABLE_CATALOG] + '.' + [a].[TABLE_SCHEMA] + '.'
                            + [a].[TABLE_NAME] + '.' + [a].[CONSTRAINT_NAME] AS [ObjName]
                     FROM   [INFORMATION_SCHEMA].[CONSTRAINT_TABLE_USAGE] AS [a]
                     INNER JOIN [INFORMATION_SCHEMA].[CHECK_CONSTRAINTS] AS [b] ON [a].[CONSTRAINT_CATALOG] = [b].[CONSTRAINT_CATALOG]
                                                              AND [a].[CONSTRAINT_SCHEMA] = [b].[CONSTRAINT_SCHEMA]
                                                              AND [a].[CONSTRAINT_NAME] = [b].[CONSTRAINT_NAME]
                     ORDER BY [a].[TABLE_CATALOG] ,
                            [a].[TABLE_SCHEMA] ,
                            [a].[TABLE_NAME] ,
                            [a].[CONSTRAINT_NAME]
                    ) AS [cc]
            ) AS [rtn]
    WHERE   ([rtn].[objName] NOT LIKE 'Client.Admin%')
            AND ([rtn].[objName] NOT LIKE 'Client.dbo.sysdiagrams%');




GO



CREATE VIEW [Admin].[DatabasePermissions]
AS
    SELECT DISTINCT
            [rp].[name] ,
            [RoleType] = [rp].[type_desc] ,
            [PermissionType] = [pm].[class_desc] ,
            [pm].[permission_name] ,
            [pm].[state_desc] ,
            [ObjectType] = CASE WHEN [obj].[type_desc] IS NULL
                                   OR [obj].[type_desc] = 'SYSTEM_TABLE'
                              THEN [pm].[class_desc]
                              ELSE [obj].[type_desc]
                         END ,
            [ObjectName] = ISNULL([ss].[name], OBJECT_NAME([pm].[major_id]))
    FROM    [sys].[database_principals] [rp]
    INNER JOIN [sys].[database_permissions] [pm] ON [pm].[grantee_principal_id] = [rp].[principal_id]
    LEFT JOIN [sys].[schemas] [ss] ON [pm].[major_id] = [ss].[schema_id]
    LEFT JOIN [sys].[objects] [obj] ON [pm].[major_id] = [obj].[object_id]
    WHERE   [rp].[type_desc] = 'DATABASE_ROLE'
            AND [pm].[class_desc] <> 'DATABASE'; 





GO
GO



CREATE VIEW [Admin].[DependencyLevel]
AS
    WITH    [fk_tables]
              AS (
                  SELECT    [s1].[name] AS [from_schema] ,
                            [o1].[name] AS [from_table] ,
                            [s2].[name] AS [to_schema] ,
                            [o2].[name] AS [to_table]
                  FROM      [sys].[foreign_keys] [fk]
                  INNER    JOIN [sys].[objects] [o1] ON [fk].[parent_object_id] = [o1].[object_id]
                  INNER    JOIN [sys].[schemas] [s1] ON [o1].[schema_id] = [s1].[schema_id]
                  INNER    JOIN [sys].[objects] [o2] ON [fk].[referenced_object_id] = [o2].[object_id]
                  INNER    JOIN [sys].[schemas] [s2] ON [o2].[schema_id] = [s2].[schema_id]    
    /*For the purposes of finding dependency hierarchy       
        we're not worried about self-referencing tables*/
                  WHERE     NOT ([s1].[name] = [s2].[name]
                                 AND [o1].[name] = [o2].[name]
                                )
                 ),
            [ordered_tables]
              AS (
                  SELECT    [s].[name] AS [schemaName] ,
                            [t].[name] AS [tableName] ,
                            0 AS [Level]
                  FROM      (
                             SELECT [name] ,
                                    [object_id] ,
                                    [principal_id] ,
                                    [schema_id] ,
                                    [parent_object_id] ,
                                    [type] ,
                                    [type_desc] ,
                                    [create_date] ,
                                    [modify_date] ,
                                    [is_ms_shipped] ,
                                    [is_published] ,
                                    [is_schema_published] ,
                                    [lob_data_space_id] ,
                                    [filestream_data_space_id] ,
                                    [max_column_id_used] ,
                                    [lock_on_bulk_load] ,
                                    [uses_ansi_nulls] ,
                                    [is_replicated] ,
                                    [has_replication_filter] ,
                                    [is_merge_published] ,
                                    [is_sync_tran_subscribed] ,
                                    [has_unchecked_assembly_data] ,
                                    [text_in_row_limit] ,
                                    [large_value_types_out_of_row] ,
                                    [is_tracked_by_cdc] ,
                                    [lock_escalation] ,
                                    [lock_escalation_desc] ,
                                    [is_filetable] ,
                                    [is_memory_optimized] ,
                                    [durability] ,
                                    [durability_desc] ,
                                    [temporal_type] ,
                                    [temporal_type_desc] ,
                                    [history_table_id] ,
                                    [is_remote_data_archive_enabled] ,
                                    [is_external]
                             FROM   [sys].[tables]
                             WHERE  [name] <> 'sysdiagrams'
                            ) [t]
                  INNER    JOIN [sys].[schemas] [s] ON [t].[schema_id] = [s].[schema_id]
                  LEFT    OUTER JOIN [fk_tables] [fk] ON [s].[name] = [fk].[from_schema]
                                                     AND [t].[name] = [fk].[from_table]
                  WHERE     [fk].[from_schema] IS NULL
                  UNION    ALL
                  SELECT    [fk].[from_schema] ,
                            [fk].[from_table] ,
                            [ot].[Level] + 1
                  FROM      [fk_tables] [fk]
                  INNER    JOIN [ordered_tables] [ot] ON [fk].[to_schema] = [ot].[schemaName]
                                                     AND [fk].[to_table] = [ot].[tableName]
                 )
    SELECT    DISTINCT
            [ot].[schemaName] ,
            [ot].[tableName] ,
            [ot].[Level]
    FROM    [ordered_tables] [ot]
    INNER    JOIN (
                   SELECT   [ordered_tables].[schemaName] ,
                            [ordered_tables].[tableName] ,
                            MAX([ordered_tables].[Level]) [maxLevel]
                   FROM     [ordered_tables]
                   GROUP BY [ordered_tables].[schemaName] ,
                            [ordered_tables].[tableName]
                  ) [mx] ON [ot].[schemaName] = [mx].[schemaName]
                          AND [ot].[tableName] = [mx].[tableName]
                          AND [mx].[maxLevel] = [ot].[Level];







GO



CREATE VIEW [Admin].[TestCoverage]
AS
    SELECT  [rtn].[TestSchema] ,
            [rtn].[TestName] ,
            [rtn].[TestType] ,
            [rtn].[ExpectedErrorNumber] ,
            CASE WHEN [tests].[SPECIFIC_NAME] IS NULL THEN 0
                 ELSE 1
            END AS [TestCreated]
    FROM    (
             SELECT [col].[TABLE_SCHEMA] + 'Tests' [TestSchema] ,
                    'testNull ' + [col].[TABLE_NAME] + [col].[COLUMN_NAME] AS [TestName] ,
                    'NULL Test' AS [TestType] ,
                    CASE WHEN [col].[IS_NULLABLE] = 'NO' THEN 515
                         ELSE 0
                    END AS [ExpectedErrorNumber]
             FROM   [INFORMATION_SCHEMA].[COLUMNS] [col]
             LEFT OUTER JOIN (
                              SELECT    [TABLE_SCHEMA] ,
                                        [TABLE_NAME] ,
                                        [COLUMN_NAME]
                              FROM      [INFORMATION_SCHEMA].[COLUMNS]
                              WHERE     COLUMNPROPERTY(OBJECT_ID([TABLE_SCHEMA]
                                                              + '.'
                                                              + [TABLE_NAME]),
                                                       [COLUMN_NAME],
                                                       'IsIdentity') = 1
                             ) [idc] ON [col].[TABLE_SCHEMA] = [idc].[TABLE_SCHEMA]
                                      AND [col].[TABLE_NAME] = [idc].[TABLE_NAME]
                                      AND [col].[COLUMN_NAME] = [idc].[COLUMN_NAME]
             WHERE  [idc].[COLUMN_NAME] IS NULL
                    AND [col].[TABLE_NAME] NOT LIKE '%SysDiagrams%'
                    AND [col].[TABLE_SCHEMA] <> 'tsqlt'
                    AND [col].[TABLE_SCHEMA] <> 'dbo'
                    AND [col].[TABLE_SCHEMA] <> 'sys'
             UNION
             SELECT [TABLE_SCHEMA] + 'Tests' [TestSchema] ,
                    'testCheck ' + [TABLE_NAME] + [CONSTRAINT_NAME] AS [TestName] ,
                    CASE [CONSTRAINT_TYPE]
                      WHEN 'Check' THEN 'Failed Check'
                      WHEN 'FOREIGN KEY' THEN 'Missing Foreign Key'
                      ELSE 'Unknown'
                    END AS [TestType] ,
                    CASE [CONSTRAINT_TYPE]
                      WHEN 'Check' THEN 547
                      WHEN 'FOREIGN KEY' THEN 547
                      ELSE NULL
                    END AS [ExpectedErrorNumber]
             FROM   [INFORMATION_SCHEMA].[TABLE_CONSTRAINTS]
             WHERE  [CONSTRAINT_TYPE] <> 'PRIMARY KEY'
                    AND [TABLE_NAME] NOT LIKE '%SysDiagrams%'
                    AND [TABLE_SCHEMA] <> 'tsqlt'
                    AND [TABLE_SCHEMA] <> 'dbo'
                    AND [TABLE_SCHEMA] <> 'sys'
             UNION
             SELECT SCHEMA_NAME([so].[schema_id]) + 'Tests' [TestSchema] ,
                    'testDuplicate ' + [so].[name] + [si].[name] AS [TestName] ,
                    'Duplicate Test' AS [TestType] ,
                    2601 AS [ExpectedErrorNumber]
             FROM   [sys].[indexes] [si]
             INNER JOIN [sys].[objects] [so] ON [si].[object_id] = [so].[object_id]
             WHERE  [si].[is_unique] = 1
                    AND [si].[type] <> 1
                    AND [so].[name] NOT LIKE '%SysDiagrams%'
                    AND SCHEMA_NAME([so].[schema_id]) <> 'tsqlt'
                    AND SCHEMA_NAME([so].[schema_id]) <> 'dbo'
                    AND SCHEMA_NAME([so].[schema_id]) <> 'sys'
             UNION
             SELECT [SPECIFIC_SCHEMA] + 'Tests' [TestSchema] ,
                    'testSuccess ' + [SPECIFIC_NAME] AS [TestName] ,
                    'Successful Run' AS [TestType] ,
                    0 AS [ExpectedErrorNumber]
             FROM   [INFORMATION_SCHEMA].[ROUTINES]
             WHERE  [SPECIFIC_NAME] NOT LIKE 'Test %'
                    AND [SPECIFIC_NAME] NOT LIKE '%SysDiagrams%'
                    AND [ROUTINE_SCHEMA] <> 'tsqlt'
                    AND [ROUTINE_SCHEMA] <> 'dbo'
                    AND [ROUTINE_SCHEMA] <> 'sys'
             UNION
             SELECT [col].[TABLE_SCHEMA] + 'Tests' [TestSchema] ,
                    'testCharLength ' + [col].[TABLE_NAME]
                    + [col].[COLUMN_NAME] AS [TestName] ,
                    'Character Length Test' AS [TestType] ,
                    CASE WHEN [col].[CHARACTER_MAXIMUM_LENGTH] IS NOT NULL
                         THEN 8152
                         ELSE NULL
                    END AS [ExpectedErrorNumber]
             FROM   [INFORMATION_SCHEMA].[COLUMNS] [col]
             WHERE  [col].[TABLE_SCHEMA] <> 'tsqlt'
                    AND [col].[TABLE_SCHEMA] <> 'dbo'
                    AND [col].[TABLE_SCHEMA] <> 'sys'
                    AND [col].[CHARACTER_MAXIMUM_LENGTH] IS NOT NULL
             UNION
             SELECT [col].[TABLE_SCHEMA] + 'Tests' [TestSchema] ,
                    'testDefaultValue ' + [col].[TABLE_NAME]
                    + [col].[COLUMN_NAME] AS [TestName] ,
                    'Default Value Test' AS [TestType] ,
                    CASE WHEN [col].[COLUMN_DEFAULT] IS NOT NULL THEN 0
                         ELSE NULL
                    END AS [ExpectedErrorNumber]
             FROM   [INFORMATION_SCHEMA].[COLUMNS] [col]
             WHERE  [col].[TABLE_SCHEMA] <> 'tsqlt'
                    AND [col].[TABLE_SCHEMA] <> 'dbo'
                    AND [col].[TABLE_SCHEMA] <> 'sys'
                    AND [col].[COLUMN_DEFAULT] IS NOT NULL
            ) [rtn]
    LEFT OUTER JOIN (
                     SELECT [SPECIFIC_SCHEMA] ,
                            [SPECIFIC_NAME]
                     FROM   [INFORMATION_SCHEMA].[ROUTINES]
                     WHERE  [SPECIFIC_NAME] LIKE 'Test %'
                    ) [tests] ON [rtn].[TestSchema] = [tests].[SPECIFIC_SCHEMA]
                               AND [rtn].[TestName] = [tests].[SPECIFIC_NAME];









GO

