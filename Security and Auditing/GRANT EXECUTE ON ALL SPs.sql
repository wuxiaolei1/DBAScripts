DECLARE @spname NVARCHAR (255)
DECLARE @cmd NVARCHAR (255)

DECLARE spgrant_cursor CURSOR FOR 

SELECT [name] FROM SYSOBJECTS WHERE type = 'P' AND OBJECTPROPERTY(ID,N'IsMSShipped') = 0

OPEN spgrant_cursor

FETCH NEXT FROM spgrant_cursor INTO @spname
WHILE (@@fetch_status = 0)
BEGIN
SET @cmd = 'GRANT EXECUTE ON '+ @spname+ ' to vcuser'
EXEC SP_EXECUTESQL @cmd
PRINT @cmd
FETCH NEXT FROM spgrant_cursor INTO @spname
END

CLOSE spgrant_cursor
DEALLOCATE spgrant_cursor