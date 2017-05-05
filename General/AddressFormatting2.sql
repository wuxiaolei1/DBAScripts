;
WITH    [addressValues]
          AS (
              SELECT    [DMS Client Number] ,
                        CASE WHEN ISNUMERIC((REPLACE(REPLACE([address1], '\', ''),
                                                     ' ', ''))) = 1 THEN NULL
                             ELSE REPLACE([address1], '\', ' ')
                        END AS [LineAddress] ,
                        1 AS [LinePos]
              FROM      [dbo].[ExcelImport]
              UNION ALL
              SELECT    [DMS Client Number] ,
                        CASE WHEN ISNUMERIC((REPLACE(REPLACE([address1], '\', ''),
                                                     ' ', ''))) = 1
                             THEN CASE WHEN [address2] IS NULL
                                       THEN REPLACE([address1], '\', ' ') + ' '
                                            + ISNULL([city], '')
                                       ELSE REPLACE([address1], '\', ' ') + ' '
                                            + ISNULL([address2], '')
                                  END
                             WHEN ISNUMERIC((REPLACE(REPLACE([address2], '\', ''),
                                                     ' ', ''))) = 1 THEN NULL
                             ELSE REPLACE([address2], '\', ' ')
                        END AS [LineAddress] ,
                        2 AS [LinePos]
              FROM      [dbo].[ExcelImport]
              UNION ALL
              SELECT    [DMS Client Number] ,
                        CASE WHEN ISNUMERIC((REPLACE([address1], '\', ''))) = 1
                                  AND [address2] IS NULL THEN NULL
                             WHEN ISNUMERIC((REPLACE(REPLACE([address2], '\', ''),
                                                     ' ', ''))) = 1
                             THEN REPLACE([address2], '\', ' ') + ' '
                                  + ISNULL([city], '')
                             ELSE REPLACE([city], '\', ' ')
                        END AS [LineAddress] ,
                        3 AS [LinePos]
              FROM      [dbo].[ExcelImport]
              UNION ALL
              SELECT    [DMS Client Number] ,
                        REPLACE([Region], '\', ' ') AS [LineAddress] ,
                        4 AS [LinePos]
              FROM      [dbo].[ExcelImport]
              UNION ALL
              SELECT    [DMS Client Number] ,
                        REPLACE(UPPER([Postcode]), '\', ' ') AS [LineAddress] ,
                        5 AS [LinePos]
              FROM      [dbo].[ExcelImport]
             ),
        [orderedaddress]
          AS (
              SELECT    [addressValues].[DMS Client Number] ,
                        [addressValues].[LineAddress] ,
                        ROW_NUMBER() OVER (PARTITION BY [addressValues].[DMS Client Number] ORDER BY [addressValues].[LinePos]) AS [Num]
              FROM      [addressValues]
              WHERE     [addressValues].[LineAddress] IS NOT NULL
                        AND REPLACE([addressValues].[LineAddress], ' ', '') <> ''
             ),
        [ordercolumns]
          AS (
              SELECT    [orderedaddress].[DMS Client Number] ,
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
                        END AS [Line5]
              FROM      [orderedaddress]
             ),
        [pivotcolumns]
          AS (
              SELECT    [ordercolumns].[DMS Client Number] ,
                        MAX([ordercolumns].[Line1]) AS [AddressLine1] ,
                        MAX([ordercolumns].[Line2]) AS [AddressLine2] ,
                        MAX([ordercolumns].[Line3]) AS [AddressLine3] ,
                        MAX([ordercolumns].[Line4]) AS [AddressLine4] ,
                        MAX([ordercolumns].[Line5]) AS [AddressLine5]
              FROM      [ordercolumns]
              GROUP BY  [ordercolumns].[DMS Client Number]
             )
    SELECT  [pivotcolumns].[DMS Client Number] ,
            [pivotcolumns].[AddressLine1] ,
            [pivotcolumns].[AddressLine2] ,
            [pivotcolumns].[AddressLine3] ,
            [pivotcolumns].[AddressLine4] ,
            [pivotcolumns].[AddressLine5]
    FROM    [pivotcolumns]
    WHERE   [pivotcolumns].[AddressLine3] IS NULL;
	
    --UNION ALL
    --SELECT  [DMS Client Number] ,
    --        Address1 ,
    --        Address2 ,
    --        city ,
    --        Region ,
    --        [PostTown] ,
    --        [Region] ,
    --        [PostCode]
    --FROM    [dbo].[ExcelImport]
    --ORDER BY 1;
			 
