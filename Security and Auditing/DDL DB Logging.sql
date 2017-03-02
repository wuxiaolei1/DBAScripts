-- DDL Logging setup
USE <<DATABASENAMEHERE>> 
GO 
IF  EXISTS (SELECT * FROM sys.triggers WHERE name = N'TRG_DDLAudit' AND parent_class=0)
BEGIN 
	DROP TRIGGER [TRG_DDLAudit] ON DATABASE ;
	PRINT 'Dropped Trigger: TRG_DDLAudit' ;
END 	
GO 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Audit].[DDLEvents]') AND type in (N'U'))
BEGIN 
	DROP TABLE [Audit].[DDLEvents] ;
	PRINT 'Dropped TABLE: Audit.DDLEvents' ;
END 
GO
IF  EXISTS (SELECT * FROM sys.schemas WHERE name = N'Audit')
BEGIN 
	DROP SCHEMA [Audit] ;
	PRINT 'Dropped Schema: Audit' ;
END 
GO 

CREATE SCHEMA [Audit] AUTHORIZATION [dbo]
GO

CREATE TABLE Audit.DDLEvents(
	LogId INT IDENTITY(1,1) NOT NULL,
	EventDate DATETIME NOT NULL CONSTRAINT DF_DDLEvents_EventDate  DEFAULT (GETDATE()),
	DatabaseName VARCHAR (256) NOT NULL,
	EventType VARCHAR(50) NOT NULL,
	--Allow NULLS for SchemaName as EVENTDATA can capture same data twice for CREATE SCHEMA events
	SchemaName VARCHAR(256) NULL,
	--Allow NULL values for ObjectName and ObjectType (needed for Compatibility Level 80 Databases)
	ObjectName VARCHAR(256) NULL,
	ObjectType VARCHAR(25) NULL,
	LoginName VARCHAR(256) NOT NULL,
	SqlCommand VARCHAR(MAX) NOT NULL,
	XMLEventData XML NOT NULL,
	-- Added ChangeReference to be manually populated after the event
	ChangeReference VARCHAR(256) NULL
) ;    
GO



--ADDED <<SET ARITHABORT ON>> TO IGNORE ARITH ERROR ON COMPATIBILITY LEVEL 80 DATABASES
--ADDED <<SET ANSI_WARNINGS ON>> FOR COMPATIBILITY LEVEL 80 DATABASES
CREATE TRIGGER TRG_DDLAudit ON DATABASE
    FOR DDL_DATABASE_LEVEL_EVENTS
AS
	SET ARITHABORT ON ;
	SET NOCOUNT ON ;
	SET ANSI_WARNINGS ON;
	
    DECLARE @data XML ;
    SET @data = EVENTDATA() ;
    
    INSERT INTO Audit.DDLEvents
            (
			DatabaseName,
			EventType,
			SchemaName,
			ObjectName,
			ObjectType,
			LoginName,
			SqlCommand,
			XMLEventData
            )
    VALUES  (
            @data.value('(/EVENT_INSTANCE/DatabaseName)[1]'	, 'varchar(256)'),
			@data.value('(/EVENT_INSTANCE/EventType)[1]'	, 'varchar(50)'), 
			@data.value('(/EVENT_INSTANCE/SchemaName)[1]'	, 'varchar(256)'),
			@data.value('(/EVENT_INSTANCE/ObjectName)[1]'	, 'varchar(256)'), 
			@data.value('(/EVENT_INSTANCE/ObjectType)[1]'	, 'varchar(25)'), 
			@data.value('(/EVENT_INSTANCE/LoginName)[1]'	, 'varchar(256)'),
			@data.value('(/EVENT_INSTANCE/TSQLCommand)[1]'	, 'varchar(max)'),
			@data 
            ) ;

GO
