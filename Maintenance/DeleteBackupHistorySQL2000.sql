DECLARE @DaysToRetain int
SET @DaysToRetain = 30

SET NOCOUNT ON

DECLARE @Err int


BEGIN TRAN

 DELETE FROM msdb..restorefile
 FROM msdb..restorefile rf
 INNER JOIN msdb..restorehistory rh 
 ON rf.restore_history_id = rh.restore_history_id
 INNER JOIN msdb..backupset bs 
 ON rh.backup_set_id = bs.backup_set_id
 WHERE bs.backup_finish_date < (GETDATE() - @DaysToRetain)

 SET @Err = @@ERROR

 IF @Err <> 0
  GOTO Error_Exit
 
 DELETE FROM msdb..restorefilegroup
 FROM msdb..restorefilegroup rfg
 INNER JOIN msdb..restorehistory rh 
 ON rfg.restore_history_id = rh.restore_history_id
 INNER JOIN msdb..backupset bs 
 ON rh.backup_set_id = bs.backup_set_id
 WHERE bs.backup_finish_date < (GETDATE() - @DaysToRetain)

 SET @Err = @@ERROR

 IF @Err <> 0
  GOTO Error_Exit
 
 DELETE FROM msdb..restorehistory
 FROM msdb..restorehistory rh
 INNER JOIN msdb..backupset bs 
 ON rh.backup_set_id = bs.backup_set_id
 WHERE bs.backup_finish_date < (GETDATE() - @DaysToRetain)

 SET @Err = @@ERROR

 IF @Err <> 0
  GOTO Error_Exit
 
 SELECT media_set_id, backup_finish_date
 INTO #Temp 
 FROM msdb..backupset
 WHERE backup_finish_date < (GETDATE() - @DaysToRetain)

 SET @Err = @@ERROR

 IF @Err <> 0
  GOTO Error_Exit
 
 DELETE FROM msdb..backupfile
 FROM msdb..backupfile bf
 INNER JOIN msdb..backupset bs 
 ON bf.backup_set_id = bs.backup_set_id
 INNER JOIN #Temp t
 ON bs.media_set_id = t.media_set_id
 WHERE bs.backup_finish_date < (GETDATE() - @DaysToRetain)

 SET @Err = @@ERROR

 IF @Err <> 0
  GOTO Error_Exit
 
 DELETE FROM msdb..backupset
 FROM msdb..backupset bs
 INNER JOIN #Temp t
 ON bs.media_set_id = t.media_set_id

 SET @Err = @@ERROR

 IF @Err <> 0
  GOTO Error_Exit
 
 DELETE FROM msdb..backupmediafamily
 FROM msdb..backupmediafamily bmf
 INNER JOIN msdb..backupmediaset bms 
 ON bmf.media_set_id = bms.media_set_id
 INNER JOIN #Temp t 
 ON bms.media_set_id = t.media_set_id

 SET @Err = @@ERROR

 IF @Err <> 0
  GOTO Error_Exit
 
 DELETE FROM msdb..backupmediaset
 FROM msdb..backupmediaset bms
 INNER JOIN #Temp t 
 ON bms.media_set_id = t.media_set_id

 SET @Err = @@ERROR

 IF @Err <> 0
  GOTO Error_Exit

COMMIT TRAN



GOTO isp_DeleteBackupHistory_Exit

Error_Exit:

ROLLBACK TRAN



isp_DeleteBackupHistory_Exit:

DROP TABLE #Temp

SET NOCOUNT OFF



