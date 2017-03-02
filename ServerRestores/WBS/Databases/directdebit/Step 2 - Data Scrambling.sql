:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET ANSI_WARNINGS ON
GO
PRINT 'Step 2 - Scramble Data - directdebit'

USE directdebit
GO

DECLARE @InternalEmail VARCHAR(100)
DECLARE @ClientEmail VARCHAR(100)
DECLARE @ClientTelNo VARCHAR(255)
DECLARE @DataScramble BIT
DECLARE @Environment VARCHAR(50)
DECLARE @HouseNameOrNumber VARCHAR(60)
DECLARE @AddressLine1 VARCHAR(60)
DECLARE @AddressLine2 VARCHAR(60)
DECLARE @AddressLine3 VARCHAR(60)
DECLARE @AddressLine4 VARCHAR(60)
DECLARE @Region VARCHAR(60)
DECLARE @Country VARCHAR(60)
DECLARE @PostCode VARCHAR(60)
DECLARE @DataRowCount INT
DECLARE @DataScrambleName INT
 -- 1 = Yes Scramble Name
DECLARE @DataScrambleAddress INT
 -- 1 = Yes Scramble Address

--SET DEFAULTS...
SET @InternalEmail = 'thisisadummyemail@notstepchange.co.na'
 --'no-reply@stepchange.org'
SET @ClientEmail = 'thisisadummyemail@notstepchange.co.na'
 --'no-reply@stepchange.org'
SET @ClientTelNo = '09999999999'
SET @DataScramble = 1
SET @Environment = $(Environment)
SET @HouseNameOrNumber = 'StepChange - Systems Department'
SET @AddressLine1 = 'Wade House'
SET @AddressLine2 = 'Merrion Centre'
SET @AddressLine3 = 'Leeds'
SET @AddressLine4 = 'Yorkshire'
SET @PostCode = 'LS2 8NG'
SET @DataRowCount = 0
SET @DataScrambleName = 1
SET @DataScrambleAddress = 1

--Read the specific settings if available...
SELECT  @InternalEmail = EDV.Email ,
        @ClientEmail = EDV.ClientEmail ,
        @ClientTelNo = EDV.TelNo ,
        @DataScramble = EDV.DataScramble ,
        @HouseNameOrNumber = EDV.HouseNameOrNumber ,
        @AddressLine1 = EDV.AddressLine1 ,
        @AddressLine2 = EDV.AddressLine2 ,
		@AddressLine3 = EDV.AddressLine3 ,
        @AddressLine4 = EDV.PostTown ,
        @Region = EDV.Region ,
        @PostCode = EDV.PostCode ,
		@Country = EDV.Country,
        @DataScrambleName = EDV.DataScrambleName ,
        @DataScrambleAddress = EDV.DataScrambleAddress
FROM    EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE   Environment = @Environment

SET @DataRowCount = @@Rowcount

-- Data Scrambling
/*
[dbo].[LetterHistory] - Need to check these further
[dbo].[LetterOutbox] - Need to check these further
*/

-- Perform Updates
IF @DataScramble = 1 
    BEGIN
    
