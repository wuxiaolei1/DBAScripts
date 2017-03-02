select qs.sql_handle, qs.execution_count
     , qs.total_elapsed_time, qs.last_elapsed_time
     , qs.min_elapsed_time, qs.max_elapsed_time
     , qs.total_clr_time, qs.last_clr_time
     , qs.min_clr_time, qs.max_clr_time
  from sys.dm_exec_query_stats as qs
 cross apply sys.dm_exec_sql_text(qs.sql_handle) as st


select s.*
			, t.text
FROM sys.dm_exec_query_stats s
cross apply sys.dm_exec_sql_text(s.plan_handle) t