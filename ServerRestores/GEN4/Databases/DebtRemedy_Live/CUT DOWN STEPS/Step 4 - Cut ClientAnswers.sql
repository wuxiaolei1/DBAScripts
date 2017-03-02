----------------------------------------------------------------
-- Script Created By Tom Braham on 11/01/2011
--
-- This script will be executed as part of the Debt Remedy cut down process. 
-- osql cmd to execute the script is
-- 
-- osql -S LDSCUTPRO1DBA01\SQL2000 -d DebtRemedy_Live -E -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\GENPRO1DBA01\Databases\DebtRemedy_Live\CUT DOWN STEPS\Step 4 - Cut ClientAnswers.sql" -o "E:\SQLOutput\DR_Step4.txt"
--
-- Script to cut down the ClientAnswers table by
-- 1. Dropping default constraints on ClientAnswers table
-- 2. Creating replica of ClientAnswers table called ClientAnswers_Temp
-- 3. Inserting the values that we want to keep into ClientAnswers_Temp from ClientAnswers
-- 4. Drop ClientAnswers table
-- 5. Rename ClientAnswers_Temp to ClientAnswers
-- 6. recreate the constarints, keys and indexes on ClientAnswers
----------------------------------------------------------------


USE DebtRemedy_live
GO
-- drop constraints
ALTER TABLE [dbo].[ClientAnswers] DROP CONSTRAINT [DF_ClientAnswers_AgreementThreshold];
ALTER TABLE [dbo].[ClientAnswers] DROP CONSTRAINT [DF_ClientAnswers_ClientAnswersId];
ALTER TABLE [dbo].[ClientAnswers] DROP CONSTRAINT [DF_ClientAnswers_ForDiscussion];
ALTER TABLE [dbo].[ClientAnswers] DROP CONSTRAINT [DF_ClientAnswers_Index];
ALTER TABLE [dbo].[ClientAnswers] DROP CONSTRAINT [DF_ClientAnswers_IsNew];
ALTER TABLE [dbo].[ClientAnswers] DROP CONSTRAINT [DF_ClientAnswers_State];

----
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ClientAnswers_Temp](
	[ClientAnswersID] [uniqueidentifier] ROWGUIDCOL  NOT NULL CONSTRAINT [DF_ClientAnswers_ClientAnswersId]  DEFAULT (convert(uniqueidentifier,(convert(binary(10),newid()) + convert(binary(6),getdate())))),
	[ClientID] [uniqueidentifier] NOT NULL,
	[DataItemID] [uniqueidentifier] NOT NULL,
	[Index] [tinyint] NOT NULL CONSTRAINT [DF_ClientAnswers_Index]  DEFAULT (0),
	[TypeRequired] [varchar](10) NOT NULL,
	[BoolValue] [bit] NULL,
	[IntValue] [int] NULL,
	[CharValue] [varchar](6500) NULL,
	[CurrencyValue] [int] NULL,
	[DateValue] [datetime] NULL,
	[CodeHistoryIdValue] [uniqueidentifier] NULL,
	[IsBlank] [bit] NOT NULL,
	[State] [tinyint] NOT NULL CONSTRAINT [DF_ClientAnswers_State]  DEFAULT (0),
	[Agreed] [bit] NOT NULL CONSTRAINT [DF_ClientAnswers_ForDiscussion]  DEFAULT (1),
	[AgreementThreshold] [tinyint] NOT NULL CONSTRAINT [DF_ClientAnswers_AgreementThreshold]  DEFAULT (0),
	[Guideline_Min] [int] NULL,
	[Guideline_Max] [int] NULL,
	[IsNew] [bit] NOT NULL CONSTRAINT [DF_ClientAnswers_IsNew]  DEFAULT (1),
	[FloatValue] [float] NULL,
	[Guideline_Default] [int] NULL
) ON [PRIMARY]
GO 

ALTER TABLE [dbo].[ClientAnswers_Temp] ADD  CONSTRAINT [PKC_ClientAnswers] PRIMARY KEY CLUSTERED 
(
	[ClientID] ASC,
	[DataItemID] ASC,
	[Index] ASC
);

--No date on client answers so reference
-- clients table on LastLoginTime

INSERT  INTO dbo.ClientAnswers_Temp
        SELECT  clientanswers.*
        FROM    dbo.ClientAnswers
                INNER JOIN dbo.clients ON ClientAnswers.ClientID = Clients.ClientID
        WHERE   Clients.LastLoginTime > DATEADD(m, -6, GETDATE())
GO

DROP TABLE dbo.ClientAnswers;
GO
-- rename the table 
EXECUTE sp_rename 'ClientAnswers_Temp','ClientAnswers';
GO

