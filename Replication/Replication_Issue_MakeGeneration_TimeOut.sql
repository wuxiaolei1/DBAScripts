--Replication Issue:
 
--This message despite altering the Merge Agent time out and the remote query timeout
--Ref: http://technet.microsoft.com/en-us/library/ms152515.aspx

--The merge process failed to execute a query because the query timed out. 
--If this failure continues, increase the query timeout for the process. 
--When troubleshooting, restart the synchronization with 
--verbose history logging and specify an output file to which to write.

--Articiles Referenced:
--http://iainmagee.wordpress.com/2008/05/09/sql-replication-fun/
--http://msmvps.com/blogs/sbsdiva/archive/2010/01/13/sql-partner-news-january-2010.aspx
--http://www.replicationanswers.com/Merge.asp
--http://www.replicationanswers.com/MergeInternals1.asp
--http://connect.microsoft.com/SQLServer/feedback/details/287534/sp-msmakegeneration-infinite-loop-on-subscriber
--http://support.microsoft.com/kb/953568
--http://social.msdn.microsoft.com/forums/en-US/sqlreplication/thread/7da7efa0-52d4-48e6-8a7f-e3579f48c5ac/
--http://social.msdn.microsoft.com/forums/en-US/sqlreplication/thread/ea00420d-643b-4aef-aea5-345e6a9c4e4b/

--On the PUBLISHER.....

--First Retrieve the current setting for generation_leveling_threshold:
USE WebsiteServices
GO
exec sp_helpmergepublication @publication = 'WebsiteServices'
--generation_leveling_threshold = 1000

--Now Set the generation_leveling_threshold = 0
exec sp_changemergepublication @publication = 'WebsiteServices'
, @property = 'generation_leveling_threshold'
, @value = 0

--Revert back to original
exec sp_changemergepublication @publication = 'WebsiteServices'
, @property = 'generation_leveling_threshold'
, @value = 1000

--ALTERNATIVELY TRY UPPING THE SIZE...
--Ref:
--http://blogs.msdn.com/b/repltalk/archive/2011/04/24/reducing-impact-of-large-updates-on-merge-replication.aspx

exec sp_changemergepublication @publication='WebsiteServices',
@property= 'generation_leveling_threshold',
@value= '10000'

--Or, on subscriber, Try...
--update sysmergepublications set [generation_leveling_threshold] = 0
--Ref:
--http://social.msdn.microsoft.com/forums/en-US/sqlreplication/thread/7da7efa0-52d4-48e6-8a7f-e3579f48c5ac/
--http://social.msdn.microsoft.com/Forums/en-US/sqlreplication/thread/53cdb5f6-eff8-42ea-9a34-3391dd30747d/

--------Run on the Subscriber...

------    SELECT top 1000 *

------      FROM [dbo].[MSmerge_genhistory] with (nolock)

------      order by generation desc

-----------------------------------------------------------------
------SELECT top 100 *

------FROM msmerge_genhistory

------WHERE genstatus = 4

------AND coldate < dateadd(hh, -12, getdate())

------select  count (*) from dbo.MSmerge_contents --6955960
------select  count (*) from dbo.MSmerge_genhistory --328
