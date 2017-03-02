IF EXISTS (SELECT 1 FROM master.sys.servers WHERE name = N'EnviroDataLinkedServer' AND is_linked = 1)
  EXEC master.dbo.sp_dropserver @server = N'EnviroDataLinkedServer', @droplogins = 'droplogins';

EXEC master.dbo.sp_addlinkedserver @server = N'EnviroDataLinkedServer', @srvproduct = N'VM2008DBA01', @provider = N'SQLNCLI', @datasrc = N'VM2008DBA01';
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N'EnviroDataLinkedServer', @useself = 'false', @locallogin = NULL, @rmtuser = N'DataScrambleReader', @rmtpassword = N'G1453643ads!';

EXEC master.dbo.sp_serveroption @server = N'EnviroDataLinkedServer', @optname = 'collation compatible', @optvalue = 'false';
EXEC master.dbo.sp_serveroption @server = N'EnviroDataLinkedServer', @optname = 'data access', @optvalue = 'true';
EXEC master.dbo.sp_serveroption @server = N'EnviroDataLinkedServer', @optname = 'rpc', @optvalue = 'false';
EXEC master.dbo.sp_serveroption @server = N'EnviroDataLinkedServer', @optname = 'rpc out', @optvalue = 'false';
EXEC master.dbo.sp_serveroption @server = N'EnviroDataLinkedServer', @optname = 'use remote collation', @optvalue = 'true';
EXEC master.dbo.sp_serveroption @server = N'EnviroDataLinkedServer', @optname = 'collation name', @optvalue = NULL;
EXEC master.dbo.sp_serveroption @server = N'EnviroDataLinkedServer', @optname = 'connect timeout', @optvalue = '0';
EXEC master.dbo.sp_serveroption @server = N'EnviroDataLinkedServer', @optname = 'query timeout', @optvalue = '0';
EXEC master.dbo.sp_serveroption @server = N'EnviroDataLinkedServer', @optname = 'dist', @optvalue = 'false';
EXEC master.dbo.sp_serveroption @server = N'EnviroDataLinkedServer', @optname = 'pub', @optvalue = 'false';
EXEC master.dbo.sp_serveroption @server = N'EnviroDataLinkedServer', @optname = 'sub', @optvalue = 'false';
EXEC master.dbo.sp_serveroption @server = N'EnviroDataLinkedServer', @optname = 'lazy schema validation', @optvalue = 'false';
