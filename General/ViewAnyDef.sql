Use master
Go
Grant View Any Definition To ViewAnyDef

Use master
GO
SELECT sp.permission_name, p.name
        FROM sys.server_permissions sp
                Inner Join sys.server_principals p
                        On p.principal_id = sp.grantee_principal_id
        Where sp.permission_name = 'View Any Definition'
GO


