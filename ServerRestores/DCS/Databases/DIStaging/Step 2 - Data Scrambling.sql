:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
PRINT 'Step 2 - Data Scramble - DIStaging'
USE DIStaging
GO

SET XACT_ABORT ON ;
/* Never scramble any data, only truncate as this is only a staging database */

/*
SELECT TABLE_SCHEMA + '.' + TABLE_NAME--, *  

FROM INFORMATION_SCHEMA.TABLES  

WHERE TABLE_TYPE = 'BASE TABLE' 

ORDER BY TABLE_SCHEMA + '.' + TABLE_NAME */

TRUNCATE TABLE dbo.Budget_Data_Errors
--TRUNCATE TABLE dbo.Budget_Data_Errors_Status
TRUNCATE TABLE dbo.Budget_Group_Items_Data_Errors
--TRUNCATE TABLE dbo.Budget_Group_Items_Data_Errors_Status
TRUNCATE TABLE dbo.Client_Data_Errors
--TRUNCATE TABLE dbo.Client_Data_Errors_Status
TRUNCATE TABLE dbo.Creditor_Data_Errors
--TRUNCATE TABLE dbo.Creditor_Data_Errors_Status
TRUNCATE TABLE dbo.Debt_Info_Data_Errors
--TRUNCATE TABLE dbo.Debt_Info_Data_Errors_Status
TRUNCATE TABLE dbo.Deposits_Data_Errors
--TRUNCATE TABLE dbo.Deposits_Data_Errors_Status
--TRUNCATE TABLE dbo.Dummy_User
--TRUNCATE TABLE dbo.Dummy_User_Log
TRUNCATE TABLE dbo.Special_User
TRUNCATE TABLE dbo.Statements_Data_Errors
--TRUNCATE TABLE dbo.Statements_Data_Errors_Status
TRUNCATE TABLE dbo.TelephoneNumber_Data_Errors
--TRUNCATE TABLE dbo.TelephoneNumber_Data_Errors_Status
TRUNCATE TABLE dcs.tblAddress
TRUNCATE TABLE dcs.tblAddress_delete
TRUNCATE TABLE dcs.tblAddress_delete_dump
TRUNCATE TABLE dcs.tblAddress_update
TRUNCATE TABLE dcs.tblBudget
TRUNCATE TABLE dcs.tblBudget_delete
TRUNCATE TABLE dcs.tblBudget_delete_dump
TRUNCATE TABLE dcs.tblBUDGET_FINANCIAL_VALUE
TRUNCATE TABLE dcs.tblBUDGET_FINANCIAL_VALUE_delete
TRUNCATE TABLE dcs.tblBUDGET_FINANCIAL_VALUE_delete_dump
TRUNCATE TABLE dcs.tblBUDGET_FINANCIAL_VALUE_update
TRUNCATE TABLE dcs.tblBUDGET_RULE_VALUE
TRUNCATE TABLE dcs.tblBUDGET_RULE_VALUE_delete
TRUNCATE TABLE dcs.tblBUDGET_RULE_VALUE_delete_dump
TRUNCATE TABLE dcs.tblBUDGET_RULE_VALUE_update
TRUNCATE TABLE dcs.tblBudget_update
TRUNCATE TABLE dcs.tblClient
TRUNCATE TABLE dcs.tblCLIENT_DEBT_REASON
TRUNCATE TABLE dcs.tblCLIENT_DEBT_REASON_update
TRUNCATE TABLE dcs.tblClient_delete
TRUNCATE TABLE dcs.tblClient_delete_dump
TRUNCATE TABLE dcs.tblCLIENT_FINANCIAL_VALUE
TRUNCATE TABLE dcs.tblCLIENT_FINANCIAL_VALUE_delete
TRUNCATE TABLE dcs.tblCLIENT_FINANCIAL_VALUE_delete_dump
TRUNCATE TABLE dcs.tblCLIENT_FINANCIAL_VALUE_update
TRUNCATE TABLE dcs.tblClient_update
TRUNCATE TABLE dcs.tblContact
TRUNCATE TABLE dcs.tblContact_delete
TRUNCATE TABLE dcs.tblContact_delete_dump
TRUNCATE TABLE dcs.tblContact_update
--TRUNCATE TABLE dcs.tblFINANCIAL_CATEGORY_AdHoc
TRUNCATE TABLE dcs.WS_NamesOfClients
TRUNCATE TABLE dcs.WS_NamesOfClients_delete
TRUNCATE TABLE dcs.WS_NamesOfClients_delete_dump
TRUNCATE TABLE dcs.WS_NamesOfClients_update
TRUNCATE TABLE dms.client

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES
			WHERE TABLE_SCHEMA = 'dms' AND TABLE_NAME = 'client_temp'
			AND TABLE_TYPE = 'BASE TABLE')
			TRUNCATE TABLE dms.client_temp

TRUNCATE TABLE dms.client_update
--TRUNCATE TABLE dms.creditor                 AS - 08/04/2013 - Don't truncate creditors, otherwise we get problems with OriginalCreditorID on StatementLineItems in CWS
TRUNCATE TABLE dms.creditor_historical_update
TRUNCATE TABLE dms.creditor_update
TRUNCATE TABLE dms.debt_info
TRUNCATE TABLE dms.debt_info_delete
TRUNCATE TABLE dms.debt_info_delete_dump
TRUNCATE TABLE dms.debt_info_ptd
TRUNCATE TABLE dms.debt_info_ptd_delete
TRUNCATE TABLE dms.debt_info_ptd_delete_dump
TRUNCATE TABLE dms.debt_info_ptd_update
TRUNCATE TABLE dms.debt_info_update
TRUNCATE TABLE dms.deposit_history
TRUNCATE TABLE dms.deposit_history_delete
TRUNCATE TABLE dms.deposit_history_delete_dump
--TRUNCATE TABLE dms.deposit_history_type_map
TRUNCATE TABLE dms.deposit_history_update
TRUNCATE TABLE dms.direct_debits
TRUNCATE TABLE dms.direct_debits_delete
TRUNCATE TABLE dms.direct_debits_delete_dump
TRUNCATE TABLE dms.direct_debits_update
TRUNCATE TABLE dms.historical_client_statement_cws
TRUNCATE TABLE dms.historical_client_statement_cws_delete
TRUNCATE TABLE dms.historical_client_statement_cws_delete_dump
TRUNCATE TABLE dms.historical_client_statement_cws_update
TRUNCATE TABLE dms.historical_creditor
TRUNCATE TABLE dms.payment_history
TRUNCATE TABLE dms.payment_history_delete
TRUNCATE TABLE dms.payment_history_delete_dump
TRUNCATE TABLE dms.payment_history_update
TRUNCATE TABLE dms.scheduled_payment
TRUNCATE TABLE dms.scheduled_payment_delete
TRUNCATE TABLE dms.scheduled_payment_delete_dump
TRUNCATE TABLE dms.scheduled_payment_update
TRUNCATE TABLE statement.opt_out
TRUNCATE TABLE statement.statement_reminder
