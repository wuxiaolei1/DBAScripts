USE msdb
go

SELECT bus.name, physical_device_name, backup_start_date 
FROM dbo.backupset BUS
				INNER JOIN 
				(
					select max(backup_set_id) maxbs, database_name from dbo.backupset
					group by database_name
				) maxbus on bus.backup_set_id = maxbus.maxbs
                INNER JOIN dbo.backupmediaset BUMS
                                ON BUS.media_set_id = BUMS.media_set_id
                INNER JOIN dbo.backupmediafamily BUMF
                                ON BUMS.media_set_id = BUMF.media_set_id
WHERE BUS.type = 'D' 
ORDER BY 3 DESC