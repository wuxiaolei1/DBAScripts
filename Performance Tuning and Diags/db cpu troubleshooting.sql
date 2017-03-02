--high runnable = bad cpu util
select  
    scheduler_id, 
    current_tasks_count, 
    runnable_tasks_count 
from  
    sys.dm_os_schedulers 
where  
    scheduler_id < 255


-- shows plan with most cpu util at top
select top 50  
    sum(qs.total_worker_time) as total_cpu_time,  
    sum(qs.execution_count) as total_execution_count, 
    count(*) as  number_of_statements,  
    qs.plan_handle  
from  
    sys.dm_exec_query_stats qs 
group by qs.plan_handle 
order by sum(qs.total_worker_time) desc

select *  
from sys.dm_exec_query_optimizer_info


select  
    cur.*  
from  
    sys.dm_exec_connections con 
    cross apply sys.dm_exec_cursors(con.session_id) as cur 
where 
    cur.fetch_buffer_size = 1  
    and cur.properties LIKE 'API%'    -- API  cursor (TSQL cursors always have fetch buffer of 1)


