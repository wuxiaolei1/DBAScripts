/*	SQL Version 2008/2012	*/

if not exists(select 1 from msdb.dbo.sysmail_profile where name = 'Deadlock_Mail') begin
	-- Create a Database Mail profile 
	EXECUTE msdb.dbo.sysmail_add_profile_sp 
	@profile_name = 'Deadlock_Mail'; 
end

if not exists(select 1 from msdb.dbo.sysmail_account  where name = 'Deadlock_Mail') begin
	-- Create a Database Mail account 
	EXECUTE msdb.dbo.sysmail_add_account_sp 
	@account_name = 'Deadlock_Mail',  
	@email_address = 'SQLServerDeadlocks@stepchange.org',  
	@display_name = 'SQL Server Deadlocks',
	@mailserver_name = 'ldsexchange01.cccs.co.uk';
end

if not exists (select 1 from msdb.dbo.sysmail_profileaccount where
	profile_id = (select profile_id from msdb.dbo.sysmail_profile where name = 'Deadlock_Mail')
	and account_id = (select account_id from msdb.dbo.sysmail_account where name = 'Deadlock_Mail')
	and sequence_number = 1) begin
	
	-- Add the account to the profile 
	EXECUTE msdb.dbo.sysmail_add_profileaccount_sp 
	@profile_name = 'Deadlock_Mail', 
	@account_name = 'Deadlock_Mail', 
	@sequence_number =1 ; 
end
