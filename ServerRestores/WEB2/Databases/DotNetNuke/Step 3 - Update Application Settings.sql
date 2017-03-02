
/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 3 - Update Application Settings .sql"

--- */
:on error exit
Print 'Step 3 - Update Application Settings - DotNetNuke'
USE DotNetNuke
GO

SET QUOTED_IDENTIFIER ON;

--update all user's email addresses
update dbo.users 
set email = 'systemstesting@stepchange.org'

--Set the IsSecure flag (changed from live as live uses SSL connections and support does not)
UPDATE Tabs
SET IsSecure = 0
WHERE IsSecure = 1

-- TB, May 2013 - Updates the user password expiry setting to 5 years
-- Requested by Craig Shaw, app support to stop users having to reset their passwords in non live environments
UPDATE [HostSettings]
SET SettingValue = 1825
WHERE SettingName = 'PasswordExpiry';

-- AS, Sep 2012 - Portal aliases requested by the Environment Team

DECLARE @PAID INT, @Alias NVARCHAR(200);

--JM - update to prevent duplicate portal alias
SELECT @PAID = MAX(PortalAliasID) FROM dbo.PortalAlias;
SET @Alias = SUBSTRING(@@SERVERNAME, 1, 4) + '.StepChange.org';
IF NOT EXISTS (SELECT * FROM dbo.PortalAlias WHERE HTTPAlias = @Alias)	
	EXEC dbo.UpdatePortalAlias @PortalAliasID = @PAID, @PortalID = 0, @HTTPAlias = @Alias, @LastModifiedByUserID = 7,
		@CultureCode = NULL, @Skin = NULL, @BrowserType = NULL, @IsPrimary = 0;

--update all passwords to 'password'
update dbo.aspnet_membership set 
password = '1HTn1Lmac97FwqHI+xiJh/ypDzIQwls8ZPua12Ff+e/eE7NiMaEv/Q==' , 
passwordsalt = 'nOJ8NuU2lq4BoP2UUS0L5w==',
[LastPasswordChangedDate] = CURRENT_TIMESTAMP - 1 ;
