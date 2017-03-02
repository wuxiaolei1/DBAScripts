--To remove all replication objects from a database use:

sp_removedbreplication '<DatabaseName>'

--To remove a PULL subscription only use:

--USE <Subscription database name>
--GO
--EXEC sp_dropmergepullsubscription @publication = N'<Publication name>', @publisher = N'<Publisher server name>', @publisher_db = N'<Publisher database name>'
