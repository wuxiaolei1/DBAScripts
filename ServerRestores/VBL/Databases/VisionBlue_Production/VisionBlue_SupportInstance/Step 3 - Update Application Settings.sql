
/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 3 - Update Application Settings .sql"

--- */
PRINT 'Step 3 - Update Application Settings - WebSeries';

USE [VisionBlue_Support];

-- Update Template Locations

UPDATE  TBL_SYSTEM
SET     REPORT_TEMPLATE_FOLDER = '\\vmvbldev1app01\Visionblue Solutions\VisionBlue Support\Custom Templates' ,
        REPORT_OUTPUT_FOLDER = '\\vmvbldev1app01\Visionblue Solutions\VisionBlue Support\Generated Documentation' ,
		[EMAIL_ATTACHMENTS_FOLDER] = '\\vmvbldev1app01\Visionblue Solutions\VisionBlue Support\EmailAttachments',
        [IAT_EXPORT_LOCATION] = '\\vadmcpro1app01\Shared\Systems\Support Management\VisionBlue\Interface Files\IAT Files\' ,
		[REMITTANCE_EXPORT_FOLDER] = '\\vadmcpro1app01\Shared\Systems\ Support Management\VisionBlue\Interface Files\BACS Remittances\' ,
        [CHEQUE_EXPORT_LOCATION] = '\\vadmcpro1app01\Shared\Systems\ Support Management\VisionBlue\Interface Files\Cheque Payments\' ,
		[CHEQUEFILE_OUTPUT_DIRECTORY] = '\\vadmcpro1app01\Shared\Systems\ Support Management\VisionBlue\Interface Files\Cheque Payments\' ,
        [BACS_EXPORT_LOCATION] = '\\vadmcpro1app01\Shared\Systems\ Support Management\VisionBlue\Interface Files\BACS Payments\' ,
        [DD_EXPORT_LOCATION] = '\\vadmcpro1app01\Shared\Systems\ Support Management\VisionBlue\Interface Files\DD Collections\',
		[SERIAL_NUMBER] = '989';