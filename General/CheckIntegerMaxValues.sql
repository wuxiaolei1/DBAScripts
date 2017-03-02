DECLARE @SQL nvarchar(4000)

SET @SQL = 'USE [?];

			IF ''[?]'' NOT IN (''[master]'', ''[model]'', 
      
	                            ''[msdb]'', ''[tempdb]'',
								''[SystemsHelpDesk]'')
		Begin
       WITH  CTE_1
        AS (SELECT OBJECT_NAME(a.Object_id) AS table_name,
                a.Name AS columnname,
                CONVERT(BIGINT, ISNULL(a.last_value, 0)) AS last_value,
                CASE WHEN b.name = ''tinyint'' THEN 255
                     WHEN b.name = ''smallint'' THEN 32767
                     WHEN b.name = ''int'' THEN 2147483647
                     WHEN b.name = ''bigint'' THEN 9223372036854775807
                END AS dt_value,
				db_name() as DatabaseName
              FROM sys.identity_columns a
              INNER JOIN sys.types AS b
              ON
                a.system_type_id = b.system_type_id
           ),
      CTE_2
        AS (SELECT *,
                CONVERT(INTEGER, ((CONVERT(FLOAT, last_value)
                / CONVERT(FLOAT, dt_value)) * 100)) AS "Percent"
              FROM CTE_1
			  WHERE last_value > 0
           )
  SELECT *
    FROM CTE_2
    WHERE [Percent] > 90 -- 90%, threshold
	AND NOT (@@SERVERNAME=''VMTFSPRO1DBA02'' AND DatabaseName=''EA_CoreArchitectureModel'' AND table_name=''t_image'' AND columnname=''ImageID'')
	Order By [Percent] desc;
	END'
	
EXEC sp_MSForEachDB @SQL