--SCRIPT IS GOOD ONLY FOR ENVIRONMENTS
--BEGINNING VMxx

DECLARE @ENVNAME VARCHAR(15)
--SET @ENVNAME = LEFT(@@SERVERNAME, 4) + 'DCSSERVER'
SET @ENVNAME = LEFT(@@SERVERNAME, 4) + 'DCSPRODBA01'

/****** Object:  LinkedServer [DCSSERVER]    Script Date: 03/15/2011 15:37:48 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'DCSSERVER', @srvproduct=@ENVNAME, @provider=N'SQLNCLI', @datasrc=@ENVNAME
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'DCSSERVER',@useself=N'False',@locallogin=NULL,@rmtuser=N'DRWriteback',@rmtpassword='DRWriteback'

EXEC master.dbo.sp_serveroption @server=N'DCSSERVER', @optname=N'collation compatible', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DCSSERVER', @optname=N'data access', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=N'DCSSERVER', @optname=N'dist', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DCSSERVER', @optname=N'pub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DCSSERVER', @optname=N'rpc', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DCSSERVER', @optname=N'rpc out', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DCSSERVER', @optname=N'sub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DCSSERVER', @optname=N'connect timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'DCSSERVER', @optname=N'collation name', @optvalue=null
EXEC master.dbo.sp_serveroption @server=N'DCSSERVER', @optname=N'lazy schema validation', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=N'DCSSERVER', @optname=N'query timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=N'DCSSERVER', @optname=N'use remote collation', @optvalue=N'true'