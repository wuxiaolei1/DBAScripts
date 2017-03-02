
/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 3 - Update Application Settings .sql"

--- */
PRINT 'Step 3 - Update Application Settings - WebSeries';

USE [VisionBlue_Training]

-- Update Template Locations

UPDATE  TBL_SYSTEM
SET     REPORT_TEMPLATE_FOLDER = '\\vmvbldev1app01\Visionblue Solutions\VisionBlue Training\Custom Templates' ,
        REPORT_OUTPUT_FOLDER = '\\vmvbldev1app01\Visionblue Solutions\VisionBlue Training\Generated Documentation' ,
		[EMAIL_ATTACHMENTS_FOLDER] = '\\vmvbldev1app01\Visionblue Solutions\VisionBlue Training\EmailAttachments',
        [IAT_EXPORT_LOCATION] = '\\vadmcpro1app01\Shared\Training\VisionBlue\Interface Files\IAT Files\' ,
		[REMITTANCE_EXPORT_FOLDER] = '\\vadmcpro1app01\Shared\Training\VisionBlue\Interface Files\BACS Remittances\' ,
        [CHEQUE_EXPORT_LOCATION] = '\\vadmcpro1app01\Shared\Training\VisionBlue\Interface Files\Cheque Payments\' ,
		[CHEQUEFILE_OUTPUT_DIRECTORY] = '\\vadmcpro1app01\Shared\Training\VisionBlue\Interface Files\Cheque Payments\' ,
        [BACS_EXPORT_LOCATION] = '\\vadmcpro1app01\Shared\Training\VisionBlue\Interface Files\BACS Payments\' ,
        [DD_EXPORT_LOCATION] = '\\vadmcpro1app01\Shared\Training\VisionBlue\Interface Files\DD Collections\',
		[SERIAL_NUMBER] = '989';