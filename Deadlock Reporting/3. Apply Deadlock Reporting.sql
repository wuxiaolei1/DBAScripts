-- Deadlock alerts through event notification

-- Code from http://www.resquel.com/ssb/2009/03/02/DeadlockAlertsThroughEventNotification.aspx


-- **********************************************************************************************************
-- DBA NOTE : Log on to the SQL Server under the built-in 'sa' login before proceeding -
--
-- this prevents an individual login with Arabic default language from being created
--
-- in order to take ownership of the event notification.
--
-- **********************************************************************************************************


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

-- Drop existing service/queue.
IF  EXISTS (SELECT * FROM sys.services WHERE name = N'svcDeadLock_Graph')
	DROP SERVICE svcDeadLock_Graph;
GO
IF  EXISTS (SELECT * FROM sys.service_queues WHERE name = N'queDeadLock_Graph')
	DROP QUEUE queDeadLock_Graph;
GO

-- Create a queue to receive messages.
CREATE QUEUE queDeadLock_Graph;
GO

-- Create a service on the queue that references
-- the event notifications contract.
CREATE SERVICE svcDeadLock_Graph
ON QUEUE queDeadLock_Graph
([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
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

-- Create table to log deadlocks.
IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DeadLock_Log]') AND type IN (N'U'))
	CREATE TABLE [dbo].[DeadLock_Log](
		DeadLock_ID INT IDENTITY(1,1) CONSTRAINT PK_DeadLock_Log PRIMARY KEY
		,DeadLock_Detected DATETIME NOT NULL
		,DeadLock_Graph XML NOT NULL
		,NoMailReason NVARCHAR(2048) NULL);
GO

-- Create alerting procedure.
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReceiveDeadLock_Graph]') AND type IN (N'P', N'PC'))
	DROP PROCEDURE [dbo].[ReceiveDeadLock_Graph];
GO
CREATE PROCEDURE [dbo].[ReceiveDeadLock_Graph]
AS
BEGIN
		DECLARE @conversation_handle UNIQUEIDENTIFIER
				,@message_body XML
				,@message_type_name NVARCHAR(256)
				,@deadlock_graph XML
				,@event_datetime DATETIME
				,@deadlock_id INT;
		BEGIN TRY
				BEGIN TRAN
						WAITFOR(
						RECEIVE TOP(1) @conversation_handle = CONVERSATION_HANDLE
										,@message_body = CAST(message_body AS XML)
										,@message_type_name = message_type_name
						FROM queDeadLock_Graph)
						, TIMEOUT 1000; -- http://resquel.com/ssb/2010/07/24/ServiceBrokerCanMakeYourTransactionLogBig.aspx

						-- Validate message.
						IF (@message_type_name = 'http://schemas.microsoft.com/SQL/Notifications/EventNotification' AND
							@message_body.exist('(/EVENT_INSTANCE/TextData/deadlock-list)') = 1)
						BEGIN
								-- Extract the info from the message.
								SELECT @deadlock_graph = @message_body.query('(/EVENT_INSTANCE/TextData/deadlock-list)')
										,@event_datetime = @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'datetime');

								-- Put the info in the table.
								INSERT [dbo].[DeadLock_Log] (DeadLock_Detected, DeadLock_Graph)
								VALUES (@event_datetime, @deadlock_graph);
								SELECT @deadlock_id = SCOPE_IDENTITY();

								-- Send deadlock alert mail.
								-- Requires configured database mail, will log an error if not (or anything else goes wrong).
								BEGIN TRY
										DECLARE @subj NVARCHAR(255), @bdy NVARCHAR(MAX), @qry NVARCHAR(MAX), @attfn NVARCHAR(255);
										SELECT @subj = 'A deadlock occurred on ' + @@SERVERNAME
											,@bdy = 'A deadlock occurred at ' + CONVERT(VARCHAR(20), @event_datetime, 120) + ' on SQL Server: ' + @@SERVERNAME + '. See attached xdl-file for deadlock details.'
											,@qry = 'SET NOCOUNT ON; SELECT DeadLock_Graph FROM [msdb].[dbo].[DeadLock_Log] WITH (READUNCOMMITTED) WHERE DeadLock_ID = ' + CAST(@deadlock_id AS VARCHAR(10))
													-- Locking hint is to prevent this dynamic query being blocked by the lock held by the insert. The dynamic SQL will not come from inside this transaction.
												,@attfn = REPLACE(@@SERVERNAME, '\', '_') + '_' + CAST(@deadlock_id AS VARCHAR(10)) + '.xdl';
										EXEC sp_send_dbmail @profile_name = 'Deadlock_Mail'
											,@recipients = 'SystemsSQLAdmin@stepchange.org'
											,@subject = @subj
											,@body = @bdy
											,@query = @qry
											,@attach_query_result_as_file = 1
											,@query_attachment_filename = @attfn -- http://support.microsoft.com/kb/924345
											,@query_result_header = 0
											,@query_result_width = 32767
											,@query_no_truncate = 1;
								END TRY
								BEGIN CATCH
										UPDATE [dbo].[DeadLock_Log]
										SET NoMailReason = ERROR_MESSAGE()
										WHERE DeadLock_ID = @deadlock_id;
								END CATCH
						END
						ELSE -- Not an event notification with deadlock-list.
								END CONVERSATION @conversation_handle
				COMMIT TRAN
		END TRY
		BEGIN CATCH
				ROLLBACK TRAN
		END CATCH
END
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
