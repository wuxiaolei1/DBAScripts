/*******************************************************************
* PURPOSE: Deletes data from SSIS_Config and SSIS_PDS based on the
*			retention period
* NOTES: 
* AUTHOR: Stefano Salvini
* CREATED DATE: 16/2/2015
* MODIFIED DETAILS
* DATE            AUTHOR                  CHGREF/DESCRIPTION
*-------------------------------------------------------------------
* {date}          {developer} {brief modification description}
*******************************************************************/

SET NOCOUNT ON;

DECLARE @RetentionDays SMALLINT
DECLARE @RetentionDate DATETIME

SET @RetentionDays = 31
SET @RetentionDate = DATEADD(dd, -@RetentionDays, GETDATE())

BEGIN TRY

    BEGIN TRANSACTION

    IF OBJECT_ID('tempdb..#BatchLogIDTable') IS NOT NULL
        DROP TABLE #BatchLogIDTable

    SELECT  BatchLogID
    INTO    #BatchLogIDTable
    FROM    dbo.BatchLog
    WHERE   StartDateTime < @RetentionDate

    DELETE  PVL
    FROM    dbo.PackageVariableLog PVL
            JOIN dbo.PackageLog PL ON PL.PackageLogID = PVL.PackageLogID
            JOIN #BatchLogIDTable BLIT ON BLIT.BatchLogID = PL.BatchLogID

    DELETE  PTL
    FROM    dbo.PackageTaskLog PTL
            JOIN dbo.PackageLog PL ON PL.PackageLogID = PTL.PackageLogID
            JOIN #BatchLogIDTable BLIT ON BLIT.BatchLogID = PL.BatchLogID

    DELETE  PEL
    FROM    dbo.PackageErrorLog PEL
            JOIN dbo.PackageLog PL ON PL.PackageLogID = PEL.PackageLogID
            JOIN #BatchLogIDTable BLIT ON BLIT.BatchLogID = PL.BatchLogID

    DELETE  PTL
    FROM    dbo.PackageTaskLog PTL
            JOIN dbo.PackageLog PL ON PL.PackageLogID = PTL.PackageLogID
            JOIN #BatchLogIDTable BLIT ON BLIT.BatchLogID = PL.BatchLogID

    DELETE  PL
    FROM    dbo.PackageLog PL
            JOIN #BatchLogIDTable BLIT ON BLIT.BatchLogID = PL.BatchLogID

    DELETE  BL
    FROM    dbo.BatchLog BL
            JOIN #BatchLogIDTable BLIT ON BLIT.BatchLogID = BL.BatchLogID

    IF OBJECT_ID('tempdb..#BatchLogIDTable') IS NOT NULL
        DROP TABLE #BatchLogIDTable

    COMMIT TRANSACTION

END TRY

BEGIN CATCH
    ROLLBACK TRANSACTION

    PRINT N'Data purging failed.';
    PRINT ERROR_MESSAGE();

END CATCH