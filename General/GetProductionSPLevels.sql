/* Created by:  thomasb
 * Create date: 06/05/2015
 * Purpose: Use this script to check the patch levels of the productions server as part of the 
 *			quarterly checks. 
 * Instructions:	
 *			1. Browse to https://technet.microsoft.com/en-us/library/ff803383.aspx to see the latest service packs
 *			2. Update the variables with the latest values
 *			3. Connect the script against all production connection and execute
 *			4. The column "Correct SP Level?" will highlight any servers that are not on the correct SP
 */

/***************************************************************************************
Latest Check:	thomasb 
Date:			06/05/2015
****************************************************************************************/
/* populate latest versions */
DECLARE @SQL2005 VARCHAR(5);
DECLARE @SQL2008 VARCHAR(5);
DECLARE @SQL2008R2 VARCHAR(5);
DECLARE @SQL2012 VARCHAR(5);
DECLARE @SQL2014 VARCHAR(5);
DECLARE @SQL2016 VARCHAR(5);

SET @SQL2005 = 'SP4';
SET @SQL2008 = 'SP4';
SET @SQL2008R2 = 'SP3';
SET @SQL2012 = 'SP3';
SET @SQL2014 = 'SP1';
SET @SQL2016 = 'SP1';

SELECT  [a].[ServerName] ,
        [a].[InstanceName] ,
        [a].[ProductVersion] ,
        [a].[VersionNumber] ,
        [a].[ProductLevel] ,
        CASE 
			/* SQL 2005 */
             WHEN [a].[MajorVersion] = 9
                  AND [a].[ProductLevel] = @SQL2005 THEN 'Yes'
			/* SQL 2008 */
             WHEN [a].[MajorVersion] = 10
                  AND [a].[MinorVersion] = 0
                  AND [a].[ProductLevel] = @SQL2008 THEN 'Yes'
			/* SQL 2008 R2 */
             WHEN [a].[MajorVersion] = 10
                  AND [a].[MinorVersion] = 50
                  AND [a].[ProductLevel] = @SQL2008R2 THEN 'Yes'
			/* SQL 2012 */
             WHEN [a].[MajorVersion] = 11
                  AND [a].[ProductLevel] = @SQL2012 THEN 'Yes'
			/* SQL 2014 */
             WHEN [a].[MajorVersion] = 12
                  AND [a].[ProductLevel] = @SQL2014 THEN 'Yes'
			/* SQL 2016 */
             WHEN [a].[MajorVersion] = 13
                  AND [a].[ProductLevel] = @SQL2016 THEN 'Yes'
             ELSE 'No - SP needs to be updated'
        END AS [Correct SP Level?] ,
		/* Windows 2012 */
        CASE WHEN [a].[WindowsVersion] = '6.2' THEN 'Windows 2012'
		/* Windows 2008 R2*/
             WHEN [a].[WindowsVersion] = '6.1' THEN 'Windows 2008 R2'
		/* Windows 2008*/
             WHEN [a].[WindowsVersion] = '6.0' THEN 'Windows 2008 R2'
		/* Windows 2003*/
             WHEN [a].[WindowsVersion] = '5.2' THEN 'Windows 2003'
             ELSE [a].[WindowsVersion]
        END AS WindowsVersion
FROM    ( SELECT    CAST(SERVERPROPERTY('MachineName') AS NVARCHAR(128)) AS 'ServerName' ,
                    ISNULL(SERVERPROPERTY('InstanceName'), 'Default') AS 'InstanceName' ,
                    RTRIM(REPLACE(LEFT(@@VERSION, 26), '  ', ' ')) AS 'ProductVersion' ,
                    SERVERPROPERTY('edition') AS 'Edition' ,
                    SERVERPROPERTY('productversion') AS 'VersionNumber' ,
                    SERVERPROPERTY('productlevel') AS 'ProductLevel' ,
                    ( ( @@microsoftversion / 0x1000000 ) & 0xff ) AS [MajorVersion] ,
                    ( ( @@microsoftversion / 0x10000 ) & 0xff ) AS [MinorVersion] ,
                    ( @@microsoftversion & 0xfff ) AS [BuildNumber] ,
                    RIGHT(SUBSTRING(@@VERSION,
                                    CHARINDEX('Windows NT', @@VERSION), 14), 3) AS WindowsVersion
        ) AS a;



		