-- Scramble Telephone Numbers
        UPDATE  [dbo].[Addresses]
        SET     [HomeTel] = CASE WHEN PATINDEX('%[^0-9]%', [HomeTel]) = 1
                                 THEN SUBSTRING([HomeTel], 1,
                                                ( PATINDEX('%[^0-9]%',
                                                           [HomeTel]) )) + '0'
                                      + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([HomeTel]) ),
                                                  ( PATINDEX('%[^0-9]%',
                                                             [HomeTel]) ) + 2,
                                                  ( LEN([HomeTel]) )) COLLATE SQL_Latin1_General_CP1_CI_AS 
                                 ELSE '0'
                                      + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([HomeTel]) ),
                                                  2, LEN([HomeTel]) - 1) COLLATE SQL_Latin1_General_CP1_CI_AS 
                            END
        WHERE   [HomeTel] IS NOT NULL
                AND REPLACE([HomeTel], ' ', '') <> ''
		
        UPDATE  [dbo].[Addresses]
        SET     [BusinessTel] = CASE WHEN PATINDEX('%[^0-9]%', [BusinessTel]) = 1
                                     THEN SUBSTRING([BusinessTel], 1,
                                                    ( PATINDEX('%[^0-9]%',
                                                              [BusinessTel]) ))
                                          + '0'
                                          + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([BusinessTel]) ),
                                                      ( PATINDEX('%[^0-9]%',
                                                              [BusinessTel]) )
                                                      + 2,
                                                      ( LEN([BusinessTel]) )) COLLATE SQL_Latin1_General_CP1_CI_AS 
                                     ELSE '0'
                                          + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([BusinessTel]) ),
                                                      2,
                                                      LEN([BusinessTel]) - 1) COLLATE SQL_Latin1_General_CP1_CI_AS 
                                END
        WHERE   [BusinessTel] IS NOT NULL
                AND REPLACE([BusinessTel], ' ', '') <> ''

        UPDATE  [dbo].[Addresses]
        SET     [Mobile] = CASE WHEN PATINDEX('%[^0-9]%', [Mobile]) = 1
                                THEN SUBSTRING([Mobile], 1,
                                               ( PATINDEX('%[^0-9]%', [Mobile]) ))
                                     + '0'
                                     + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([Mobile]) ),
                                                 ( PATINDEX('%[^0-9]%',
                                                            [Mobile]) ) + 2,
                                                 ( LEN([Mobile]) )) COLLATE SQL_Latin1_General_CP1_CI_AS 
                                ELSE '0'
                                     + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([Mobile]) ),
                                                 2, LEN([Mobile]) - 1) COLLATE SQL_Latin1_General_CP1_CI_AS 
                           END
        WHERE   [Mobile] IS NOT NULL
                AND REPLACE([Mobile], ' ', '') <> ''
		    
        UPDATE  [dbo].[Addresses]
        SET     [Fax] = CASE WHEN PATINDEX('%[^0-9]%', [Fax]) = 1
                             THEN SUBSTRING([Fax], 1,
                                            ( PATINDEX('%[^0-9]%', [Fax]) ))
                                  + '0'
                                  + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([Fax]) ),
                                              ( PATINDEX('%[^0-9]%', [Fax]) )
                                              + 2, ( LEN([Fax]) )) COLLATE SQL_Latin1_General_CP1_CI_AS 
                             ELSE '0'
                                  + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([Fax]) ),
                                              2, LEN([Fax]) - 1) COLLATE SQL_Latin1_General_CP1_CI_AS 
                        END
        WHERE   [Fax] IS NOT NULL
                AND REPLACE([Fax], ' ', '') <> ''

   UPDATE  [dbo].[LetterHistory]
        SET     [HomeTel] = CASE WHEN PATINDEX('%[^0-9]%', [HomeTel]) = 1
                                 THEN SUBSTRING([HomeTel], 1,
                                                ( PATINDEX('%[^0-9]%',
                                                           [HomeTel]) )) + '0'
                                      + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([HomeTel]) ),
                                                  ( PATINDEX('%[^0-9]%',
                                                             [HomeTel]) ) + 2,
                                                  ( LEN([HomeTel]) )) COLLATE SQL_Latin1_General_CP1_CI_AS 
                                 ELSE '0'
                                      + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([HomeTel]) ),
                                                  2, LEN([HomeTel]) - 1) COLLATE SQL_Latin1_General_CP1_CI_AS 
                            END
        WHERE   [HomeTel] IS NOT NULL
                AND REPLACE([HomeTel], ' ', '') <> ''
		
        UPDATE  [dbo].[LetterHistory]
        SET     [BusinessTel] = CASE WHEN PATINDEX('%[^0-9]%', [BusinessTel]) = 1
                                     THEN SUBSTRING([BusinessTel], 1,
                                                    ( PATINDEX('%[^0-9]%',
                                                              [BusinessTel]) ))
                                          + '0'
                                          + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([BusinessTel]) ),
                                                      ( PATINDEX('%[^0-9]%',
                                                              [BusinessTel]) )
                                                      + 2,
                                                      ( LEN([BusinessTel]) )) COLLATE SQL_Latin1_General_CP1_CI_AS 
                                     ELSE '0'
                                          + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([BusinessTel]) ),
                                                      2,
                                                      LEN([BusinessTel]) - 1) COLLATE SQL_Latin1_General_CP1_CI_AS 
                                END
        WHERE   [BusinessTel] IS NOT NULL
                AND REPLACE([BusinessTel], ' ', '') <> ''

        UPDATE  [dbo].[LetterHistory]
        SET     [Mobile] = CASE WHEN PATINDEX('%[^0-9]%', [Mobile]) = 1
                                THEN SUBSTRING([Mobile], 1,
                                               ( PATINDEX('%[^0-9]%', [Mobile]) ))
                                     + '0'
                                     + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([Mobile]) ),
                                                 ( PATINDEX('%[^0-9]%',
                                                            [Mobile]) ) + 2,
                                                 ( LEN([Mobile]) )) COLLATE SQL_Latin1_General_CP1_CI_AS 
                                ELSE '0'
                                     + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([Mobile]) ),
                                                 2, LEN([Mobile]) - 1) COLLATE SQL_Latin1_General_CP1_CI_AS 
                           END
        WHERE   [Mobile] IS NOT NULL
                AND REPLACE([Mobile], ' ', '') <> ''
		    
        UPDATE  [dbo].[LetterHistory]
        SET     [Fax] = CASE WHEN PATINDEX('%[^0-9]%', [Fax]) = 1
                             THEN SUBSTRING([Fax], 1,
                                            ( PATINDEX('%[^0-9]%', [Fax]) ))
                                  + '0'
                                  + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([Fax]) ),
                                              ( PATINDEX('%[^0-9]%', [Fax]) )
                                              + 2, ( LEN([Fax]) )) COLLATE SQL_Latin1_General_CP1_CI_AS 
                             ELSE '0'
                                  + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([Fax]) ),
                                              2, LEN([Fax]) - 1) COLLATE SQL_Latin1_General_CP1_CI_AS 
                        END
        WHERE   [Fax] IS NOT NULL
                AND REPLACE([Fax], ' ', '') <> ''


   UPDATE  [dbo].[LetterOutbox]
        SET     [HomeTel] = CASE WHEN PATINDEX('%[^0-9]%', [HomeTel]) = 1
                                 THEN SUBSTRING([HomeTel], 1,
                                                ( PATINDEX('%[^0-9]%',
                                                           [HomeTel]) )) + '0'
                                      + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([HomeTel]) ),
                                                  ( PATINDEX('%[^0-9]%',
                                                             [HomeTel]) ) + 2,
                                                  ( LEN([HomeTel]) )) COLLATE SQL_Latin1_General_CP1_CI_AS 
                                 ELSE '0'
                                      + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([HomeTel]) ),
                                                  2, LEN([HomeTel]) - 1) COLLATE SQL_Latin1_General_CP1_CI_AS 
                            END
        WHERE   [HomeTel] IS NOT NULL
                AND REPLACE([HomeTel], ' ', '') <> ''
		
        UPDATE  [dbo].[LetterOutbox]
        SET     [BusinessTel] = CASE WHEN PATINDEX('%[^0-9]%', [BusinessTel]) = 1
                                     THEN SUBSTRING([BusinessTel], 1,
                                                    ( PATINDEX('%[^0-9]%',
                                                              [BusinessTel]) ))
                                          + '0'
                                          + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([BusinessTel]) ),
                                                      ( PATINDEX('%[^0-9]%',
                                                              [BusinessTel]) )
                                                      + 2,
                                                      ( LEN([BusinessTel]) )) COLLATE SQL_Latin1_General_CP1_CI_AS 
                                     ELSE '0'
                                          + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([BusinessTel]) ),
                                                      2,
                                                      LEN([BusinessTel]) - 1) COLLATE SQL_Latin1_General_CP1_CI_AS 
                                END
        WHERE   [BusinessTel] IS NOT NULL
                AND REPLACE([BusinessTel], ' ', '') <> ''

        UPDATE  [dbo].[LetterOutbox]
        SET     [Mobile] = CASE WHEN PATINDEX('%[^0-9]%', [Mobile]) = 1
                                THEN SUBSTRING([Mobile], 1,
                                               ( PATINDEX('%[^0-9]%', [Mobile]) ))
                                     + '0'
                                     + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([Mobile]) ),
                                                 ( PATINDEX('%[^0-9]%',
                                                            [Mobile]) ) + 2,
                                                 ( LEN([Mobile]) )) COLLATE SQL_Latin1_General_CP1_CI_AS 
                                ELSE '0'
                                     + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([Mobile]) ),
                                                 2, LEN([Mobile]) - 1) COLLATE SQL_Latin1_General_CP1_CI_AS 
                           END
        WHERE   [Mobile] IS NOT NULL
                AND REPLACE([Mobile], ' ', '') <> ''
		    
        UPDATE  [dbo].[LetterOutbox]
        SET     [Fax] = CASE WHEN PATINDEX('%[^0-9]%', [Fax]) = 1
                             THEN SUBSTRING([Fax], 1,
                                            ( PATINDEX('%[^0-9]%', [Fax]) ))
                                  + '0'
                                  + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([Fax]) ),
                                              ( PATINDEX('%[^0-9]%', [Fax]) )
                                              + 2, ( LEN([Fax]) )) COLLATE SQL_Latin1_General_CP1_CI_AS 
                             ELSE '0'
                                  + SUBSTRING(( [tempdb].[dbo].[FN_Replace0To8]([Fax]) ),
                                              2, LEN([Fax]) - 1) COLLATE SQL_Latin1_General_CP1_CI_AS 
                        END
        WHERE   [Fax] IS NOT NULL
                AND REPLACE([Fax], ' ', '') <> ''

