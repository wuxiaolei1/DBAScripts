
USE msdb;
GO

ALTER QUEUE queDeadLock_Graph
WITH
STATUS = OFF,
ACTIVATION(
PROCEDURE_NAME = [msdb].[dbo].[ReceiveDeadLock_Graph],
STATUS = OFF,
MAX_QUEUE_READERS = 1,
EXECUTE AS OWNER);
GO

IF  EXISTS (SELECT * FROM sys.server_event_notifications WHERE name = N'evnDeadLock_Graph')
	DROP EVENT NOTIFICATION evnDeadLock_Graph
	ON SERVER;
GO
IF  EXISTS (SELECT * FROM sys.services WHERE name = N'svcDeadLock_Graph')
	DROP SERVICE svcDeadLock_Graph;
GO
IF  EXISTS (SELECT * FROM sys.service_queues WHERE name = N'queDeadLock_Graph')
	DROP QUEUE queDeadLock_Graph;
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReceiveDeadLock_Graph]') AND type IN (N'P', N'PC'))
	DROP PROCEDURE [dbo].[ReceiveDeadLock_Graph];
GO
