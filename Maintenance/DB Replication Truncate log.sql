-------------------------------------------------
-- ++ Created by PaulB							-
-- ++ Created on 09/03/2009						-
-- ++ Reduces transaction log size of			-
-- ++ databases in non-live environments that	-
-- ++ were replication enabled in live.			-
-------------------------------------------------	 


-- Press CTRL+SHIFT+M and set DB value to the name of the database.

-- Step one, sets the database to publisher.
sp_replicationdboption '<DB, VARCHAR (100), >','publish','true' 

-- Step two, marks all the transactions in the log as replicated.
USE <DB, VARCHAR (100), >
EXEC sp_repldone @xactid = NULL, @xact_segno = NULL, @numtrans = 0,     @time = 0, @reset = 1

-- Step three, truncates the log without backing it up.
BACKUP LOG <DB, VARCHAR (100), > WITH TRUNCATE_ONLY 

-- Step four, sets the database back to non-publisher.
sp_replicationdboption '<DB, VARCHAR (100), >','publish','false' 