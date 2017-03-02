SELECT S2.[name] TableName, S1.[name] TriggerName, 
CASE 
WHEN S2.deltrig = s1.id  THEN 'Delete' 
WHEN S2.instrig = s1.id THEN 'Insert' 
WHEN S2.updtrig = s1.id THEN 'Update' 
END 'TriggerType' , 'S1',s1.*,'S2',s2.*
FROM sysobjects S1 JOIN sysobjects S2 ON S1.parent_obj = S2.[id] WHERE S1.xtype='TR'
