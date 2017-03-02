--From - http://thesqlguy.wordpress.com/2010/11/24/sql-server-security-audit-script-detect-logins-with-no-permissions-sql-2005-version/


USE [SystemsHelpDesk]
GO

IF OBJECT_ID(N'[dbo].[rpt_security_Logins_with_no_permissions_2005]') IS NOT NULL
	DROP PROCEDURE [dbo].[rpt_security_Logins_with_no_permissions_2005]
GO

CREATE PROC [dbo].[rpt_security_Logins_with_no_permissions_2005]

AS

/*

	NE - 7/11/2007 - SQL 2005 only

	Displays any SQL logins which have no server-wide or database permissions.
	These logins should be able to be dropped from the SQL server

	Original script courtesy of SQLServerCentral.com,

http://www.sqlservercentral.com/scripts/viewscript.asp?scriptid=1084

	EXEC rpt_security_Logins_with_no_permissions_2005

*/

SET NOCOUNT ON

DECLARE @username sysname
DECLARE @objname sysname
DECLARE @found integer
DECLARE @sql nvarchar(4000)
DECLARE @results TABLE (Login sysname)

SET @username = ' '
WHILE @username IS NOT NULL
BEGIN
	SELECT @username = MIN(name)
	FROM master.dbo.syslogins WITH (NOLOCK)
	WHERE sysadmin = 0
	AND securityadmin = 0
	AND serveradmin = 0
	AND setupadmin = 0
	AND processadmin = 0
	AND diskadmin = 0
	AND dbcreator = 0
	AND bulkadmin = 0
	AND name > @username
	-- this is the list of non system logins
	-- ids in server roles may not have corresponding users
	-- any database but they should not be rremoved
	SET  @found = 0

	IF @username IS NOT NULL
		BEGIN
		--  now we search through each non system database
		--  to see if this login has database access
		SET @objname = ''
		WHILE @objname IS NOT NULL
		BEGIN
			SELECT @objname = MIN( name )
			FROM master.dbo.sysdatabases WITH (NOLOCK)
			WHERE
--			name NOT IN ('master', 'model', 'msdb', 'tempdb')
--			AND
			name > @objname
			AND DATABASEPROPERTYEX(name, 'status') = 'ONLINE'

			IF @objname IS NOT NULL
			BEGIN
				SET @sql = N'SELECT @found = COUNT(*) FROM [' + @objname
				+ N'].dbo.sysusers s WITH (NOLOCK) JOIN master.dbo.syslogins x WITH (NOLOCK)
				ON s.sid = x.sid WHERE hasdbaccess = 1 AND x.name = '''+ @username + ''''

				EXEC sp_executesql @sql,N'@found Int OUTPUT',@found OUTPUT
				--SELECT @found, @objname, @username
				IF @found IS NOT NULL AND @found > 0
					SET @objname = 'zzzzz'  -- terminate as a corresponding user has been found
			END
		END

		IF @found = 0
		BEGIN


		INSERT INTO @results
		SELECT @username
		END
	END
END

SELECT Login
FROM @results r

	--Other SQL 2005 permissions the login may have...
	LEFT JOIN
	(

		SELECT
			spr.name,
			[Object Class]=class_desc,
			[Object]=
				CASE class
					WHEN 100 THEN @@SERVERNAME
					WHEN 105 THEN (SELECT name FROM master.sys.endpoints WHERE endpoint_id=major_id)
					ELSE object_name(major_id)
				END ,
			[column]='',
			spm.state_desc,
			[Permission]=permission_name,
			[Permission Type]=
				CASE spr.type
					WHEN 'U' THEN 'Direct'
					WHEN 'R' THEN 'Inherited'
				END
		FROM master.sys.server_permissions spm 

			INNER JOIN master.sys.server_principals spr
			ON spm.grantee_principal_id=spr.principal_id
		WHERE
			spr.type NOT IN('C')
			AND is_disabled=0
		--		AND spr.name=@login
			AND permission_name NOT LIKE 'CONNECT%'

		UNION 

		SELECT
			spr.name,
			[Object Class]=class_desc,
			Object=
				CASE class
					WHEN 100 THEN @@SERVERNAME
					WHEN 105 THEN (SELECT name FROM master.sys.endpoints WHERE endpoint_id=major_id)
					ELSE object_name(major_id)
				END,
			'' ,
			spm.state_desc,
			permission_name,
			[Permission Type]=
				CASE spr.type
					WHEN 'U' THEN 'Direct'
					WHEN 'R' THEN 'Inherited'
				END
		FROM master.sys.server_permissions spm 

			INNER JOIN master.sys.server_principals spr
			ON spm.grantee_principal_id=spr.principal_id 

		WHERE
			spr.type NOT IN('C')
			AND is_disabled=0 AND
			spr.name='public'
			AND permission_name NOT LIKE 'CONNECT%'

		UNION

		SELECT
			spr.name,
			'',
			'',
			'',
			'',
			CASE
				WHEN spr.is_disabled = 1 THEN '(Valid login, but login is disabled at the SQL level)'
				ELSE '(Valid login, but permission to connect to database engine is denied)'
			END,
			''
		FROM master.sys.server_permissions spm 

			INNER JOIN master.sys.server_principals spr
			ON spm.grantee_principal_id=spr.principal_id

		WHERE
			spr.is_disabled = 1
			OR (spm.permission_name = 'CONNECT SQL' AND spm.state_desc = 'DENY')

	) AS a

	ON r.[Login] = a.name

	WHERE a.name IS NULL

ORDER BY LOGIN

GO

--Test execution
EXEC rpt_security_Logins_with_no_permissions_2005

