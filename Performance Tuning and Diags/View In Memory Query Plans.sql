select p.query_plan, t.text
from 
sys.dm_exec_cached_plans r
cross apply sys.dm_exec_query_plan(r.plan_handle) p
cross apply sys.dm_exec_sql_text(r.plan_handle) t