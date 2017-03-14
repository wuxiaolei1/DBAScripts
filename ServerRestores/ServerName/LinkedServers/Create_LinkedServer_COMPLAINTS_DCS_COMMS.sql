USE [master]
GO

DECLARE @ENVNAME VARCHAR(15)
SET @ENVNAME = LEFT(@@SERVERNAME, 4) + 'DCSPRODBA01'

/****** Object:  LinkedServer [COMPLAINTS_DCS_COMMS]    Script Date: 11/05/2016 12:37:11 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'COMPLAINTS_DCS_COMMS', @srvproduct=@ENVNAME, @provider=N'SQLNCLI', @datasrc=@ENVNAME
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'COMPLAINTS_DCS_COMMS',@useself=N'False',@locallogin=NULL,@rmtuser=N'CommsWebServiceUser',@rmtpassword='CommsWebServiceUser'

GO

EXEC master.dbo.sp_serveroption @server=N'COMPLAINTS_DCS_COMMS', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'COMPLAINTS_DCS_COMMS', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'COMPLAINTS_DCS_COMMS', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'COMPLAINTS_DCS_COMMS', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'COMPLAINTS_DCS_COMMS', @optname=N'rpc', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'COMPLAINTS_DCS_COMMS', @optname=N'rpc out', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'COMPLAINTS_DCS_COMMS', @optname=N'sub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'COMPLAINTS_DCS_COMMS', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'COMPLAINTS_DCS_COMMS', @optname=N'collation name', @optvalue=NULL
GO

EXEC master.dbo.sp_serveroption @server=N'COMPLAINTS_DCS_COMMS', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'COMPLAINTS_DCS_COMMS', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'COMPLAINTS_DCS_COMMS', @optname=N'use remote collation', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'COMPLAINTS_DCS_COMMS', @optname=N'remote proc transaction promotion', @optvalue=N'true'
GO


