
/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 3 - Update Application Settings .sql"

--- */
:on error exit
Print 'Step 3 - Update Application Settings - QMS'

USE QMS
GO

UPDATE	qms.branch
SET		qwin_host = CASE @@SERVERNAME
						WHEN 'VM01QMTPRODBA01' THEN 'PC01QWNPROAPP01'
						WHEN 'VMDEVQMATICDBA1' THEN 'PCDEVQWINAPP01'
						WHEN 'VMDEVQMATICDBA2' THEN 'PCDEVQWINAPP02'
						WHEN 'HLXGENDSR1DBA03' THEN 'HLXQWNDSR1APP01'
						ELSE ''
					END ,
		qwin_event_host = 
					CASE @@SERVERNAME
						WHEN 'VM01QMTPRODBA01' THEN 'PC01QWNPROAPP01'
						WHEN 'VMDEVQMATICDBA1' THEN 'PCDEVQWINAPP01'
						WHEN 'VMDEVQMATICDBA2' THEN 'PCDEVQWINAPP02'
						WHEN 'HLXGENDSR1DBA03' THEN 'HLXQWNDSR1APP01'
						ELSE ''
					END 
WHERE	[name] = 'Step Change Debt Charity';