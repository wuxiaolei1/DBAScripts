USE master
GO 
-- drop the logins if they exists
IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N'TCSAppointmentsUser')
	DROP LOGIN [TCSAppointmentsUser]	;
GO 
IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N'TCSBackgroundSvcUser')
	DROP LOGIN [TCSBackgroundSvcUser]	;
GO 
IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N'qms')
	DROP LOGIN [qms]	;
GO 


CREATE LOGIN [TCSAppointmentsUser] WITH PASSWORD=N'TCSAppointmentsUser', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;
CREATE LOGIN [TCSBackgroundSvcUser] WITH PASSWORD=N'TCSBackgroundSvcUser', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;
CREATE LOGIN [qms] WITH PASSWORD=N'qms', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;
GO 