:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
PRINT 'Step 2 - Scramble Data - ShoreTelECC'

USE ShoreTelECC
GO

DECLARE @Environment VARCHAR(50)
SET @Environment = $(Environment)

TRUNCATE TABLE dbo.ClientCallRouting
GO
TRUNCATE TABLE dbo.ClientCallRoutingVA
GO
UPDATE dbo.Transcripts SET TranscriptXML = NULL
GO
TRUNCATE TABLE dbo.UnwantedNumbers
GO
