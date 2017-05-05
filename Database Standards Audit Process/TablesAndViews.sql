-- Tables and Views
SET NOCOUNT ON

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

-- Primary Key not prefixed with PK_
SELECT DISTINCT
        'Primary Key not prefixed with PK_' AS ProblemDescription ,
        i.name + '.' + OBJECT_NAME(ic.OBJECT_ID) AS ProblemItem
FROM    sys.indexes AS i
        INNER JOIN sys.index_columns AS ic ON i.OBJECT_ID = ic.OBJECT_ID
                                              AND i.index_id = ic.index_id
WHERE   i.is_primary_key = 1
        AND i.name NOT LIKE 'PK_%'
UNION

-- Check for invalid/deprecated data types
SELECT  'Deprecated Data Type' AS ProblemDescription ,
        SCHEMA_NAME(o.uid) + '.' + o.Name + '.' + col.name AS ProblemItem
FROM    syscolumns col
        INNER JOIN sysobjects o ON col.id = o.id
        INNER JOIN systypes ON col.xtype = systypes.xtype
WHERE   o.type = 'U'
        AND OBJECTPROPERTY(o.id, N'IsMSShipped') = 0
        AND systypes.name IN ( 'text', 'ntext', 'image', 'float' )
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

-- Check for table/view plural name
SELECT  'Table Name/view non plural' AS ProblemDescription ,
        Table_Name AS ProblemItem
FROM    Information_Schema.Tables
WHERE   Table_Name NOT LIKE '%s'
UNION

-- Primary Key not prefixed with PK_
SELECT DISTINCT
        'Primary Key not prefixed with PK_' AS ProblemDescription ,
        i.name + '.' + OBJECT_NAME(ic.OBJECT_ID) AS ProblemItem
FROM    sys.indexes AS i
        INNER JOIN sys.index_columns AS ic ON i.OBJECT_ID = ic.OBJECT_ID
                                              AND i.index_id = ic.index_id
WHERE   i.is_primary_key = 1
        AND i.name NOT LIKE 'PK_%'
UNION

-- Unique Key not prefixed with UQ_
SELECT DISTINCT
        'Unique Key not prefixed with UQ_' AS ProblemDescription ,
        i.name + '.' + OBJECT_NAME(ic.OBJECT_ID) AS ProblemItem
FROM    sys.indexes AS i
        INNER JOIN sys.index_columns AS ic ON i.OBJECT_ID = ic.OBJECT_ID
                                              AND i.index_id = ic.index_id
WHERE   i.is_unique = 1
        AND i.is_primary_key <> 1
        AND i.name NOT LIKE 'UQ_%'
UNION

-- Non-unique index not prefixed with IX_
SELECT DISTINCT
        'Non-unique index not prefixed with IX_' AS ProblemDescription ,
        i.name + '.' + OBJECT_NAME(ic.OBJECT_ID) AS ProblemItem
FROM    sys.indexes AS i
        INNER JOIN sys.index_columns AS ic ON i.OBJECT_ID = ic.OBJECT_ID
                                              AND i.index_id = ic.index_id
WHERE   i.is_unique = 0
        AND i.is_primary_key <> 1
        AND i.name NOT LIKE 'IX_%'
UNION

-- Constraint not named CK_TableName_ColumnName_
SELECT  'Constraint not named CK_TableName_ColumnName' AS ProblemDescription ,
        cc.CONSTRAINT_NAME + '.' + TABLE_NAME + '.' + COLUMN_NAME AS ProblemItem
FROM    INFORMATION_SCHEMA.CHECK_CONSTRAINTS cc
        INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE c ON cc.CONSTRAINT_NAME = c.CONSTRAINT_NAME
WHERE   cc.CONSTRAINT_NAME NOT LIKE 'CK_' + TABLE_NAME + '_' + COLUMN_NAME
        + '%'
UNION

-- Tables with no foreign keys
SELECT DISTINCT
        'No Foreign Keys Exist' AS ProblemDescription ,
        name AS ProblemItem
FROM    sys.tables
WHERE   is_ms_shipped = 0
        AND name NOT IN (
        SELECT  OBJECT_NAME(f.parent_object_id) AS TableName
        FROM    sys.foreign_keys AS f
                INNER JOIN sys.foreign_key_columns AS fc ON f.OBJECT_ID = fc.constraint_object_id )

-- Check against exceptions already existing
EXCEPT
SELECT  ProblemDescription ,
        ProblemItem
FROM    SystemsHelpDesk.dbo.DBAStandardsExceptions
WHERE   dbname = DB_NAME()

   