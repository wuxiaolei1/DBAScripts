USE msdb
GO
SET NOCOUNT ON;
--=====================================================================
-- Author:  Yan Pan
-- Description: This stored procedure is used to generate a script 
-- for all the SSIS package stored in a SQL Server 
-- that are only protected by database roles.
-- The output script can be executed on another server 
-- to copy SSIS packages from the source server.
--=====================================================================
DECLARE @srcServer sysname, -- Source server name
@destServer sysname, -- Destination server name
@srcUser sysname, -- SQL Server login used to connect to the source server
@srcPassword sysname, -- Password of the SQL Server login on the source server
@destUser sysname, -- SQL Server login used to connect to the destination server
@destPassword sysname, -- Password of the SQL Server login on the destination server
@foldername sysname -- Password of the SQL Server login on the destination server

SELECT @srcServer = 'SYSDEV003', -- Source server name
@destServer = 'VM07DCSSERVER', -- Destination server name
@srcUser = '', -- SQL Server login used to connect to the source server
@srcPassword = '', -- Password of the SQL Server login on the source server
@destUser = '', -- SQL Server login used to connect to the destination server
@destPassword = '', -- Password of the SQL Server login on the destination server
@foldername = 'CWS Data Integration' -- Password of the SQL Server login on the destination server  
  

  -- Create folder
  select DISTINCT 'dtutil /Quiet /FCreate SQL;\;"CWS Data Integration" /SourceServer ' + @destServer 
  from msdb.dbo.sysdtspackages90 pkg 
  inner join msdb.dbo.sysdtspackagefolders90 fld  on pkg.folderid = fld.folderid
  where foldername = @foldername;

  -- Copy SSIS packages
  select 'dtutil /Quiet /COPY SQL;' + 
  case foldername when '' then '"' + [name] + '"' else '"' + foldername + '\' +  [name] + '"' end 
  + ' /SQL ' + case foldername when '' then '"' + [name] + '"' else '"' + foldername + '\' +  [name] + '"' end 
  + ' /SOURCESERVER ' + @srcServer 
  + case @srcUser when '' then '' else ' /SourceUser ' + @srcUser + ' /SourcePassword ' + @srcPassword end
  + ' /DESTSERVER ' + @destServer
  + case @destUser when '' then '' else ' /DestUser ' + @destUser + ' /DestPassword ' + @destPassword end
  from msdb.dbo.sysdtspackages90 pkg 
  inner join msdb.dbo.sysdtspackagefolders90 fld  on pkg.folderid = fld.folderid
  where foldername = @foldername;
 
  select 'dtutil /Quiet /Encrypt SQL;' + 
  case foldername when '' then '"' + [name] + '"' else '"' + foldername + '\' +  [name] + '"' end + ';0'
    + ' /DESTSERVER ' + @destServer
  + case @destUser when '' then '' else ' /DestUser ' + @destUser + ' /DestPassword ' + @destPassword end 
  from msdb.dbo.sysdtspackages90 pkg 
  inner join msdb.dbo.sysdtspackagefolders90 fld  on pkg.folderid = fld.folderid
  where foldername = @foldername;
 
 