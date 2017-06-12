SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [Admin].[DatabaseObjects]
AS
SELECT        objType, CONVERT(VARCHAR(255), objName) AS Expr1
FROM            (SELECT        'database' AS objType, 'Client' AS objName
                          UNION
                          SELECT        ObjType, ObjName
                          FROM            (SELECT        TOP (100) PERCENT 'schema' AS ObjType, CATALOG_NAME + '.' + SCHEMA_NAME AS ObjName, CATALOG_NAME, SCHEMA_NAME, 
                                                                              SCHEMA_OWNER, DEFAULT_CHARACTER_SET_CATALOG, DEFAULT_CHARACTER_SET_SCHEMA, 
                                                                              DEFAULT_CHARACTER_SET_NAME
                                                    FROM            INFORMATION_SCHEMA.SCHEMATA
                                                    WHERE        (SCHEMA_OWNER = 'dbo') AND (SCHEMA_NAME <> 'dbo')
                                                    ORDER BY CATALOG_NAME, SCHEMA_NAME) AS sch
                          UNION
                          SELECT        objType, objName
                          FROM            (SELECT        TOP (100) PERCENT LOWER(REPLACE(TABLE_TYPE, 'base ', '')) AS objType, 
                                                                              TABLE_CATALOG + '.' + TABLE_SCHEMA + '.' + TABLE_NAME AS objName
                                                    FROM            INFORMATION_SCHEMA.TABLES
                                                    WHERE        (TABLE_NAME NOT LIKE 'sys%')
                                                    ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME) AS TB
                          UNION
                          SELECT        ObjType, ObjName
                          FROM            (SELECT        TOP (100) PERCENT 'Column' AS ObjType, 
                                                                              TABLE_CATALOG + '.' + TABLE_SCHEMA + '.' + TABLE_NAME + '.' + COLUMN_NAME AS ObjName
                                                    FROM            INFORMATION_SCHEMA.COLUMNS
                                                    ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION) AS col
                          UNION
                          SELECT        ObjType, ObjName
                          FROM            (SELECT        TOP (100) PERCENT 'Check Constraint' AS ObjType, 
                                                                              a.TABLE_CATALOG + '.' + a.TABLE_SCHEMA + '.' + a.TABLE_NAME + '.' + a.CONSTRAINT_NAME AS ObjName
                                                    FROM            INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE AS a INNER JOIN
                                                                              INFORMATION_SCHEMA.CHECK_CONSTRAINTS AS b ON a.CONSTRAINT_CATALOG = b.CONSTRAINT_CATALOG AND 
                                                                              a.CONSTRAINT_SCHEMA = b.CONSTRAINT_SCHEMA AND a.CONSTRAINT_NAME = b.CONSTRAINT_NAME
                                                    ORDER BY a.TABLE_CATALOG, a.TABLE_SCHEMA, a.TABLE_NAME, a.CONSTRAINT_NAME) AS cc) AS rtn
WHERE        (objName NOT LIKE 'Client.Admin%') AND (objName NOT LIKE 'Client.dbo.sysdiagrams%')





GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "rtn"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 101
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'Admin', @level1type=N'VIEW',@level1name=N'DatabaseObjects'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'Admin', @level1type=N'VIEW',@level1name=N'DatabaseObjects'
GO


