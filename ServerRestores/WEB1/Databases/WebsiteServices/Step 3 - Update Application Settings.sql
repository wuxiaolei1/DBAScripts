
/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 3 - Update Application Settings .sql"

--- */
:on error exit
Print 'Step 3 - Update Application Settings - WebsiteServices'

--Add User

USE WebsiteServices
GO

declare @EnvTeam uniqueidentifier
set @EnvTeam = newid()

insert into WebMail.AddressableEntities (AddressableEntityID,AddressableEntityTypeID)
select @EnvTeam,'A3F3F6F7-B633-41A7-A5D0-57D3C1AECD95'

insert into Users (UserID,UserName,password,EmailAddress,ValidFrom,passwordSalt,FullName,CreatorUserID,AddressableEntityTypeID,OrganisationalUnitID)
select @EnvTeam,'EnviroTeam','','environments@stepchange.org',CURRENT_TIMESTAMP,0,'Enviro Team',@EnvTeam,'A3F3F6F7-B633-41A7-A5D0-57D3C1AECD95','DFB3DAFD-2E8C-40CA-B40F-A314ABDE281F'

update DMSWritebacks set SuccessUserID = @EnvTeam,FailureUserID = @EnvTeam

