
-- Lists all subscriptions on the Report Server

USE ReportServer
GO

SELECT 
    CatalogParent.Name ParentName, 
    Catalog.Name ReportName, 
    ReportModifiedByUsers.UserName ReportModifiedByUserName, 
    Catalog.ModifiedDate ReportModifiedDate, 
    CountExecution.CountStart TotalExecutions, 
    ExecutionLog.TimeStart LastExecutedTimeStart, 
    ExecutionLog.TimeEnd LastExecutedTimeEnd, 
    ExecutionLog.ByteCount LastExecutedByteCount, 
    ExecutionLog.[RowCount] LastExecutedRowCount, 
    SubscriptionOwner.UserName SubscriptionOwnerUserName, 
    SubscriptionModifiedByUsers.UserName SubscriptionModifiedByUserName, 
    Subscriptions.ModifiedDate SubscriptionModifiedDate, 
    Subscriptions.Description SubscriptionDescription, 
    Subscriptions.LastStatus SubscriptionLastStatus, 
    Subscriptions.LastRunTime SubscriptionLastRunTime 
FROM 
    dbo.Catalog 
JOIN 
    dbo.Catalog CatalogParent 
ON Catalog.ParentID = CatalogParent.ItemID 
JOIN 
    dbo.Users ReportCreatedByUsers 
ON Catalog.CreatedByID = ReportCreatedByUsers.UserID 
JOIN 
    dbo.Users ReportModifiedByUsers 
ON Catalog.ModifiedByID = ReportModifiedByUsers.UserID 
LEFT JOIN ( 
                   SELECT 
                      ReportID, MAX(TimeStart) LastTimeStart 
                   FROM 
                     dbo.ExecutionLog 
                  GROUP BY ReportID ) LatestExecution 
ON Catalog.ItemID = LatestExecution.ReportID 
LEFT JOIN ( 
                 SELECT 
                      ReportID, COUNT(TimeStart) CountStart 
                 FROM 
                      dbo.ExecutionLog 
                GROUP BY ReportID ) CountExecution 
ON Catalog.ItemID = CountExecution.ReportID 
LEFT JOIN 
    dbo.ExecutionLog 
ON LatestExecution.ReportID = ExecutionLog.ReportID 
AND LatestExecution.LastTimeStart = ExecutionLog.TimeStart 
LEFT JOIN 
     dbo.Subscriptions 
ON Catalog.ItemID = Subscriptions.Report_OID 
LEFT JOIN 
    dbo.Users SubscriptionOwner 
ON Subscriptions.OwnerID = SubscriptionOwner.UserID 
LEFT JOIN 
    dbo.Users SubscriptionModifiedByUsers 
ON Subscriptions.ModifiedByID = SubscriptionModifiedByUsers.UserID 
WHERE 
    SubscriptionOwner.UserName is not NULL
ORDER BY 
    CatalogParent.Name, 
    Catalog.Name
