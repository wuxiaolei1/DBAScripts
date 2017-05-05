SET NOCOUNT ON

-- Check for select *
SELECT  'Contains Select *' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   REPLACE(sm.definition, ' ', '') LIKE '%select *%'
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0
UNION

-- Check for @@error
SELECT  'Contains @@error' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   REPLACE(sm.definition, ' ', '') LIKE '%@@error%'
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0
UNION

-- Check for Rules
SELECT  'Contains Rule' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   REPLACE(sm.definition, ' ', '') LIKE '%Create Rule%'
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0
UNION

-- Check for Order By numbering
SELECT  'Contains Order By numbering' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   REPLACE(sm.definition, ' ', '') LIKE '%Order by [0-9]%'
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0
UNION

-- Tables with no Primary Key
SELECT  'No Primary Key' AS ProblemDescription ,
        su.name + '.' + AllTables.Name AS ProblemItem
FROM    ( SELECT    Name ,
                    id ,
                    uid
          FROM      sysobjects
          WHERE     xtype = 'U'
        ) AS AllTables
        INNER JOIN sysusers su ON AllTables.uid = su.uid
        LEFT JOIN ( SELECT  parent_obj
                    FROM    sysobjects
                    WHERE   xtype = 'PK'
                  ) AS PrimaryKeys ON AllTables.id = PrimaryKeys.parent_obj
WHERE   PrimaryKeys.parent_obj IS NULL
UNION

-- Check for Order By numbering
SELECT  'Contains GOTO' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   REPLACE(sm.definition, ' ', '') LIKE '%GOTO%'
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0
UNION

-- Check for Stored Procedure prefix SP_
SELECT  'SP_ prefix' AS ProblemDescription ,
        SPECIFIC_SCHEMA + '.' + SPECIFIC_NAME AS ProblemItem
FROM    INFORMATION_SCHEMA.ROUTINES
WHERE   SPECIFIC_NAME LIKE 'sp[_]%'
        AND SPECIFIC_NAME NOT LIKE '%diagram%'
UNION

-- Check for invalid/deprecated data types
SELECT  'Deprecated Data Type' AS ProblemDescription ,
        SCHEMA_NAME(o.uid) + '.' + o.Name + '.' + col.name AS ProblemItem
FROM    syscolumns col
        INNER JOIN sysobjects o ON col.id = o.id
        INNER JOIN systypes ON col.xtype = systypes.xtype
WHERE   o.type = 'U'
        AND OBJECTPROPERTY(o.id, N'IsMSShipped') = 0
        AND systypes.name IN ( 'text', 'ntext', 'image' )
UNION

-- Check for no SET NOCOUNT ON
SELECT  'SET NOCOUNT ON' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sysobjects so
        LEFT JOIN ( SELECT  id
                    FROM    syscomments
                    WHERE   text LIKE '%SET NOCOUNT ON%'
                  ) AS GoodProcs ON so.id = GoodProcs.id
WHERE   so.xtype = 'P'
        AND GoodProcs.id IS NULL
        AND so.name NOT IN ( 'sp_helpdiagrams', 'sp_upgraddiagrams' )
UNION

-- Check for RECOMPILE
SELECT  'RECOMPILE' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sysobjects so
        LEFT JOIN ( SELECT  id
                    FROM    syscomments
                    WHERE   text LIKE '%WITH RECOMPILE%'
                  ) AS GoodProcs ON so.id = GoodProcs.id
WHERE   so.xtype = 'P'
        AND GoodProcs.id IS NULL
        AND so.name NOT IN ( 'sp_helpdiagrams', 'sp_upgraddiagrams' )
UNION

-- Invalid Characters in column/table/view Name
SELECT  'Invalid Character in Column Name' AS ProblemDescription ,
        Table_Name + '.' + Column_Name AS ProblemItem
FROM    Information_Schema.Columns
WHERE   Column_Name LIKE '%[^a-z]%'
UNION
SELECT  'Invalid Character in Table/View Name' AS ProblemDescription ,
        Table_Name AS ProblemItem
FROM    Information_Schema.Tables
WHERE   Table_Name LIKE '%[^a-z]%'
UNION

-- Check for column singular name
SELECT  'Column Name not singular' AS ProblemDescription ,
        Table_Name + '.' + Column_Name AS ProblemItem
FROM    Information_Schema.Columns
WHERE   Column_Name LIKE '%s'
UNION

-- Check Table Name Prefix
SELECT  'tbl in Table Name' AS ProblemDescription ,
        TABLE_SCHEMA + '.' + TABLE_NAME AS ProblemItem
FROM    INFORMATION_SCHEMA.TABLES
WHERE   TABLE_TYPE = 'BASE TABLE'
        AND TABLE_NAME LIKE 'tbl%'
UNION

-- Check Function Name Prefix
SELECT  'fn in Function Name' AS ProblemDescription ,
        B.name + '.' + A.name AS ProblemItem
FROM    sysobjects A ,
        sysusers B
WHERE   A.type IN ( 'FN', 'TF' )
        AND B.uid = OBJECTPROPERTY(A.id, 'ownerid')
        AND A.name LIKE 'fn%'
UNION
SELECT  'fn in Function Name' AS ProblemDescription ,
        B.name + '.' + A.name AS ProblemItem
FROM    sysobjects A ,
        sys.schemas B
WHERE   A.type IN ( 'FN', 'TF' )
        AND B.schema_id = A.uid
        AND A.name LIKE 'fn%'
UNION

-- Check for table/view plural name
SELECT  'Table Name/view non plural' AS ProblemDescription ,
        Table_Name AS ProblemItem
FROM    Information_Schema.Tables
WHERE   Table_Name NOT LIKE '%s'
UNION

-- Check for Default Constraint Names
SELECT  'Default Constraint Name' AS ProblemDescription ,
        CONSTRAINT_SCHEMA + '.' + CONSTRAINT_NAME AS ProblemItem
FROM    INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE
WHERE   CONSTRAINT_NAME LIKE '%[_][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]'
        AND TABLE_NAME <> 'sysdiagrams'
UNION

-- Check for Triggers
SELECT  'Trigger exists' AS ProblemDescription ,
        name AS ProblemItem
FROM    sys.triggers
WHERE   is_ms_shipped = 0
UNION

-- Check for comments
SELECT  'Does not contain comments' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   ( REPLACE(sm.definition, ' ', '') NOT LIKE '%--%'
          OR REPLACE(sm.definition, ' ', '') NOT LIKE '%/*%*/%'
        )
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0
UNION

--Check for Wild Card Filters
SELECT  'Leading Wild Card Filter' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   ( REPLACE(sm.definition, ' ', '') LIKE '%LIKE ''!%'
          ESCAPE '!' )
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0
UNION

-- Check for comment block *** Not working properly ***
SELECT  'Does not contain comment block' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   ( (sm.definition NOT LIKE '%--%Create Procedure%')
          OR (sm.definition NOT LIKE '%/*%*/%Create Procedure%')
        )
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0