-- Scramble Email Addresses
        UPDATE  [dbo].[Addresses]
        SET     [Email] = @ClientEmail
        WHERE   ISNULL([Email], '') <> ''
		
        UPDATE  [dbo].[Emails]
        SET     [FromEmail] = @ClientEmail
        WHERE   ISNULL([FromEmail], '') <> ''
		
        UPDATE  [dbo].[LetterHistory]
        SET     [Email] = @ClientEmail
        WHERE   ISNULL([Email], '') <> ''
		
        UPDATE  [dbo].[LetterOutbox]
        SET     [Email] = @ClientEmail
        WHERE   ISNULL([Email], '') <> ''


-- Scramble Client Names if required
        IF @DataScrambleName = 1 
            BEGIN
                BEGIN TRAN UpdateNames
		
                UPDATE  [dbo].[DDHistory]
                SET     [DAccountName] = [tempdb].[dbo].[FN_ScrambleName]([DAccountName],
                                                              1)
                WHERE   ISNULL([DAccountName], '') <> ''
			
                UPDATE  [dbo].[DDOutbox]
                SET     [DAccountName] = [tempdb].[dbo].[FN_ScrambleName]([DAccountName],
                                                              1)
                WHERE   ISNULL([DAccountName], '') <> ''

                UPDATE  [dbo].[Debtors]
                SET     [LastName] = [tempdb].[dbo].[FN_ScrambleName]([LastName],
                                                              0)
                WHERE   ISNULL([LastName], '') <> ''

                UPDATE  [dbo].[LetterHistory]
                SET     [LASTNAME] = [tempdb].[dbo].[FN_ScrambleName]([LASTNAME],
                                                              0)
                WHERE   ISNULL([LASTNAME], '') <> ''
			
                UPDATE  [dbo].[LetterOutbox]
                SET     [LASTNAME] = [tempdb].[dbo].[FN_ScrambleName]([LASTNAME],
                                                              0)
                WHERE   ISNULL([LASTNAME], '') <> ''
		
                UPDATE  [dbo].[PaymentPlan]
                SET     [DAccountName] = [tempdb].[dbo].[FN_ScrambleName]([DAccountName],
                                                              1)
                WHERE   ISNULL([DAccountName], '') <> ''
			
                UPDATE  [dbo].[Emails]
                SET     [FromName] = [tempdb].[dbo].[FN_ScrambleName]([FromName],
                                                              1)
                WHERE   ISNULL([FromName], '') <> ''

                COMMIT TRAN UpdateNames
            END
  
  -- Scramble Client Addresses if required
        IF @DataScrambleAddress = 1 
            BEGIN
							
                UPDATE  [dbo].[Addresses]
                SET     Street1 = CASE WHEN ISNULL([Street1], '') <> ''
                                       THEN @HouseNameorNumber
                                  END ,
                        Street2 = CASE WHEN ISNULL([Street2], '') <> ''
                                       THEN @AddressLine1
                                  END ,
                        Street3 = CASE WHEN ISNULL([Street3], '') <> ''
                                       THEN @AddressLine2
                                  END ,
                        Street4 = CASE WHEN ISNULL([Street4], '') <> ''
                                       THEN @AddressLine3
                                  END ,
                        Town = CASE WHEN ISNULL([Town], '') <> ''
                                    THEN @AddressLine4
                               END ,
                        County = CASE WHEN ISNULL([County], '') <> ''
                                      THEN @Region
                                 END ,
                        Country = CASE WHEN ISNULL([Country], '') <> ''
                                       THEN @Country
                                  END  
            END
		-- Raise an error if no rows were selected from the Environment Data Values Table
        IF @DataRowCount = 0 
            RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)

    END
