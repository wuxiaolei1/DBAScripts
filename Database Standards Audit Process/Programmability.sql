-- Programmability
SET NOCOUNT ON

-- Check for select *
SELECT  'Contains Select *' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   REPLACE(sm.definition, ' ', '') LIKE '%select*%'
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

-- Check for @@identity
SELECT  'Contains @@identity' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   REPLACE(sm.definition, ' ', '') LIKE '%@@identity%'
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0
UNION

-- Check for Rules
SELECT  'Contains Rule' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   REPLACE(sm.definition, ' ', '') LIKE '%CreateRule%'
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0
UNION

-- Check for Order By numbering
SELECT  'Contains Order By numbering' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   REPLACE(sm.definition, ' ', '') LIKE '%OrderBy[0-9]%'
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0
UNION

-- Check for GOTO
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

-- Check for no SET NOCOUNT ON
SELECT  'NO SET NOCOUNT ON' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sysobjects so
        JOIN ( SELECT   id
               FROM     syscomments
               WHERE    REPLACE(text, ' ', '') NOT LIKE '%SETNOCOUNTON%'
             ) AS GoodProcs ON so.id = GoodProcs.id
WHERE   so.xtype = 'P'
        AND so.name NOT IN ( 'sp_helpdiagrams', 'sp_upgraddiagrams' )
UNION

-- Check for RECOMPILE
SELECT  'RECOMPILE' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sysobjects so
        RIGHT JOIN ( SELECT id
                     FROM   syscomments
                     WHERE  REPLACE(text, ' ', '') LIKE '%WITHRECOMPILE%'
                   ) AS GoodProcs ON so.id = GoodProcs.id
WHERE   so.xtype = 'P'
        AND so.name NOT IN ( 'sp_helpdiagrams', 'sp_upgraddiagrams' )
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
        AND name <> 'TRG_DDLAudit'
UNION

-- Check for comments
SELECT  'Does not contain comments' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   REPLACE(sm.definition, ' ', '') NOT LIKE '%--%'
        AND REPLACE(sm.definition, ' ', '') NOT LIKE '%/*%*/%'
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0
UNION

--Check for Wild Card Filters
SELECT  'Leading Wild Card Filter' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   ( REPLACE(sm.definition, ' ', '') LIKE '%LIKE''!%%' ESCAPE '!' )
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0
UNION

-- Check for comment block
SELECT  'Does not contain comment block' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   REPLACE(sm.definition, ' ', '') NOT LIKE '%--%CreateProcedure%'
        AND REPLACE(sm.definition, ' ', '') NOT LIKE '%/*%*/%CreateProcedure%'
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0
UNION

-- Set Isolation Level
SELECT  'Sets Isolation Level' AS ProblemDescription ,
        SCHEMA_NAME(so.uid) + '.' + so.name AS ProblemItem
FROM    sys.sql_modules sm
        INNER JOIN sys.sysobjects so ON sm.object_id = so.id
                                        AND so.type = 'P'
WHERE   REPLACE(sm.definition, ' ', '') LIKE '%SETTRANSACTIONISOLATIONLEVEL%'
        AND OBJECTPROPERTY(so.Id, N'IsMSSHIPPED') = 0

-- Check against exceptions already existing
EXCEPT
SELECT  ProblemDescription ,
        ProblemItem
FROM    SystemsHelpDesk.dbo.DBAStandardsExceptions
WHERE   dbname = DB_NAME()
