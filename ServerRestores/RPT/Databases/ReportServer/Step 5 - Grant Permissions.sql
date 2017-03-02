:on error exit
SET NOCOUNT ON
Print 'Step 5 - Grant Permissions - ReportServer'

-- Re-establish multi-user access
ALTER DATABASE [ReportServer] SET MULTI_USER;

USE ReportServer
GO
DECLARE @AssociatedDatabase VARCHAR(30)
DECLARE @Environment VARCHAR(10)
SET @AssociatedDatabase = $(DBName)
SET @Environment = $(Environment)

IF  NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'CCCSNT\VM_SSRS')
CREATE USER [CCCSNT\VM_SSRS] FOR LOGIN [CCCSNT\VM_SSRS]
GO

IF  EXISTS (SELECT * FROM sys.schemas WHERE name = N'CCCSNT\VM_SSRS')
DROP SCHEMA [CCCSNT\VM_SSRS]
GO

CREATE SCHEMA [CCCSNT\VM_SSRS] AUTHORIZATION [CCCSNT\VM_SSRS]
GO

ALTER USER [CCCSNT\VM_SSRS] WITH DEFAULT_SCHEMA=[CCCSNT\VM_SSRS]

EXEC sp_addrolemember 'RSExecRole', 'CCCSNT\VM_SSRS'
GO
EXEC sp_addrolemember 'db_owner', 'RSExecRole'
GO
