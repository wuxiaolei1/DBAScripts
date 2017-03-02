select p.name, s.name from sys.server_event_notifications s join sys.server_principals p on s.principal_id = p.principal_id



-- STEP 1 : Get the service broker guid of the msdb database and copy it to the clipboard.

USE master;
GO

SELECT service_broker_guid FROM sys.databases WHERE name = 'msdb';
GO

-- STEP 2 : CTRL+SHIFT+M to insert the guid.

-- STEP 3 : Run the code that proceeds.

USE msdb;
GO

EXECUTE AS LOGIN = 'sa';
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



-- Create the event notification.
IF  EXISTS (SELECT * FROM sys.server_event_notifications WHERE name = N'evnDeadLock_Graph')
	DROP EVENT NOTIFICATION evnDeadLock_Graph
	ON SERVER;
GO
CREATE EVENT NOTIFICATION evnDeadLock_Graph
ON SERVER
FOR DEADLOCK_GRAPH
TO SERVICE 'svcDeadLock_Graph', '<msdb_service_broker_guid, UNIQUEIDENTIFIER, >';
GO



ALTER QUEUE queDeadLock_Graph
WITH
STATUS = ON,
ACTIVATION(
PROCEDURE_NAME = [msdb].[dbo].[ReceiveDeadLock_Graph],
STATUS = ON,
MAX_QUEUE_READERS = 1,
EXECUTE AS OWNER);
GO





select p.name, s.name from sys.server_event_notifications s join sys.server_principals p on s.principal_id = p.principal_id
