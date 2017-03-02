	
SELECT	session_id
        ,DB_NAME(er.database_id) as [Database]
        ,er.status
        ,wait_type
        ,SUBSTRING (qt.text, er.statement_start_offset/2,
				(CASE
					WHEN er.statement_end_offset = -1 
						THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
					ELSE er.statement_end_offset 
				 END - er.statement_start_offset)/2) as [Statement]
        ,qt.text
        ,start_time
    FROM sys.dm_exec_requests er
    CROSS APPLY sys.dm_exec_sql_text(er.sql_handle)as qt
    WHERE session_id = 62        
    AND session_id NOT IN (@@SPID)   	