
--Check sysadmin for App Supp, Release Team, Octopus
USE [master];

SET NOCOUNT ON;

CREATE TABLE #sysadmins_check (ServerRole sysname, MemberName sysname, MemberSID varbinary(85));

INSERT #sysadmins_check ( ServerRole, MemberName, MemberSID )
EXEC sp_helpsrvrolemember 'sysadmin';

IF EXISTS(SELECT 1 FROM #sysadmins_check WHERE MemberName = 'CCCSNT\IT Application Support') PRINT SPACE(40)+CAST('(sysadmin)' AS CHAR(30))+'CCCSNT\IT Application Support';

IF EXISTS(SELECT 1 FROM #sysadmins_check WHERE MemberName = 'CCCSNT\Systems Application Support') PRINT SPACE(40)+CAST('(sysadmin)' AS CHAR(30))+'CCCSNT\Systems Application Support';

IF EXISTS(SELECT 1 FROM #sysadmins_check WHERE MemberName = 'Systems Application Support') PRINT SPACE(40)+CAST('(sysadmin)' AS CHAR(30))+'Systems Application Support';

IF EXISTS(SELECT 1 FROM #sysadmins_check WHERE MemberName = 'ApplicationSupport') PRINT SPACE(40)+CAST('(sysadmin)' AS CHAR(30))+'ApplicationSupport';

IF EXISTS(SELECT 1 FROM #sysadmins_check WHERE MemberName = 'CCCSNT\Systems Release Analysts') PRINT SPACE(40)+CAST('(sysadmin)' AS CHAR(30))+'CCCSNT\Systems Release Analysts';

IF EXISTS(SELECT 1 FROM #sysadmins_check WHERE MemberName = 'SystemsRelease') PRINT SPACE(40)+CAST('(sysadmin)' AS CHAR(30))+'SystemsRelease';

IF EXISTS(SELECT 1 FROM #sysadmins_check WHERE MemberName = 'CCCSNT\OctoTentacle') PRINT SPACE(40)+CAST('(sysadmin)' AS CHAR(30))+'CCCSNT\OctoTentacle';

DROP TABLE #sysadmins_check;

EXEC ('
IF EXISTS (SELECT 1 FROM sys.databases WHERE name=''CPF_BACS'')
BEGIN
CREATE TABLE ##role_members (role_name sysname, member_name sysname);
INSERT ##role_members (role_name, member_name)
SELECT dp.name AS role_name, us.name AS member_name
FROM CPF_BACS.sys.sysusers us
RIGHT JOIN CPF_BACS.sys.database_role_members rm ON us.uid = rm.member_principal_id
JOIN CPF_BACS.sys.database_principals dp ON rm.role_principal_id = dp.principal_id
WHERE dp.name<>''ReportingServices''
END;')

--Check database access for App Supp, Release Team, Octopus
DECLARE @SQL nvarchar(4000);

SET @SQL = 'USE [?];

			IF ''[?]'' NOT IN (''[master]'', ''[model]'', 
      
	                            ''[msdb]'', ''[tempdb]'',
								''[SystemsHelpDesk]'',
								''[NSB.Transport]'',
								''[NSB.DCS.Timeouts]'',
								''[NSB.DCS.Sagas]'',
								''[NSB.DMS.Timeouts]'',
								''[NSB.DMS.Sagas]'')
				AND NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = ''?'' AND source_database_id IS NOT NULL)
		Begin
      
  IF EXISTS(SELECT 1 FROM sys.database_principals WHERE name = ''CCCSNT\IT Application Support'') PRINT SPACE(40)+CAST(''.?'' AS CHAR(30))+''CCCSNT\IT Application Support'';

IF ''.?''<>''.CPF_BACS''
BEGIN
  IF EXISTS(SELECT 1 FROM sys.database_principals WHERE name = ''CCCSNT\Systems Application Support'') 
  PRINT SPACE(40)+CAST(''.?'' AS CHAR(30))+''CCCSNT\Systems Application Support'';
END
ELSE
BEGIN
	IF EXISTS(SELECT 1 FROM ##role_members WHERE member_name=''CCCSNT\Systems Application Support'')
  PRINT SPACE(40)+CAST(''.?'' AS CHAR(30))+''CCCSNT\Systems Application Support'';
END

  IF EXISTS(SELECT 1 FROM sys.database_principals WHERE name = ''Systems Application Support'') 
    AND @@SERVERNAME+''.?'' NOT IN (''LDSGENPRO1DBA02.PDD'',''LDSDCSPRO1DBA01.DCSLive'')
  PRINT SPACE(40)+CAST(''.?'' AS CHAR(30))+''Systems Application Support'';

  IF EXISTS(SELECT 1 FROM sys.database_principals WHERE name = ''ApplicationSupport'') PRINT SPACE(40)+CAST(''.?'' AS CHAR(30))+''ApplicationSupport'';

  IF EXISTS(SELECT 1 FROM sys.database_principals WHERE name = ''CCCSNT\Systems Release Analysts'') PRINT SPACE(40)+CAST(''.?'' AS CHAR(30))+''CCCSNT\Systems Release Analysts'';

  IF EXISTS(SELECT 1 FROM sys.database_principals WHERE name = ''SystemsRelease'') PRINT SPACE(40)+CAST(''.?'' AS CHAR(30))+''SystemsRelease'';

  IF EXISTS(SELECT 1 FROM sys.database_principals WHERE name = ''CCCSNT\OctoTentacle'') PRINT SPACE(40)+CAST(''.?'' AS CHAR(30))+''CCCSNT\OctoTentacle'';

	END';
	
EXEC sp_MSForEachDB @SQL;


EXEC ('
IF EXISTS (SELECT 1 FROM sys.databases WHERE name=''CPF_BACS'')
BEGIN
DROP TABLE ##role_members;
END
')

