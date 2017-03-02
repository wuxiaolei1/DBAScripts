
/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 3 - Update Application Settings .sql"

--- */
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

--AddStepChangeIP & Subnet for every creditor
--Enables every creditor to be accessed in support environments
INSERT INTO [CreditorServices].[AbstractCreditorIPs] (
	[AbstractCreditorID],
	[IPAddress],
	[IPSubnet],
	[ValidFrom],
	[ValidTo],
	[CreatorUserID],
	[DeletorUserID]
) 
SELECT 
	DISTINCT ACIPS2.AbstractCreditorID,
	-1408237568,
	-65536,
	Current_TimeStamp,
	NULL,
	'C946CD41-8C18-429E-B9EA-C5221F3229D6', --davidk
	NULL
FROM [CreditorServices].[AbstractCreditorIPs] ACIPS2 --73 Rows
--DO NOT INCLUDE WHERE THE CREDITOR ALREADY HAS SUCH A VALID IP ADDRESS
WHERE ACIPS2.AbstractCreditorID NOT IN
								(
								SELECT DISTINCT(ACIPS1.[AbstractCreditorID]) 
								FROM [CreditorServices].[AbstractCreditorIPs] ACIPS1
								WHERE ACIPS1.[IPAddress] = -1408237568 --CCCS IP
								AND ACIPS1.[IPSubnet] = -65536 --CCCS SubNet Mask
								AND (ACIPS1.[ValidTo] IS NULL OR Current_TimeStamp < ACIPS1.[ValidTo]) 
								) 
