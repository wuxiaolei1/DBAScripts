/*******************************************************************
* PURPOSE: Script to highlight any logins that are not present on the 
*			HA or DR server that exist on the production server
* NOTES:   A login will be considered out of sync if it doesnt exist, or there
*			is a difference in either the name, sid, type or password
*		   Currently checks:
* 	LDSTCSPRO1DBA01 - TCS
* 	LDSDCSPRO1DBA01 - DCSLive
* 	LDSDMSPRO1DBA01 - DMS
* 	LDSGENPRO1DBA02 - CPD
* 	LDSGENPRO1DBA02 - ShoreTelECC
* 	LDSGENPRO1DBA03 - CIPHR
* 	LDSGENPRO1DBA04 - WebsiteServices
* 	LDSGENPRO1DBA03 - CPF_BACS
* 	LDSQMTPRO1DBA01 - qms
* 	LDSQMTPRO1DBA01 - Appointments
*	VMWBSPRO1DBA01  - WebSeries
*	VMWBSPRO1DBA01  - directdebit
*	VMCLUPRO1DBA01  - AssetLiability
*	VMCLUPRO1DBA01  - Budget
*	VMCLUPRO1DBA01  - Client
*	VMCLUPRO1DBA01  - ClientHistoryAudit
*	VMCLUPRO1DBA01  - ClientSolution
*	VMCLUPRO1DBA01  - Communications
*	VMCLUPRO1DBA01  - Imaging
*	VMCLUPRO1DBA01  - Note
*	VMCLUPRO1DBA01  - NoteHistoryAudit
*	VMCLUPRO1DBA01  - TaskRemindersVMNSBPRO2DBA01  - NSB.Assets.Subscriptions
*	VMNSBPRO2DBA01  - NSB.Assets.Timeouts
*	VMNSBPRO2DBA01  - NSB.Assets.Writer.Sagas
*	VMNSBPRO2DBA01  - NSB.Assets.Writer.Timeouts
*	VMNSBPRO2DBA01  - NSB.Bus2DCS.Timeouts
*	VMNSBPRO2DBA01  - NSB.Bus2DMS.Timeouts
*	VMNSBPRO2DBA01  - NSB.Client.Subscriptions
*	VMNSBPRO2DBA01  - NSB.Client.Timeouts
*	VMNSBPRO2DBA01  - NSB.Client.Writer.Sagas
*	VMNSBPRO2DBA01  - NSB.Client.Writer.Timeouts
*	VMNSBPRO2DBA01  - NSB.ClientSolution.Subscriptions
*	VMNSBPRO2DBA01  - NSB.ClientSolution.Timeouts
*	VMNSBPRO2DBA01  - NSB.ClientSolution.Writer.Sagas
*	VMNSBPRO2DBA01  - NSB.ClientSolution.Writer.Timeouts
*	VMNSBPRO2DBA01  - NSB.Colleague.Writer.Subscriptions
*	VMNSBPRO2DBA01  - NSB.Colleague.Writer.Timeouts
*	VMNSBPRO2DBA01  - NSB.Communications.Subscriptions
*	VMNSBPRO2DBA01  - NSB.Communications.Timeouts
*	VMNSBPRO2DBA01  - NSB.Communications.Writer.Sagas
*	VMNSBPRO2DBA01  - NSB.Communications.Writer.Timeouts
*	VMNSBPRO2DBA01  - NSB.DCS.Sagas
*	VMNSBPRO2DBA01  - NSB.DCS.Timeouts
*	VMNSBPRO2DBA01  - NSB.DCSBudget.Subscriptions
*	VMNSBPRO2DBA01  - NSB.DCSBudget.Timeouts
*	VMNSBPRO2DBA01  - NSB.DCSBudget.Writer.Sagas
*	VMNSBPRO2DBA01  - NSB.DCSBudget.Writer.Timeouts
*	VMNSBPRO2DBA01  - NSB.DirectDebit.Timeouts
*	VMNSBPRO2DBA01  - NSB.DMS.Sagas
*	VMNSBPRO2DBA01  - NSB.DMS.Timeouts
*	VMNSBPRO2DBA01  - NSB.Imaging.Subscriptions
*	VMNSBPRO2DBA01  - NSB.Imaging.Timeouts
*	VMNSBPRO2DBA01  - NSB.Imaging.Writer.Sagas
*	VMNSBPRO2DBA01  - NSB.Imaging.Writer.Timeouts
*	VMNSBPRO2DBA01  - NSB.Notes.Subscriptions
*	VMNSBPRO2DBA01  - NSB.Notes.Timeouts
*	VMNSBPRO2DBA01  - NSB.Notes.Writer.Sagas
*	VMNSBPRO2DBA01  - NSB.Notes.Writer.Timeouts
*	VMNSBPRO2DBA01  - NSB.TaskReminders.Subscriptions
*	VMNSBPRO2DBA01  - NSB.TaskReminders.Timeouts
*	VMNSBPRO2DBA01  - NSB.TaskReminders.Writer.Sagas
*	VMNSBPRO2DBA01  - NSB.TaskReminders.Writer.Timeouts
*	VMNSBPRO2DBA01  - NSB.Transport
* AUTHOR:  Tom Braham
* CREATED DATE: 26/06/2013
* MODIFIED DETAILS
* DATE            AUTHOR                  CHGREF/DESCRIPTION
*-------------------------------------------------------------------
* {date}          {developer} {brief modification description}
*******************************************************************/

