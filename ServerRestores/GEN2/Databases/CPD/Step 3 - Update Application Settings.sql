
/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 3 - Update Application Settings .sql"

--- */
--:on error exit
Print 'Step 3 - Update Application Settings - CPD'
USE CPD
GO

declare @RootFolderLocation varchar (50)
set @RootFolderLocation = '\\ldsfileproapp01\non-livecpd$\'

declare @DefaultFolderLocation varchar (50)
set @DefaultFolderLocation = @RootFolderLocation + 'AUTODEP\'

/*
declare @DDMSfolderLocation varchar (100)
set @DDMSFolderlocation = '\\ldsfileproapp01\DDMS\DDMS Solutions\'
*/

--Set tbl_FileDefault Values
UPDATE dbo.[tbl_FileDefaults] SET [FieldValue] = SPACE(0)

--Debit Card Payment Export
Update tbl_FileDefaults
set FieldValue = @DEfaultFolderLocation + 'Debit Card Payments\Export'
where FieldName = 'DCPExportFile'

--Debit Card Payment Import
Update tbl_FileDefaults
set FieldValue = @DEfaultFolderLocation + 'Debit Card Payments'
where FieldName = 'DCPImportFile'

--Direct Debit Export
Update tbl_FileDefaults
set FieldValue = @DEfaultFolderLocation + 'DD\Output'
where FieldName = 'DDExportFile'

--Direct Debit import
Update tbl_FileDefaults
set FieldValue = @DEfaultFolderLocation + 'DD'
where FieldName = 'DDImportFile'

--DDMS Sweep File Location
Update tbl_FileDefaults
set FieldValue = @DEfaultFolderLocation  + 'BACS Files'
Where FieldName = 'DDMSSWEEPFILE'

--Debit Payment Card Export
Update tbl_FileDefaults
set FieldValue = @DEfaultFolderLocation + 'Debit Card Payments\Export'
where FieldName = 'DPCExportFile'

--Debit Payment Card Import
Update tbl_FileDefaults
set FieldValue = @DEfaultFolderLocation + 'Debit Card Payments'
where FieldName = 'DPCImportFile'

--Girobank Export
Update tbl_FileDefaults
set FieldValue = @DEfaultFolderLocation + 'Girobank\GI Output'
where FieldName = 'Exportlocation' or FieldName = 'GBExportlocation'

--Girobank Import
Update tbl_FileDefaults
set FieldValue = @DEfaultFolderLocation + 'Girobank'
where FieldName = 'ImportFile' or FieldName = 'GBImportFile'

--Update the Manual Deposit file location
Update tbl_fileDefaults
Set FieldValue = @DefaultFolderLocation + 'MP'
Where fieldName = 'MPExportLocation'

--Standing Order Export
Update tbl_FileDefaults
set FieldValue = @DEfaultFolderLocation + 'SO\Output'
where FieldName = 'STOExportLocation'

--Standing Order Import
Update tbl_FileDefaults
set FieldValue = @DEfaultFolderLocation + 'SO'
where FieldName = 'STOImportfile'

--Update the RF Parameters table

--Update DDERefundSSweepFile
update tbl_RF_Parameters
set value = @DEfaultFolderLocation + 'RF\RefundSweepFile'
where  Type = 'DDEREFUNDSSWEEPFILE'

--Update IMPORTFOLDER
update tbl_RF_Parameters
set value = @DEfaultFolderLocation + 'RF'
where  Type = 'IMPORTFOLDER'

--Update EXPORTFOLDER
update tbl_RF_Parameters
set value = @DEfaultFolderLocation + 'RF\Output'
where  Type = 'EXPORTFOLDER'

UPDATE dbo.[tbl_RF_Parameters] SET [Value] = SPACE(0)
WHERE UPPER([Type]) IN ('DDELASTREFUNDFILE',/*'DDEREFUNDSSWEEPFILE','IMPORTFOLDER',
'EXPORTFOLDER',*/'DATA SOURCE','INITIAL CATALOG')

-- Update the Unpaid Direct Debit parameters table

--Update DDERefundSweepFile
update tbl_UP_Parameters
set value = @RootFolderLocation + 'UnpaidDD\Refund'
where Type = 'DDERefundSweepfile'

--Update IMPORTFOLDER
update tbl_UP_Parameters
set value = @RootFolderLocation + 'UnpaidDD'
where Type = 'IMPORTFOLDER'

--Update EXPORTFOLDER
Update tbl_UP_Parameters
set value = @RootFolderLocation + 'UnpaidDD\Output'
where Type = 'EXPORTFOLDER'

UPDATE dbo.[tbl_MP_Parameters] SET [ValueIS] = SPACE(0)
WHERE UPPER([Type]) = 'LASTFILENAME'