-- create constraints and keys
ALTER TABLE [dbo].[ClientAnswers]  WITH NOCHECK ADD  CONSTRAINT [FK_ClientAnswers_Clients] FOREIGN KEY([ClientID])
REFERENCES [dbo].[Clients] ([ClientID])
NOT FOR REPLICATION ;
ALTER TABLE [dbo].[ClientAnswers] CHECK CONSTRAINT [FK_ClientAnswers_Clients]
;
ALTER TABLE [dbo].[ClientAnswers]  WITH NOCHECK ADD  CONSTRAINT [FK_ClientAnswers_CodesHistory] FOREIGN KEY([CodeHistoryIdValue])
REFERENCES [dbo].[CodesHistory] ([CodesHistoryID])
NOT FOR REPLICATION ;
ALTER TABLE [dbo].[ClientAnswers] CHECK CONSTRAINT [FK_ClientAnswers_CodesHistory]
;
ALTER TABLE [dbo].[ClientAnswers]  WITH NOCHECK ADD  CONSTRAINT [FK_ClientAnswers_DataItems] FOREIGN KEY([DataItemID], [TypeRequired])
REFERENCES [dbo].[DataItems] ([DataItemID], [TypeRequired])
ON UPDATE CASCADE
NOT FOR REPLICATION;
ALTER TABLE [dbo].[ClientAnswers] CHECK CONSTRAINT [FK_ClientAnswers_DataItems]
;
ALTER TABLE [dbo].[ClientAnswers]  WITH CHECK ADD  CONSTRAINT [CK_ClientAnswers_Guidelines] CHECK  (([Guideline_Min] is null and [Guideline_Max] is null and [Guideline_Default] is null or [Guideline_Min] is not null and [Guideline_Max] is not null and [Guideline_Default] is not null and [TypeRequired] = 'CURRENCY' and [Guideline_Min] <= [Guideline_Max] and [Guideline_Min] <= [Guideline_Default] and [Guideline_Default] <= [Guideline_Max]));
ALTER TABLE [dbo].[ClientAnswers] CHECK CONSTRAINT [CK_ClientAnswers_Guidelines];
ALTER TABLE [dbo].[ClientAnswers]  WITH CHECK ADD  CONSTRAINT [CK_ClientAnswers_ValidTypes] CHECK  (([TypeRequired] = 'BOOL' and [BoolValue] is not null and [IntValue] is null and [CharValue] is null and [CurrencyValue] is null and [DateValue] is null and [IsBlank] = 0 and ([State] = 6 or ([State] = 3 or ([State] = 2 or ([State] = 1 or [State] = 0)))) or [TypeRequired] = 'CHAR' and [BoolValue] is null and [IntValue] is null and [CharValue] is not null and [CurrencyValue] is null and [DateValue] is null and [IsBlank] = 0 and ([State] = 6 or ([State] = 3 or ([State] = 2 or ([State] = 1 or [State] = 0)))) or [TypeRequired] = 'INT' and [BoolValue] is null and [IntValue] is not null and [CharValue] is null and [CurrencyValue] is null and [DateValue] is null and [IsBlank] = 0 and ([State] = 6 or ([State] = 3 or ([State] = 2 or ([State] = 1 or [State] = 0)))) or [TypeRequired] = 'CURRENCY' and [BoolValue] is null and [IntValue] is null and [CharValue] is null and [CurrencyValue] is not null and [DateValue] is null and [IsBlank] = 0 and ([State] = 6 or ([State] = 3 or ([State] = 2 or ([State] = 1 or [State] = 0)))) or [TypeRequired] = 'CODEID' and [BoolValue] is null and [IntValue] is null and [CharValue] is null and [CurrencyValue] is null and [DateValue] is null and [IsBlank] = 0 and ([State] = 6 or ([State] = 3 or ([State] = 2 or ([State] = 1 or [State] = 0)))) or [TypeRequired] = 'DATE' and [BoolValue] is null and [IntValue] is null and [CharValue] is null and [CurrencyValue] is null and [DateValue] is not null and [IsBlank] = 0 and ([State] = 6 or ([State] = 3 or ([State] = 2 or ([State] = 1 or [State] = 0)))) or ([TypeRequired] = 'BOOL' or [TypeRequired] = 'CHAR' or [TypeRequired] = 'INT' or [TypeRequired] = 'CURRENCY' or [TypeRequired] = 'CODEID' or [TypeRequired] = 'DATE') and ([BoolValue] is null and [IntValue] is null and [CharValue] is null and [CurrencyValue] is null and [DateValue] is null and ([IsBlank] = 1 or ([State] = 1 or [State] = 0)))));
ALTER TABLE [dbo].[ClientAnswers] CHECK CONSTRAINT [CK_ClientAnswers_ValidTypes];

-- create indexes
CREATE UNIQUE NONCLUSTERED INDEX [index_2080882630] ON [dbo].[ClientAnswers] 
(
	[ClientAnswersID] ASC
)
; 
CREATE NONCLUSTERED INDEX [UK_ndx_ClientAnswers1] ON [dbo].[ClientAnswers] 
(
	[ClientID] ASC,
	[State] ASC,
	[DataItemID] ASC,
	[TypeRequired] ASC,
	[CurrencyValue] ASC
)
; 
CREATE NONCLUSTERED INDEX [UK_ndx_ClientAnswers2] ON [dbo].[ClientAnswers] 
(
	[DataItemID] ASC,
	[ClientID] ASC,
	[CurrencyValue] ASC
)
;
CREATE NONCLUSTERED INDEX [UK_ndx_ClientAnswers3] ON [dbo].[ClientAnswers] 
(
	[DataItemID] ASC
);

-- Rename the PK
EXECUTE sp_rename 'dbo.ClientAnswers.PKC_ClientAnswers','PK_ClientAnswers','INDEX';