EXEC sp_configure 'show advanced options',1;
go 
RECONFIGURE
go 
EXEC sp_configure 'Ad Hoc Distributed Queries',1;
go 
RECONFIGURE
go 

/* Declare variables */
DECLARE @ProdSvr sysname, @ProdConn VARCHAR(255);
DECLARE @HASvr sysname, @HAConn VARCHAR(255);
DECLARE @DRSvr sysname, @DRConn VARCHAR(255);
DECLARE @DatabaseName sysname;
DECLARE @SQL VARCHAR(MAX);

IF OBJECT_ID('tempdb..#OutOfSyncLogins','U') IS NOT NULL
BEGIN
	DROP TABLE #OutOfSyncLogins;
END;

IF OBJECT_ID('tempdb..#AllServers','U') IS NOT NULL
BEGIN
	DROP TABLE #AllServers;
END

/* Create results table if it doesnt exist already */
IF OBJECT_ID('tempdb..#OutOfSyncLogins') IS NULL
BEGIN
	CREATE TABLE #OutOfSyncLogins
	(	ProductionServer sysname NOT NULL,
		LoginName sysname NOT NULL,
		LoginType CHAR(1) NOT NULL,
		OutOfSyncServer sysname NOT NULL,
		DatabaseName sysname NOT NULL );
END;

/* create table to hold list of servers to query */	
IF OBJECT_ID('tempdb..#AllServers') IS NULL
BEGIN
	CREATE TABLE #AllServers
	(	ProductionServer sysname NOT NULL,
		HAServer sysname NULL,
		DRServer sysname NOT NULL, 
		DatabaseName sysname NOT NULL );
END
ELSE
BEGIN
	TRUNCATE TABLE #AllServers;
END;

/* Populate server list 
NOTE: modify this list to add/remove server to verify */
INSERT INTO #AllServers 
	(	ProductionServer,
		HAServer,
		DRServer,
		DatabaseName  )
