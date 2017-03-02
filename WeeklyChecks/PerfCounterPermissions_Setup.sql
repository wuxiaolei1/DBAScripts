USE SystemsHelpDesk
GO

CREATE TABLE [dbo].[CounterData](
	[GUID] [uniqueidentifier] NOT NULL,
	[CounterID] [int] NOT NULL,
	[RecordIndex] [int] NOT NULL,
	[CounterDateTime] [char](24) NOT NULL,
	[CounterValue] [float] NOT NULL,
	[FirstValueA] [int] NULL,
	[FirstValueB] [int] NULL,
	[SecondValueA] [int] NULL,
	[SecondValueB] [int] NULL,
	[MultiCount] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[GUID] ASC,
	[CounterID] ASC,
	[RecordIndex] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

CREATE TABLE [dbo].[CounterDetails](
	[CounterID] [int] IDENTITY(1,1) NOT NULL,
	[MachineName] [varchar](1024) NOT NULL,
	[ObjectName] [varchar](1024) NOT NULL,
	[CounterName] [varchar](1024) NOT NULL,
	[CounterType] [int] NOT NULL,
	[DefaultScale] [int] NOT NULL,
	[InstanceName] [varchar](1024) NULL,
	[InstanceIndex] [int] NULL,
	[ParentName] [varchar](1024) NULL,
	[ParentObjectID] [int] NULL,
	[TimeBaseA] [int] NULL,
	[TimeBaseB] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[CounterID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

CREATE TABLE [dbo].[DisplayToID](
	[GUID] [uniqueidentifier] NOT NULL,
	[RunID] [int] NULL,
	[DisplayString] [varchar](1024) NOT NULL,
	[LogStartTime] [char](24) NULL,
	[LogStopTime] [char](24) NULL,
	[NumberOfRecords] [int] NULL,
	[MinutesToUTC] [int] NULL,
	[TimeZoneName] [char](32) NULL,
PRIMARY KEY CLUSTERED 
(
	[GUID] ASC
) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[DisplayString] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.CounterData TO [NT AUTHORITY\NETWORK SERVICE]
GO

GRANT SELECT, UPDATE, DELETE, INSERT ON dbo.CounterDetails TO [NT AUTHORITY\NETWORK SERVICE]
GO

GRANT SELECT, UPDATE, DELETE, INSERT  ON dbo.DisplayToID TO [NT AUTHORITY\NETWORK SERVICE]
GO

