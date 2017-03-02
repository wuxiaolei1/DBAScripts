
/* Enable global deadlock tracing (SQL Server 2005/8) */

DBCC TRACEON (1222, -1);
GO

DBCC TRACESTATUS (-1);
GO


/* SQL 2012							*/
/* 1204 by Node						*/
/* 1222 ny processes and resource	*/
DBCC TRACEON (1204, 1222)