SELECT 	'LDSTCSPRO1DBA01','LDSGENDSR1DBA01\SQL2005STD','HLXGENDSR1DBA01','TCS'
UNION ALL
SELECT 	'LDSDCSPRO1DBA01','LDSGENDSR1DBA01','HLXGENDSR1DBA03','DCSLive'
UNION ALL
SELECT 	'LDSDMSPRO1DBA01','LDSGENDSR1DBA01','HLXDMSDSR1DBA02','DMS'
UNION ALL
SELECT 	'LDSDMSPRO1DBA01','LDSGENDSR1DBA01','HLXDMSDSR1DBA02','DMSArchive'
UNION ALL
--SELECT 	'LDSGENPRO1DBA02',NULL,'HLXGENDSR1DBA01','ACC'
--UNION ALL
SELECT 	'LDSGENPRO1DBA02',NULL,'HLXGENDSR1DBA01','CPD'
UNION ALL
--SELECT 	'LDSGENPRO1DBA04',NULL,'HLXGENDSR1DBA01','DirectDebit'
--UNION ALL
--SELECT 	'LDSGENPRO1DBA04',NULL,'HLXGENDSR1DBA01','iBACS'
--UNION ALL
SELECT 	'LDSGENPRO1DBA04',NULL,'HLXGENDSR1DBA02','ShoreTelECC'
UNION ALL
SELECT 	'VMCIPPRO1DBA01',NULL,'HLXGENDSR1DBA04','CIPHR'
UNION ALL
SELECT 	'LDSGENPRO1DBA04',NULL,'HLXGENDSR1DBA02','WebsiteServices'
UNION ALL
SELECT 	'LDSGENPRO1DBA03',NULL,'HLXGENDSR1DBA04','CPF_BACS'
UNION ALL
SELECT 	'LDSQMTPRO1DBA01','LDSGENDSR1DBA01\SQL2005STD','HLXGENDSR1DBA03','qms'
UNION ALL
SELECT 	'LDSQMTPRO1DBA01','LDSGENDSR1DBA01\SQL2005STD','HLXGENDSR1DBA03','Appointments'
UNION ALL
SELECT  'VMWBSPRO1DBA01',NULL,'VMWBSDSR1DBA01','WebSeries'
UNION ALL
SELECT  'VMWBSPRO1DBA01',NULL,'VMWBSDSR1DBA01','directdebit'

UNION ALL
SELECT  'VMCLUPRO1DBA01','VMCLUPRO2DBA01','VMCLUPRO4DBA01','AssetLiability'
UNION ALL
SELECT  'VMCLUPRO1DBA01','VMCLUPRO2DBA01','VMCLUPRO4DBA01','Budget'
UNION ALL
SELECT  'VMCLUPRO1DBA01','VMCLUPRO2DBA01','VMCLUPRO4DBA01','Client'
UNION ALL
SELECT  'VMCLUPRO1DBA01','VMCLUPRO2DBA01','VMCLUPRO4DBA01','ClientHistoryAudit'
UNION ALL
SELECT  'VMCLUPRO1DBA01','VMCLUPRO2DBA01','VMCLUPRO4DBA01','ClientSolution'
UNION ALL
SELECT  'VMCLUPRO1DBA01','VMCLUPRO2DBA01','VMCLUPRO4DBA01','Communications'
UNION ALL
SELECT  'VMCLUPRO1DBA01','VMCLUPRO2DBA01','VMCLUPRO4DBA01','Imaging'
UNION ALL
SELECT  'VMCLUPRO1DBA01','VMCLUPRO2DBA01','VMCLUPRO4DBA01','Note'
UNION ALL
SELECT  'VMCLUPRO1DBA01','VMCLUPRO2DBA01','VMCLUPRO4DBA01','NoteHistoryAudit'
UNION ALL
SELECT  'VMCLUPRO1DBA01','VMCLUPRO2DBA01','VMCLUPRO4DBA01','TaskReminders'

