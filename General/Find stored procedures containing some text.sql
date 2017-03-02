SELECT OBJECT_NAME(id) 
    FROM syscomments 
    WHERE [text] LIKE '%sometext%' 
    AND OBJECTPROPERTY(id, 'IsProcedure') = 1 
    GROUP BY OBJECT_NAME(id)