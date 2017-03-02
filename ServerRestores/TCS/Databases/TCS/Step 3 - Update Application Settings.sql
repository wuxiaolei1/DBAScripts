
/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 3 - Update Application Settings .sql"

--- */
:on error exit
Print 'Step 3 - Update Application Settings - TCS'

USE TCS
GO

-- AS, Sep 2012 - Changed folder locations from \\sysapscomsapp02\CommsFTP\ to C:\Applications\TCS\FTP\ at the request of the Environment Team
-- TB, Aug 2015 - Changed folder locations from C:\Applications\... to C:\EVXX-Applications\... where XX is the environment number (e.g.01 for daily) at the request of the Environment Team

UPDATE dbo.ExternalCommunicationTypes
SET DCSFolderLocation = 'C:\EV' + RIGHT(LEFT(@@SERVERNAME,4),2) + '-Applications\TCS\FTP\Q' + cast(DCSQueueID as varchar) + '\'

-- DCSDMPFolderLocation
UPDATE dbo.ExternalCommunicationTypes
SET DCSDMPFolderLocation = 'C:\EV' + RIGHT(LEFT(@@SERVERNAME,4),2) + '-Applications\TCS\FTP\' + right(DCSDMPFolderLocation, len(DCSDMPFolderLocation) - charindex('\Q', DCSDMPFolderLocation))
WHERE DCSDMPFolderLocation is not NULL

-- DCSDROFolderLocation
UPDATE dbo.ExternalCommunicationTypes
SET DCSDROFolderLocation = 'C:\EV' + RIGHT(LEFT(@@SERVERNAME,4),2) + '-Applications\TCS\FTP\' + right(DCSDROFolderLocation, len(DCSDROFolderLocation) - charindex('\Q', DCSDROFolderLocation))
WHERE DCSDROFolderLocation is not NULL

-- DCSDRODMPFolderLocation
UPDATE dbo.ExternalCommunicationTypes
SET DCSDRODMPFolderLocation = 'C:\EV' + RIGHT(LEFT(@@SERVERNAME,4),2) + '-Applications\TCS\FTP\' + right(DCSDRODMPFolderLocation, len(DCSDRODMPFolderLocation) - charindex('\Q', DCSDRODMPFolderLocation))
WHERE DCSDRODMPFolderLocation is not NULL;

-- DCSDROFolderLocationNI
UPDATE dbo.ExternalCommunicationTypes
SET DCSDROFolderLocationNI = 'C:\EV' + RIGHT(LEFT(@@SERVERNAME,4),2) + '-Applications\TCS\FTP\' + right(DCSDROFolderLocationNI, len(DCSDROFolderLocationNI) - charindex('\Q', DCSDROFolderLocationNI))
WHERE DCSDROFolderLocationNI is not NULL;

-- DCSDRODMPFolderLocationNI
UPDATE dbo.ExternalCommunicationTypes
SET DCSDRODMPFolderLocationNI = 'C:\EV' + RIGHT(LEFT(@@SERVERNAME,4),2) + '-Applications\TCS\FTP\' + right(DCSDRODMPFolderLocationNI, len(DCSDRODMPFolderLocationNI) - charindex('\Q', DCSDRODMPFolderLocationNI))
WHERE DCSDRODMPFolderLocationNI is not NULL;

-- DCSDPPFolderLocation
UPDATE dbo.ExternalCommunicationTypes
SET DCSDPPFolderLocation = 'C:\EV' + RIGHT(LEFT(@@SERVERNAME,4),2) + '-Applications\TCS\FTP\' + right(DCSDPPFolderLocation, len(DCSDPPFolderLocation) - charindex('\Q', DCSDPPFolderLocation))
WHERE DCSDPPFolderLocation is not NULL;

-- DCSDPPDMPFolderLocation
UPDATE dbo.ExternalCommunicationTypes
SET DCSDPPDMPFolderLocation = 'C:\EV' + RIGHT(LEFT(@@SERVERNAME,4),2) + '-Applications\TCS\FTP\' + right(DCSDPPDMPFolderLocation, len(DCSDPPDMPFolderLocation) - charindex('\Q', DCSDPPDMPFolderLocation))
WHERE DCSDPPDMPFolderLocation is not NULL;

-- DCSMAPSEQFolderLocation
IF EXISTS (SELECT 1 FROM sys.columns WHERE name = N'DCSMAPSEQFolderLocation' AND [object_id] = OBJECT_ID(N'[dbo].[ExternalCommunicationTypes]'))
EXEC('
UPDATE dbo.ExternalCommunicationTypes
SET DCSMAPSEQFolderLocation = ''C:\EV'' + RIGHT(LEFT(@@SERVERNAME,4),2) + ''-Applications\TCS\FTP\'' + right(DCSMAPSEQFolderLocation, len(DCSMAPSEQFolderLocation) - charindex(''\Q'', DCSMAPSEQFolderLocation))
WHERE DCSMAPSEQFolderLocation is not NULL;
');

UPDATE dbo.VCProperties
SET CharValue = '"Test Debt Remedy (testing only)" <druat@stepchange.org>'
WHERE PropertyName = 'P.DebtRemedyEmail'

UPDATE	Counsellors
SET	ReviewEmail = NULL
WHERE	ISNULL(ReviewEmail,'') <> ''
GO
