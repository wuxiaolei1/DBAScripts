
use reportserver
go

select distinct c.path, username, max(timestart) lastrun
from dbo.ExecutionLogStorage els
inner join
	dbo.Catalog c
	on els.reportid = c.itemid
	
	group  by c.path, username
	order by 1, 2
	