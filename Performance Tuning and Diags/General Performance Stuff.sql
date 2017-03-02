DBCC FREEPROCCACHE			-- Purge all execution plans on the server
DBCC DROPCLEANBUFFERS


-- STATISTICS INFORMATION
-- To view IO stats
SET STATISTICS IO ON
GO

Select * from tblclient

SET STATISTICS IO OFF
GO
-- 

-- To view compile and execution duration
SET STATISTICS TIME ON
GO

Select * from tblclient

SET STATISTICS TIME OFF
GO

-- A parse time of 0ms indicates the Qery Optimiser used a compiled plan