--UNION ALL
--SELECT  'VMCLUPRO2DBA01','VMCLUPRO1DBA01','VMCLUPRO4DBA01','AssetLiability'
--UNION ALL
--SELECT  'VMCLUPRO2DBA01','VMCLUPRO1DBA01','VMCLUPRO4DBA01','Budget'
--UNION ALL
--SELECT  'VMCLUPRO2DBA01','VMCLUPRO1DBA01','VMCLUPRO4DBA01','Client'
--UNION ALL
--SELECT  'VMCLUPRO2DBA01','VMCLUPRO1DBA01','VMCLUPRO4DBA01','ClientHistoryAudit'
--UNION ALL
--SELECT  'VMCLUPRO2DBA01','VMCLUPRO1DBA01','VMCLUPRO4DBA01','ClientSolution'
--UNION ALL
--SELECT  'VMCLUPRO2DBA01','VMCLUPRO1DBA01','VMCLUPRO4DBA01','Communications'
--UNION ALL
--SELECT  'VMCLUPRO2DBA01','VMCLUPRO1DBA01','VMCLUPRO4DBA01','Imaging'
--UNION ALL
--SELECT  'VMCLUPRO2DBA01','VMCLUPRO1DBA01','VMCLUPRO4DBA01','Note'
--UNION ALL
--SELECT  'VMCLUPRO2DBA01','VMCLUPRO1DBA01','VMCLUPRO4DBA01','NoteHistoryAudit'
--UNION ALL
--SELECT  'VMCLUPRO2DBA01','VMCLUPRO1DBA01','VMCLUPRO4DBA01','TaskReminders'

UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Assets.Subscriptions]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Assets.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Assets.Writer.Sagas]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Assets.Writer.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Bus2DCS.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Bus2DMS.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Client.Subscriptions]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Client.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Client.Writer.Sagas]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Client.Writer.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.ClientSolution.Subscriptions]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.ClientSolution.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.ClientSolution.Writer.Sagas]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.ClientSolution.Writer.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Colleague.Writer.Subscriptions]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Colleague.Writer.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Communications.Subscriptions]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Communications.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Communications.Writer.Sagas]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Communications.Writer.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.DCS.Sagas]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.DCS.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.DCSBudget.Subscriptions]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.DCSBudget.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.DCSBudget.Writer.Sagas]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.DCSBudget.Writer.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.DirectDebit.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.DMS.Sagas]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.DMS.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Imaging.Subscriptions]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Imaging.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Imaging.Writer.Sagas]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Imaging.Writer.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Notes.Subscriptions]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Notes.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Notes.Writer.Sagas]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Notes.Writer.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.TaskReminders.Subscriptions]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.TaskReminders.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.TaskReminders.Writer.Sagas]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.TaskReminders.Writer.Timeouts]'
UNION ALL
SELECT  'VMNSBPRO2DBA01','VMNSBPRO3DBA01',' VMNSBPRO5DBA01','[NSB.Transport]'

--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Assets.Subscriptions]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Assets.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Assets.Writer.Sagas]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Assets.Writer.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Bus2DCS.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Bus2DMS.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Client.Subscriptions]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Client.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Client.Writer.Sagas]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Client.Writer.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.ClientSolution.Subscriptions]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.ClientSolution.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.ClientSolution.Writer.Sagas]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.ClientSolution.Writer.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Colleague.Writer.Subscriptions]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Colleague.Writer.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Communications.Subscriptions]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Communications.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Communications.Writer.Sagas]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Communications.Writer.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.DCS.Sagas]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.DCS.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.DCSBudget.Subscriptions]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.DCSBudget.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.DCSBudget.Writer.Sagas]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.DCSBudget.Writer.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.DirectDebit.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.DMS.Sagas]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.DMS.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Imaging.Subscriptions]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Imaging.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Imaging.Writer.Sagas]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Imaging.Writer.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Notes.Subscriptions]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Notes.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Notes.Writer.Sagas]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Notes.Writer.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.TaskReminders.Subscriptions]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.TaskReminders.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.TaskReminders.Writer.Sagas]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.TaskReminders.Writer.Timeouts]'
--UNION ALL
--SELECT  'VMNSBPRO3DBA01','VMNSBPRO2DBA01',' VMNSBPRO5DBA01','[NSB.Transport]'


