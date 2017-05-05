;
WITH    [addressValues]
          AS (
              SELECT    [ClientReference] ,
                        CASE WHEN ISNUMERIC((REPLACE(REPLACE([HouseNameOrNumber],
                                                             '\', ''), ' ', ''))) = 1
                             THEN NULL
                             ELSE REPLACE([HouseNameOrNumber], '\', ' ')
                        END AS [LineAddress] ,
                        1 AS [LinePos]
              FROM      [dbo].[ClientAddressSSActiveClients]
              UNION ALL
              SELECT    [ClientReference] ,
                        CASE WHEN ISNUMERIC((REPLACE(REPLACE([HouseNameOrNumber],
                                                             '\', ''), ' ', ''))) = 1
                             THEN CASE WHEN [AddressLine1] IS NULL
                                       THEN REPLACE([HouseNameOrNumber], '\',
                                                    ' ') + ' '
                                            + ISNULL([AddressLine2], '')
                                       ELSE REPLACE([HouseNameOrNumber], '\',
                                                    ' ') + ' '
                                            + ISNULL([AddressLine1], '')
                                  END
                             WHEN ISNUMERIC((REPLACE(REPLACE([AddressLine1],
                                                             '\', ''), ' ', ''))) = 1
                             THEN NULL
                             ELSE REPLACE([AddressLine1], '\', ' ')
                        END AS [LineAddress] ,
                        2 AS [LinePos]
              FROM      [dbo].[ClientAddressSSActiveClients]
              UNION ALL
              SELECT    [ClientReference] ,
                        CASE WHEN ISNUMERIC((REPLACE([HouseNameOrNumber], '\',
                                                     ''))) = 1
                                  AND [AddressLine1] IS NULL THEN NULL
                             WHEN ISNUMERIC((REPLACE(REPLACE([AddressLine1],
                                                             '\', ''), ' ', ''))) = 1
                             THEN REPLACE([AddressLine1], '\', ' ') + ' '
                                  + ISNULL([AddressLine2], '')
                             ELSE REPLACE([AddressLine2], '\', ' ')
                        END AS [LineAddress] ,
                        3 AS [LinePos]
              FROM      [dbo].[ClientAddressSSActiveClients]
              UNION ALL
              SELECT    [ClientReference] ,
                        REPLACE([AddressLine3], '\', ' ') AS [LineAddress] ,
                        4 AS [LinePos]
              FROM      [dbo].[ClientAddressSSActiveClients]
              UNION ALL
              SELECT    [ClientReference] ,
                        REPLACE([PostTown], '\', ' ') AS [LineAddress] ,
                        5 AS [LinePos]
              FROM      [dbo].[ClientAddressSSActiveClients]
              UNION ALL
              SELECT    [ClientReference] ,
                        REPLACE([Region], '\', ' ') AS [LineAddress] ,
                        6 AS [LinePos]
              FROM      [dbo].[ClientAddressSSActiveClients]
              UNION ALL
              SELECT    [ClientReference] ,
                        REPLACE(UPPER([PostCode]), '\', ' ') AS [LineAddress] ,
                        7 AS [LinePos]
              FROM      [dbo].[ClientAddressSSActiveClients]
             ),
        [orderedaddress]
          AS (
              SELECT    [addressValues].[ClientReference] ,
                        [addressValues].[LineAddress] ,
                        ROW_NUMBER() OVER (PARTITION BY [addressValues].[ClientReference] ORDER BY [addressValues].[LinePos]) AS [Num]
              FROM      [addressValues]
              WHERE     [addressValues].[LineAddress] IS NOT NULL
                        AND REPLACE([addressValues].[LineAddress], ' ', '') <> ''
             ),
        [ordercolumns]
          AS (
              SELECT    [orderedaddress].[ClientReference] ,
                        CASE WHEN [orderedaddress].[Num] = 1
                             THEN ([orderedaddress].[LineAddress])
                        END AS [Line1] ,
                        CASE WHEN [orderedaddress].[Num] = 2
                             THEN ([orderedaddress].[LineAddress])
                        END AS [Line2] ,
                        CASE WHEN [orderedaddress].[Num] = 3
                             THEN ([orderedaddress].[LineAddress])
                        END AS [Line3] ,
                        CASE WHEN [orderedaddress].[Num] = 4
                             THEN ([orderedaddress].[LineAddress])
                        END AS [Line4] ,
                        CASE WHEN [orderedaddress].[Num] = 5
                             THEN ([orderedaddress].[LineAddress])
                        END AS [Line5] ,
                        CASE WHEN [orderedaddress].[Num] = 6
                             THEN ([orderedaddress].[LineAddress])
                        END AS [Line6] ,
                        CASE WHEN [orderedaddress].[Num] = 7
                             THEN ([orderedaddress].[LineAddress])
                        END AS [Line7]
              FROM      [orderedaddress]
             ),
        [pivotcolumns]
          AS (
              SELECT    [ordercolumns].[ClientReference] ,
                        MAX([ordercolumns].[Line1]) AS [AddressLine1] ,
                        MAX([ordercolumns].[Line2]) AS [AddressLine2] ,
                        MAX([ordercolumns].[Line3]) AS [AddressLine3] ,
                        MAX([ordercolumns].[Line4]) AS [AddressLine4] ,
                        MAX([ordercolumns].[Line5]) AS [AddressLine5] ,
                        MAX([ordercolumns].[Line6]) AS [AddressLine6] ,
                        MAX([ordercolumns].[Line7]) AS [AddressLine7]
              FROM      [ordercolumns]
              GROUP BY  [ordercolumns].[ClientReference]
             )
    SELECT  [pivotcolumns].[ClientReference] ,
            [pivotcolumns].[AddressLine1] ,
            [pivotcolumns].[AddressLine2] ,
            [pivotcolumns].[AddressLine3] ,
            [pivotcolumns].[AddressLine4] ,
            [pivotcolumns].[AddressLine5] ,
            [pivotcolumns].[AddressLine6] ,
            [pivotcolumns].[AddressLine7]
    FROM    [pivotcolumns]
    --UNION ALL
    --SELECT  [ClientReference] ,
    --        [HouseNameOrNumber] ,
    --        [AddressLine1] ,
    --        [AddressLine2] ,
    --        [AddressLine3] ,
    --        [PostTown] ,
    --        [Region] ,
    --        [PostCode]
    --FROM    [dbo].[ClientAddressSSActiveClients]
	WHERE [pivotcolumns].[AddressLine3] IS NULL
    ORDER BY 1;
			 
