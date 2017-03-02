/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -v Environment="'SYSTEST'" -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DCSSERVER\DCSLive\Step 3 - Update Application Settings.sql"

--- */

/* ------ Repoint DCS -------- */
:on error exit
SET NOCOUNT ON
Print 'Step 3 - Update Application Settings DCS'
USE DCSLive
GO

DECLARE @MaintURL varchar(100), --LIVE = 'http://PDD/wfmDMCMaintenance.aspx'
@WebserviceURL NVARCHAR(200), --LIVE = 'http://ddebroker/dde.asmx'
@RunningEnvironment NVARCHAR(200), --LIVE = 'Production'
@DBUsername NVARCHAR(200), --Same as live - do not need to set!!
@DBPassword NVARCHAR(200), --Changed from live
@WebsiteStartURL NVARCHAR(200), --LIVE = 'http://pdddde/'
@WebsiteCloseURL NVARCHAR(200), --Same as live - do not need to set!!
@DBServer NVARCHAR(200), --LIVE = 'LDSGENPRO1DBA02'
@DBName NVARCHAR(200), --Same as live - do not need to set!!
@Environment varchar(15)

--Set the same for every environment...
SET @DBUsername = 'PddDbUser'
SET @DBPassword = 'PddDbUser'
SET @WebsiteCloseURL = 'blank.aspx'
SET @DBName = 'PDD'
set @Environment = $(Environment)
--Defaults
SET @WebsiteStartURL = ''

--Change on every environment...
SET @MaintURL = ''
SET @WebserviceURL = ''
SET @RunningEnvironment = $(Environment) --Change to PDD Webservice Running Environment e.g. 'Acceptance' for UAT

SET @DBServer = LEFT(@@SERVERNAME, 4) + 'GENPRODBA02'

--If more items need setting create table variable and 
--update tblSystem_References with after populating

SELECT @WebsiteStartURL = EAS.PDDWebSiteStartURL
FROM EnviroDataLinkedServer.DataScramble.dbo.EnviroAppSettings EAS
WHERE Environment = @Environment
	

--DO THE UPDATES...
Update tblSystem_References set 
	Reference_Display_Value = @WebserviceURL
where Reference_Type = 95
and Reference_Description = 'DDeBrokerWebService'

Update tblSystem_References set 
	Reference_Display_Value = @RunningEnvironment
where Reference_Type = 96
and Reference_Description = 'Broker_Configuration'

Update tblSystem_References set 
	Reference_Display_Value = @DBUsername
where Reference_Type = 97
and Reference_Description = 'PDDSQLUser'

Update tblSystem_References set 
	Reference_Display_Value = @DBPassword
where Reference_Type = 98
and Reference_Description = 'PDDSQLUSERPASSWORD'

Update tblSystem_References set 
	Reference_Display_Value = @WebsiteStartURL
where Reference_Type = 32
and Reference_Description = 'PDD Setup Website URL'

Update tblSystem_References set 
	Reference_Display_Value = @WebsiteCloseURL
where Reference_Type = 34
and Reference_Description = 'PDD Close Browser URL'

UPDATE tblSystem_References SET
	Reference_Display_Value = @DBServer
WHERE Reference_Type = 30
and Reference_Description = 'PDD SQL SERVER Name'

UPDATE tblSystem_References SET
	Reference_Display_Value = @DBName
WHERE Reference_Type = 31
and Reference_Description = 'PDD Database Name'

update tblSystem_References
set Reference_display_value = @MaintURL
where reference_type = 33


/*-------------------------------------------------*/
/* ---- Update Application Settings ---- */

DECLARE @EdriveFolder varchar(30)
DECLARE @CommsServer1 varchar(30)
DECLARE @CommsServer2 varchar(30)

--Set Defaults
--SET @CommsServer1 = '\\LDSCOMPRO1APP01'
--SET @CommsServer2 = '\\LDSCOMPRO1APP02'
SET @CommsServer1 = '\\SYSAPSCOMSAPP01'
SET @CommsServer2 = '\\SYSAPSCOMSAPP02'
SET @EdriveFolder = 'E:\'

SELECT	 @CommsServer1 = EDV.CommsServer1
		, @CommsServer2 = EDV.CommsServer2
FROM EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE Environment = @Environment

SELECT	 @EdriveFolder = EAS.EdriveFolder
FROM EnviroDataLinkedServer.DataScramble.dbo.EnviroAppSettings EAS
WHERE Environment = @Environment


		--TABLE: tblCommProductionQueue

		UPDATE	tblCommProductionQueue
		SET	PQ_DriverProcessPath = @EdriveFolder + 'Program Files\DCS\' + 'PQProcessor.exe'
		WHERE	PQ_DriverProcessPath like '%PQProcessor.exe%'

		UPDATE	tblCommProductionQueue
		SET	PQ_DriverProcessPath = @EdriveFolder + 'Program Files\DCS\' + 'ExcelProcessor.exe'
		WHERE	PQ_DriverProcessPath like '%ExcelProcessor.exe%'

		UPDATE	tblCommProductionQueue
		SET	PQ_DriverProcessPath = @EdriveFolder + 'Program Files\DCS\' + 'ClientRetention.exe'
		WHERE	PQ_DriverProcessPath like '%ClientRetention.exe%'

		UPDATE	tblCommProductionQueue
		SET	PQ_DriverProcessPath = @EdriveFolder + 'Program Files\DCS\' + 'BCCreateCRs.exe'
		WHERE	PQ_DriverProcessPath like '%BCCreateCRs.exe%'

		--TABLE: tblCommProdQueueSchedule
		UPDATE	tblCommProdQueueSchedule
		SET	CPQS_ValidTo = dateadd(d, -1, getdate())

		--TABLE: tblSystem_References
		UPDATE	tblSystem_References
		SET	Reference_display_value = @EdriveFolder + 'Program Files\DCS\Templates\'
		WHERE	Reference_Type = 26

		--TABLE: tblCommFileAttributes
		UPDATE	tblCommFileAttributes
		SET	CFA_StorageLocation = replace(left(CFA_Storagelocation, 50 - len(@EdriveFolder)), 'E:\', @EdriveFolder)

		UPDATE	tblCommFileAttributes
		SET	CFA_StorageLocation = replace(CFA_Storagelocation, @CommsServer1, @EdriveFolder)

		UPDATE	tblCommFileAttributes
		SET	CFA_StorageLocation = replace(CFA_Storagelocation, @CommsServer2, @EdriveFolder)

		--TABLE: tblPrinterAttributes...updated to new Systems printer...IJ 04/08/11
		UPDATE	dbo.tblPrinterAttributes
		SET	PA_Name = 'HP4540SYSTEMS', PA_Path = '\\vmprtpro1app01\HP4540SYSTEMS'

		--TABLE: tblService_Settings...updated to new Systems printer...IJ 04/08/11
		UPDATE	dbo.tblService_Settings
		SET	value = '\\vmprtpro1app01\HP4540SYSTEMS'
		WHERE	name = 'Printer'

		--TABLE: tblCommDefaults
		UPDATE	tblCommDefaults
		SET	DefaultServerName = 'DEVSERVER', active = 0 
		WHERE	locked = 'X'

GO 


-- Update SQL Agent logon to use non-Live account
UPDATE
[DCSLive].[dbo].[tblCOLLEAGUE]
SET [Colleague_NT_Logon_Id] = 'SUPPRO3_SQLAGENT'
WHERE [Colleague_NT_Logon_Id] = 'GENPRO3_SQLAgent'