/* now loop through each of the servers to pull back all the APP jobs */
DECLARE SvrCursor CURSOR FAST_FORWARD FOR
	SELECT	ProductionServer,
			HAServer,
			DRServer,
			DatabaseName
	FROM #AllServers ;

OPEN SvrCursor
FETCH NEXT FROM SvrCursor
	INTO @ProdSvr,@HASvr,@DRSvr,@DatabaseName;
	
WHILE @@FETCH_STATUS = 0
BEGIN	

	PRINT @ProdSvr;
	PRINT @HASvr;
	PRINT @DRSvr;
	
	/* Drop all temp tables */
	IF OBJECT_ID('tempdb..##HALogins') IS NOT NULL
	BEGIN
		DROP TABLE ##HALogins;
	END;
	IF OBJECT_ID('tempdb..##ProductionLogins') IS NOT NULL
	BEGIN
		DROP TABLE ##ProductionLogins;
	END;
	IF OBJECT_ID('tempdb..##DRLogins') IS NOT NULL
	BEGIN
		DROP TABLE ##DRLogins;
	END;

	/* Build connections strings */
	SET @ProdConn = 'Server=' + @ProdSvr + ';Trusted_Connection=yes;';
	SET @HAConn = 'Server=' + @HASvr + ';Trusted_Connection=yes;';
	SET @DRConn = 'Server=' + @DRSvr + ';Trusted_Connection=yes;';

	/* Clear any existing data for the server */
	IF EXISTS(SELECT * FROM #OutOfSyncLogins WHERE ProductionServer = @ProdSvr AND DatabaseName = @DatabaseName)
	BEGIN
		DELETE FROM #OutOfSyncLogins WHERE ProductionServer = @ProdSvr AND DatabaseName = @DatabaseName;
	END;

	/* Get High availability server jobs */
	IF @HASvr IS NOT NULL 
	BEGIN	
		SET @SQL = '
		SELECT a.*
		INTO ##HALogins	
		FROM OPENROWSET(''SQLNCLI'', ''' + @HAConn + ''',
			 ''SELECT	sp.name AS LoginName, 
						sp.[type] AS LoginType, 
						sp.[sid] AS LoginSID,
						LOGINPROPERTY( sp.name, ''''PasswordHash'''' ) AS PasswordHash
				FROM sys.server_principals sp
				WHERE sp.type IN (''''S'''',''''U'''',''''G'''')
				AND sp.name NOT IN (''''sa'''',''''NT AUTHORITY\SYSTEM'''',''''SQLCompare'''')
				AND sp.name NOT LIKE ''''' + LEFT(@HASvr,15) + '%'''';'') AS a;';

		PRINT @SQL
		EXEC (@SQL);
	
	END ;

	/* Get production server jobs - only those with a user in a HADR database*/
	SET @SQL = '
	SELECT a.*
	INTO ##ProductionLogins	
	FROM OPENROWSET(''SQLNCLI'', ''' + @ProdConn + ''',
		 ''	SELECT	sp.name AS LoginName, 
					sp.[type] AS LoginType, 
					sp.[sid] AS LoginSID,
					LOGINPROPERTY( sp.name, ''''PasswordHash'''' ) AS PasswordHash
			FROM sys.server_principals sp
					INNER JOIN ' + @DatabaseName + '.sys.database_principals dp
					ON sp.[sid] = dp.[sid]
			WHERE sp.type IN (''''S'''',''''U'''',''''G'''')
			AND sp.name NOT IN (''''sa'''',''''NT AUTHORITY\SYSTEM'''',''''SQLCompare'''')
			AND sp.name NOT LIKE ''''' + LEFT(@ProdSvr,15) + '%'''';'') AS a;';

	PRINT @SQL
	EXEC (@SQL);

	/* Get disaster recovery server jobs */
	IF @DRSvr IS NOT NULL 
	BEGIN 
		SET @SQL = '
		SELECT a.*
		INTO ##DRLogins	
		FROM OPENROWSET(''SQLNCLI'', ''' + @DRConn + ''',
			 ''SELECT	sp.name AS LoginName, 
						sp.[type] AS LoginType, 
						sp.[sid] AS LoginSID,
						LOGINPROPERTY( sp.name, ''''PasswordHash'''' ) AS PasswordHash
				FROM sys.server_principals sp
				WHERE sp.type IN (''''S'''',''''U'''',''''G'''')
				AND sp.name NOT IN (''''sa'''',''''NT AUTHORITY\SYSTEM'''',''''SQLCompare'''')
				AND sp.name NOT LIKE ''''' + LEFT(@DRSvr,15) + '%'''';'') AS a;';
		
		PRINT @SQL
		EXEC (@SQL);
	
	END ;
	

	/* record all jobs out of sync on the HA server */
	IF @HASvr IS NOT NULL 
	BEGIN
		INSERT INTO #OutOfSyncLogins
				( ProductionServer, LoginName, LoginType, OutOfSyncServer, DatabaseName )
		SELECT @ProdSvr, LoginName, LoginType, @HASvr, @DatabaseName
		FROM (		
		SELECT * FROM ##ProductionLogins
		EXCEPT
		SELECT * FROM ##HALogins ) AS a;
	END;

	/* record all jobs out of sync on the DR server */
	IF @DRSvr IS NOT NULL 
	BEGIN 
		INSERT INTO #OutOfSyncLogins
				( ProductionServer, LoginName, LoginType, OutOfSyncServer, DatabaseName )
		SELECT @ProdSvr, LoginName, LoginType, @DRSvr, @DatabaseName
		FROM (		
		SELECT * FROM ##ProductionLogins
		EXCEPT
		SELECT * FROM ##DRLogins ) AS a;
	END ;
	
	FETCH NEXT FROM SvrCursor
		INTO @ProdSvr,@HASvr,@DRSvr,@DatabaseName;
END 

CLOSE SvrCursor
DEALLOCATE SvrCursor

/* remove any entries that are not applicable i.e. snapdrive */
DELETE FROM #OutOfSyncLogins
WHERE /* Remove general accounts from all servers */
	LoginName IN ('CCCSNT\snapdrive','PeformanceDataCollectorUser','CCCSNT\thomasb','CCCSNT\radmin'
		,'CCCSNT\andrews','CCCSNT\stefanos','CCCSNT\jeffreym','CCCSNT\Systems Application Support'
		,'##MS_PolicyEventProcessingLogin##','##MS_PolicyTsqlExecutionLogin##','ReportingServices')
/* remove any service accounts */		
OR LoginName LIKE '%_MSSQL'
OR LoginName LIKE '%_SSAS'
OR LoginName LIKE '%_SQLAGENT'
/* 'LinkedServerLogin','PDDUser' are used for linked servers that are currently setup and working in Halifax so i dont want to change them
	'DMS_BMI_DWExtract' - not sure which is the correct password to use as extract are taken from the HA server, not changing
    'tcs_user' and 'CWSRefreshUser' is present for both DMS and DCS on the HA server so can never get in sync */
OR (LoginName IN ('LinkedServerLogin','PDDUser','DMS_BMI_DWExtract') 
		AND ProductionServer = 'LDSDMSPRO1DBA01')
OR (LoginName IN ('tcs_user','CWSRefreshUser') 
		AND OutOfSyncServer = 'LDSGENDSR1DBA01')		
/* 'Sqlserverlink' are used for linked servers that are currently setup and working in Halifax so i dont want to change them
	'DCS_BMI_DWExtract' - not sure which is the correct password to use as extract are taken from the HA server, not changing */
OR (LoginName IN ('Sqlserverlink','PDDUser','DCS_BMI_DWExtract') 
		AND ProductionServer = 'LDSDCSPRO1DBA01')	
/* 'DMSSQLServerLink' is used for linked servers that are currently setup and working in Halifax so i dont want to change them
	'DCS_BMI_DWExtract' - not sure which is the correct password to use as extract are taken from the HA server, not changing */
OR (LoginName IN ('DMSSQLServerLink','CCCSVA\tech') 
		AND ProductionServer = 'LDSGENPRO1DBA03')			
OR (LoginName IN ('ReProposalsUser') 
		AND ProductionServer = 'LDSDMSPRO1DBA01' AND OutOfSyncServer = 'LDSGENDSR1DBA01') -- exists with a different login name because DCS has this login too
OR (LoginName IN ('ThirdPartyAgreementUser') 
		AND ProductionServer = 'LDSDMSPRO1DBA01' AND OutOfSyncServer = 'LDSGENDSR1DBA01') -- exists with a different login name because DCS has this login too
/* remove accounts for general server that are for DBs that are not part of HADR */			
--OR (LoginName IN ('CCCSNT\MX-Contact Users','CCCSNT\MX-Contact Administrators','CCCSNT\PDD Users','CCCSNT\Quality'
--	,'CCCSNT\Human Resources Department','CCCSNT\Business Information Team','CCCSNT\NMonitor','safecom'
--	,'Avast_User','ClientRetention','iFACE_BMI_DWEXTRACT','iFACE_User','PddDbUser','PDDUser','PDDUsers'
--	,'QuestionnaireDBUser','AutomationTest','CallTrackingUser','','') 
--		AND ProductionServer = 'LDSGENPRO1DBA02')
--OR /* Majority of the users excluded are created in prod for Docutrieve which is not part of HADR */
--   /* If Docutrieve ever becomes part of HADR then these login exceptions will need to be removed */
--	(LoginName IN ('CCCSNT\JUTAdmins','CCCSNT\JUTUsers','CCCSNT\Systems Environment Team','CCCSNT\Client Support'
--	,'CCCSNT\Customer Services','CCCSNT\Debt Management Services Security Group','CCCSNT\DocuTrieve Storage Master Users'
--	,'CCCSNT\DocuTrieve Users','CCCSNT\DRO Follow Up System','CCCSNT\DRO Follow Up System Team Leaders','CCCSNT\Finance'
--	,'CCCSNT\Leeds Counselling Support','CCCSNT\Leeds Counsellors','CCCSNT\Limavady','CCCSNT\South East','CCCSNT\Training'
--	,'CCCSNT\Kaspersky','CCCSNT\CreditBureau','CCCSNT\droapppool','CCCSNT\droreportingservices','CCCSNT\droservice'
--	,'CCCSNT\anthonyb','CCCSVA\tech') 
--		AND ProductionServer = 'LDSGENPRO1DBA03');

/* return result set if any exists */
SELECT	ProductionServer, 
		LoginName, 
		CASE LoginType
				WHEN 'S' THEN 'SQL Login'
				WHEN 'U' THEN 'Windows User'
				WHEN 'G' THEN 'Windows Group'
		END AS LoginType, 
		OutOfSyncServer ,
		DatabaseName
FROM #OutOfSyncLogins
ORDER BY loginName

/*
SELECT * FROM ##ProductionLogins
where logintype = 'S'
--and loginName = 'DMS_BMI_DWExtract'
order by LoginName;
SELECT * FROM ##HALogins
where logintype = 'S'
--and loginName = 'DMS_BMI_DWExtract'
order by LoginName;
SELECT * FROM ##DRLogins 
where logintype = 'S'
--and loginName = 'DMS_BMI_DWExtract'
order by LoginName;

SELECT * FROM ##ProductionLogins
		EXCEPT
		SELECT * FROM ##DRLogins
*/