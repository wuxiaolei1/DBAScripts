:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
PRINT 'Step 2 - Data Scramble - DCSLive'
USE DCSLive
GO

SET XACT_ABORT ON;

DECLARE @ClientTelNo VARCHAR(20) ,
    @ClientEmail VARCHAR(50) ,
    @Website VARCHAR(50) ,
    @NetSendUser VARCHAR(30) ,
    @CommsSendEmails BIT ,
    @SendXLlProcFileTo VARCHAR(50) ,
    @CommsServer1 VARCHAR(30) ,
    @CommsServer2 VARCHAR(30) ,
    @AppointmentMobTel VARCHAR(255) ,
    @RefEmail VARCHAR(50) ,
    @RefTelNo VARCHAR(20) ,
    @ScrambleData BIT ,
    @HouseNameorNumber VARCHAR(50) ,
    @AddressLine1 VARCHAR(30) ,
    @AddressLine2 VARCHAR(30) ,
    @AddressLine3 VARCHAR(30) ,
    @AddressLine4 VARCHAR(30) ,
    @PostTown VARCHAR(30) ,
    @Region VARCHAR(30) ,
    @Postcode VARCHAR(15) ,
    @Country INT ,
    @Environment VARCHAR(15) ,
    @DataRowCount INT ,
    @DataScrambleName INT -- 1 = Yes Scramble Name
    ,
    @DataScrambleAddress INT
 -- 1 = Yes Scramble Address

--SET DEFAULTS...
SET @ClientTelNo = '09999999999'
SET @ClientEmail = 'thisisadummyemail@notstepchange.co.na'
 --'no-reply@stepchange.org'
SET @Website = 'ws'
SET @netSendUser = 'thisisadummyemail'
SET @CommsSendEmails = 0
SET @SendXLlProcFileTo = 'thisisadummyemail@notstepchange.co.na'
 --'@stepchange.org'
--SET @CommsServer1 = '\\LDSCOMPRO1APP01'
--SET @CommsServer2 = '\\LDSCOMPRO1APP02'
SET @CommsServer1 = '\\SYSAPSCOMSAPP01'
SET @CommsServer2 = '\\SYSAPSCOMSAPP02'
SET @AppointmentMobTel = '09999999999'
SET @RefEmail = 'thisisadummyemail@notstepchange.co.na'
 --'no-reply@stepchange.org'
SET @RefTelNo = '09999999999'
SET @ScrambleData = 1
SET @HouseNameorNumber = 'StepChange - Systems Department'
SET @AddressLine1 = ''
SET @AddressLine2 = NULL
SET @AddressLine3 = NULL
SET @AddressLine4 = ''
SET @PostTown = 'Leeds'
SET @Region = 'Yorkshire'
SET @Postcode = 'LS2 8NG'
SET @Country = 826
SET @Environment = $(Environment)
SET @DataRowCount = 0
SET @DataScrambleName = 1
SET @DataScrambleAddress = 1

--Read the specific settings if available...
SELECT  @ClientTelNo = EDV.TelNo ,
        @ClientEmail = EDV.ClientEmail ,
        @Website = EDV.Website ,
        @netSendUser = EDV.netSendUser ,
        @CommsSendEmails = EDV.CommsSendEmails ,
        @SendXLlProcFileTo = EDV.SendXLlProcFileTo ,
        @CommsServer1 = EDV.CommsServer1 ,
        @CommsServer2 = EDV.CommsServer2 ,
        @AppointmentMobTel = EDV.MobileNo ,
        @RefEmail = EDV.Email ,
        @RefTelNo = EDV.TelNo ,
        @ScrambleData = EDV.DataScramble ,
        @HouseNameorNumber = EDV.HouseNameorNumber ,
        @AddressLine1 = EDV.AddressLine1 ,
        @AddressLine2 = EDV.AddressLine2 ,
        @AddressLine3 = EDV.AddressLine3 ,
        @AddressLine4 = EDV.AddressLine4 ,
        @PostTown = EDV.PostTown ,
        @Region = EDV.Region ,
        @Postcode = EDV.PostCode ,
        @Country = EDV.CountryCode ,
        @DataScrambleName = EDV.DataScrambleName ,
        @DataScrambleAddress = EDV.DataScrambleAddress
FROM    EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE   Environment = @Environment

SET @DataRowCount = @@Rowcount

IF @ScrambleData = 1 
    BEGIN
  
		PRINT 'Disabling COP Triggers';
		
		DISABLE TRIGGER ALL ON [dbo].[tblAddress];
		DISABLE TRIGGER ALL ON [dbo].[tblAssociateAddress];
		DISABLE TRIGGER ALL ON [dbo].[tblAssociateContact];
		DISABLE TRIGGER ALL ON [dbo].[tblAssociateRelationship];
		DISABLE TRIGGER ALL ON [dbo].[tblClient];
		DISABLE TRIGGER ALL ON [dbo].[tblCLIENT_AUTHORITY];
		DISABLE TRIGGER ALL ON [dbo].[tblCLIENT_DEBT_REASON];
		DISABLE TRIGGER ALL ON [dbo].[tblClientPerson];
		DISABLE TRIGGER ALL ON [dbo].[tblClientPersonName];
		DISABLE TRIGGER ALL ON [dbo].[tblContact];
		DISABLE TRIGGER ALL ON [dbo].[tblNamedAssociate];
		DISABLE TRIGGER ALL ON [dbo].[tblClient_Notes];
		 
		PRINT 'Starting data scrambling @ ...'
        PRINT GETDATE()
	
        UPDATE  tblcommunication_request
        SET     cr_processing_status = 'B'
        WHERE   cr_processing_status = 'P'

        UPDATE  tblContact
        SET     Value = CASE Con.TypeID
                          WHEN 3 /*Email*/ THEN @ClientEmail
                          WHEN 4 /*Website*/ THEN @Website
                        END
        FROM    tblContact Con
                INNER JOIN tblAssociateContact AC ON AC.ContactID = Con.ID
                INNER JOIN tblClientPerson CP ON CP.AssociateID = AC.AssociateID 
                INNER JOIN tblAssociateRelationship AR ON CP.AssociateID = AR.FromID
                INNER JOIN tblClient C ON C.ClientID = AR.ToID 
		WHERE	Con.TypeID IN (3,4) -- 03/04/2014 - Added to fix issue with phone numbers all updating to NULL value

		UPDATE  tblContact
		SET     Value = 
		CASE  
		WHEN PATINDEX('%[^0-9]%',Value)  =1 THEN SUBSTRING(Value,1,(PATINDEX('%[^0-9]%',Value))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](Value)),(PATINDEX('%[^0-9]%',Value))+2,(LEN(Value)))
		COLLATE SQL_Latin1_General_CP1_CI_AS 
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](Value)),2,LEN(Value)-1)
		COLLATE SQL_Latin1_General_CP1_CI_AS
		END
		FROM    tblContact Con
        INNER JOIN tblAssociateContact AC ON AC.ContactID = Con.ID
        INNER JOIN tblClientPerson CP ON CP.AssociateID = AC.AssociateID 
        INNER JOIN tblAssociateRelationship AR ON CP.AssociateID = AR.FromID
        INNER JOIN tblClient C ON C.ClientID = AR.ToID 
		WHERE value IS NOT NULL AND REPLACE(value,' ','') <> '' and Con.TypeID in (1,2,5)  
		/*1:Telephone 2:Mobile 5:Fax*/

		--TABLE: dbo.tblDC_GACS
        UPDATE  dbo.tblDC_GACS
        SET     DC_GACS_EMAIL = CASE WHEN DC_GACS_EMAIL IS NOT NULL
                                          OR DC_GACS_EMAIL <> ''
                                     THEN @RefEmail
                                END 
		UPDATE  dbo.tblDC_GACS
		SET DC_GACS_TELNO = 
		CASE  
		WHEN PATINDEX('%[^0-9]%',DC_GACS_TELNO)  =1 THEN SUBSTRING(DC_GACS_TELNO,1,(PATINDEX('%[^0-9]%',DC_GACS_TELNO))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](DC_GACS_TELNO)),(PATINDEX('%[^0-9]%',DC_GACS_TELNO))+2,(LEN(DC_GACS_TELNO)))
		COLLATE SQL_Latin1_General_CP1_CI_AS 
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](DC_GACS_TELNO)),2,LEN(DC_GACS_TELNO)-1)
		COLLATE SQL_Latin1_General_CP1_CI_AS
		END
		WHERE DC_GACS_TELNO IS NOT NULL AND REPLACE(DC_GACS_TELNO,' ','') <> ''
		
		--TABLE: dbo.tblEmailArchive
        UPDATE  dbo.tblEmailArchive
        SET     Email_To = @ClientEmail
        WHERE   ISNULL(Email_To, '') <> ''

		--TABLE: dbo.tblSMSAppointmentData
		UPDATE  dbo.tblSMSAppointmentData
		SET     MobileNo = CASE  
		WHEN PATINDEX('%[^0-9]%',MobileNo)  =1 THEN SUBSTRING(MobileNo,1,(PATINDEX('%[^0-9]%',MobileNo))) + '0'
		+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](MobileNo)),(PATINDEX('%[^0-9]%',MobileNo))+2,(LEN(MobileNo)))
		COLLATE SQL_Latin1_General_CP1_CI_AS 
		ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](MobileNo)),2,LEN(MobileNo)-1)
		COLLATE SQL_Latin1_General_CP1_CI_AS
		END
		WHERE MobileNo IS NOT NULL AND REPLACE(MobileNo,' ','') <> ''

		--TABLE: dbo.tblCommProductionQueue
        UPDATE  tblCommProductionqueue
        SET     PQ_StatusID = 2 ,
                PQ_NetSendiD = @netSendUser

		--TABLE: dbo.tblSystem_References

        UPDATE  tblSystem_References
        SET     Reference_display_value = CAST(@CommsSendEmails AS VARCHAR(1))
        WHERE   reference_type = 20

		-- Removed by request as it was causing validation issues in UAT
		--UPDATE	tblSystem_References
		--SET	Reference_display_value = @RefEmail
		--WHERE	reference_type IN (11, 19, 21, 39, 41, 43, 68, 82, 83, 99)

		-- Removed by request as it was causing validation issues in UAT
		--UPDATE	tblSystem_References
		--SET	Reference_display_value = @RefTelNo
		--WHERE	reference_type IN (3, 6, 9, 10, 13, 18, 38, 42, 44, 45, 52, 57, 58, 62, 67, 76, 94)

		--TABLE: dbo.tblCommFileAttributes
        UPDATE  tblCommfileAttributes
        SET     CFA_DestinationAddress = @SendXLlProcFileTo
        WHERE   CFA_DestinationAddress <> 'C:\temp'

		--TABLE: dbo.tblCommunication_request
        UPDATE  tblCommunication_request
        SET     CR_Recipient_Override_name = @SendXLlProcFileTo
        WHERE   NOT CR_Recipient_Override_name IS NULL

		--TABLE: dbo.tblDisastorContingency
        UPDATE  dbo.tblDisastorContingency
        SET     Location = @RefEmail
        WHERE   ID = 10
		
-- Scramble Client Names if required
        IF @DataScrambleName = 1 
            BEGIN
                BEGIN TRAN UpdateNames
			
			--TABLE: tblClient
                UPDATE  dbo.tblClient
                SET     DMSClientName = [tempdb].[dbo].[FN_ScrambleName](DMSClientName,
                                                              1)
                WHERE   ISNULL(DMSClientName, '') <> '' 
				
			--TABLE: tblClientPersonName
                UPDATE  dbo.tblClientPersonName
                SET     LastName = CASE WHEN LastName IS NOT NULL
                                             OR LastName <> ''
                                        THEN [tempdb].[dbo].[FN_ScrambleName](LastName,
                                                              0)
                                   END ,
                        PreviousLastName = CASE WHEN PreviousLastName IS NOT NULL
                                                     OR PreviousLastName <> ''
                                                THEN [tempdb].[dbo].[FN_ScrambleName](PreviousLastName,
                                                              0)
                                           END
			
			--TABLE: tblNamedAssociate
                UPDATE  dbo.tblNamedAssociate
                SET     [Name] = [tempdb].[dbo].[FN_ScrambleName]([Name],
                                                              1)
                WHERE   ISNULL([Name], '') <> ''
			
                COMMIT TRAN UpdateNames
            END
		
-- Scramble Client Addresses if required
        IF @DataScrambleAddress = 1 
            BEGIN
			--TABLE: dbo.tblAddress		
                UPDATE  dbo.tblAddress
                SET     HouseNameorNumber = CASE WHEN HouseNameorNumber IS NOT NULL
                                                      OR HouseNameorNumber <> ''
                                                 THEN @HouseNameorNumber
                                            END ,
                        AddressLine1 = CASE WHEN AddressLine1 IS NOT NULL
                                                 OR AddressLine1 <> ''
                                            THEN @AddressLine1
                                       END ,
                        AddressLine2 = CASE WHEN AddressLine2 IS NOT NULL
                                                 OR AddressLine2 <> ''
                                            THEN @AddressLine2
                                       END ,
                        AddressLine3 = CASE WHEN AddressLine3 IS NOT NULL
                                                 OR AddressLine3 <> ''
                                            THEN @AddressLine3
                                       END ,
                        PostTown = CASE WHEN PostTown IS NOT NULL
                                             OR PostTown <> '' THEN @PostTown
                                   END ,
                        Region = CASE WHEN Region IS NOT NULL
                                           OR Region <> '' THEN @Region
                                 END ,
                        --PostCode = CASE WHEN PostCode IS NOT NULL
                        --                     OR PostCode <> '' THEN @Postcode
                        --           END ,
                        Country = CASE WHEN Country IS NOT NULL
                                            OR Country <> '' THEN @Country
                                  END
  
  
			-- CREDITORS
			
                UPDATE  dbo.tblCLIENT_DEBT
                SET     CD_Client_Stated_Creditor_Address = CASE
                                                              WHEN CD_Client_Stated_Creditor_Address IS NOT NULL
                                                              OR CD_Client_Stated_Creditor_Address <> ''
                                                              THEN @HouseNameorNumber
                                                              + ', '
                                                              + @PostTown
                                                              + ', '
                                                              + @Postcode
                                                            END
            END		

		PRINT 'Enabling COP Triggers';
		
		ENABLE TRIGGER ALL ON [dbo].[tblAddress];
		ENABLE TRIGGER ALL ON [dbo].[tblAssociateAddress];
		ENABLE TRIGGER ALL ON [dbo].[tblAssociateContact];
		ENABLE TRIGGER ALL ON [dbo].[tblAssociateRelationship];
		ENABLE TRIGGER ALL ON [dbo].[tblClient];
		ENABLE TRIGGER ALL ON [dbo].[tblCLIENT_AUTHORITY];
		ENABLE TRIGGER ALL ON [dbo].[tblCLIENT_DEBT_REASON];
		ENABLE TRIGGER ALL ON [dbo].[tblClientPerson];
		ENABLE TRIGGER ALL ON [dbo].[tblClientPersonName];
		ENABLE TRIGGER ALL ON [dbo].[tblContact];
		ENABLE TRIGGER ALL ON [dbo].[tblNamedAssociate];
		ENABLE TRIGGER ALL ON [dbo].[tblClient_Notes];


		/* Truncate the new BusAdapter table created for COP in any environment except daily */
		IF LEFT(@@SERVERNAME,4) = 'VM01'
		BEGIN
			/* [BusAdapter].[tblContactChangeTable] */
			UPDATE [BusAdapter].[tblContactChangeTable]
			SET ins_VALUE = CASE [ins_TypeID]
								WHEN 3 /*Email*/ THEN @ClientEmail
								WHEN 4 /*Website*/ THEN @Website
								ELSE ins_VALUE
							END,
				del_VALUE = CASE [del_TypeID]
								WHEN 3 /*Email*/ THEN @ClientEmail
								WHEN 4 /*Website*/ THEN @Website
								ELSE del_VALUE
							END;

			UPDATE [BusAdapter].[tblContactChangeTable]
				SET     ins_Value = 
				CASE  
				WHEN PATINDEX('%[^0-9]%',ins_Value)  =1 THEN SUBSTRING(ins_Value,1,(PATINDEX('%[^0-9]%',ins_Value))) + '0'
				+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](ins_Value)),(PATINDEX('%[^0-9]%',ins_Value))+2,(LEN(ins_Value)))
				COLLATE SQL_Latin1_General_CP1_CI_AS 
				ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](ins_Value)),2,LEN(ins_Value)-1)
				COLLATE SQL_Latin1_General_CP1_CI_AS
				END
				WHERE ins_value IS NOT NULL AND REPLACE(ins_value,' ','') <> '' and ins_TypeID in (1,2,5)  ;
				/*1:Telephone 2:Mobile 5:Fax*/

			UPDATE [BusAdapter].[tblContactChangeTable]
				SET     ins_Value = 
				CASE  
				WHEN PATINDEX('%[^0-9]%',del_Value)  =1 THEN SUBSTRING(del_Value,1,(PATINDEX('%[^0-9]%',del_Value))) + '0'
				+ SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](del_Value)),(PATINDEX('%[^0-9]%',del_Value))+2,(LEN(del_Value)))
				COLLATE SQL_Latin1_General_CP1_CI_AS 
				ELSE '0' + SUBSTRING(([tempdb].[dbo].[FN_Replace0To8](del_Value)),2,LEN(del_Value)-1)
				COLLATE SQL_Latin1_General_CP1_CI_AS
				END
				WHERE del_value IS NOT NULL AND REPLACE(del_value,' ','') <> '' and del_TypeID in (1,2,5)  ;
				/*1:Telephone 2:Mobile 5:Fax*/


			/* [BusAdapter].[tblAddressChangeTable] */
			UPDATE  [BusAdapter].[tblAddressChangeTable] 
			SET     ins_HouseNameorNumber = CASE WHEN ins_HouseNameorNumber IS NOT NULL
													OR ins_HouseNameorNumber <> ''
												THEN @HouseNameorNumber
										END ,
					ins_AddressLine1 = CASE WHEN ins_AddressLine1 IS NOT NULL
												OR ins_AddressLine1 <> ''
										THEN @AddressLine1
									END ,
				   ins_AddressLine2 = CASE WHEN ins_AddressLine2 IS NOT NULL
												OR ins_AddressLine2 <> ''
										THEN @AddressLine2
									END ,
					ins_AddressLine3 = CASE WHEN ins_AddressLine3 IS NOT NULL
												OR ins_AddressLine3 <> ''
										THEN @AddressLine3
									END ,
					ins_PostTown = CASE WHEN ins_PostTown IS NOT NULL
											OR ins_PostTown <> '' THEN @PostTown
								END ,
					ins_Region = CASE WHEN ins_Region IS NOT NULL
										OR ins_Region <> '' THEN @Region
								END ,
					ins_Country = CASE WHEN ins_Country IS NOT NULL
										OR ins_Country <> '' THEN @Country
								END ,
					del_HouseNameorNumber = CASE WHEN del_HouseNameorNumber IS NOT NULL
													OR del_HouseNameorNumber <> ''
												THEN @HouseNameorNumber
										END ,
					del_AddressLine1 = CASE WHEN del_AddressLine1 IS NOT NULL
												OR del_AddressLine1 <> ''
										THEN @AddressLine1
									END ,
					del_AddressLine2 = CASE WHEN del_AddressLine2 IS NOT NULL
												OR del_AddressLine2 <> ''
										THEN @AddressLine2
									END ,
					del_AddressLine3 = CASE WHEN del_AddressLine3 IS NOT NULL
												OR del_AddressLine3 <> ''
										THEN @AddressLine3
									END ,
					del_PostTown = CASE WHEN del_PostTown IS NOT NULL
											OR del_PostTown <> '' THEN @PostTown
								END ,
					del_Region = CASE WHEN del_Region IS NOT NULL
										OR del_Region <> '' THEN @Region
								END ,
					del_Country = CASE WHEN del_Country IS NOT NULL
										OR del_Country <> '' THEN @Country
								END;
	
			/* [BusAdapter].[tblClientChangeTable] */
			UPDATE  [BusAdapter].[tblClientChangeTable]
			SET     ins_DMSClientName = [tempdb].[dbo].[FN_ScrambleName](ins_DMSClientName,1)
			WHERE   ISNULL(ins_DMSClientName, '') <> '' ;

			UPDATE  [BusAdapter].[tblClientChangeTable]
			SET     del_DMSClientName = [tempdb].[dbo].[FN_ScrambleName](del_DMSClientName,1)
			WHERE   ISNULL(del_DMSClientName, '') <> '' ;
				
			/* [BusAdapter].[tblClientPersonNameChangeTable] */
			UPDATE  [BusAdapter].[tblClientPersonNameChangeTable]
			SET     ins_LastName = CASE WHEN ins_LastName IS NOT NULL
											OR ins_LastName <> ''
									THEN [tempdb].[dbo].[FN_ScrambleName](ins_LastName, 0)
								END ,
					ins_PreviousLastName = CASE WHEN ins_PreviousLastName IS NOT NULL
													OR ins_PreviousLastName <> ''
											THEN [tempdb].[dbo].[FN_ScrambleName](ins_PreviousLastName, 0)
										END;
			UPDATE  [BusAdapter].[tblClientPersonNameChangeTable]
			SET     del_LastName = CASE WHEN del_LastName IS NOT NULL
											OR del_LastName <> ''
									THEN [tempdb].[dbo].[FN_ScrambleName](del_LastName, 0)
								END ,
					del_PreviousLastName = CASE WHEN del_PreviousLastName IS NOT NULL
													OR del_PreviousLastName <> ''
											THEN [tempdb].[dbo].[FN_ScrambleName](del_PreviousLastName, 0)
										END;

			/* [BusAdapter].[tblNamedAssociateChangeTable] */
			UPDATE  [BusAdapter].[tblNamedAssociateChangeTable]
			SET     ins_Name = [tempdb].[dbo].[FN_ScrambleName](ins_Name,1)
			WHERE   ISNULL(ins_Name, '') <> '';

			UPDATE  [BusAdapter].[tblNamedAssociateChangeTable]
			SET     del_Name = [tempdb].[dbo].[FN_ScrambleName](del_Name,1)
			WHERE   ISNULL(del_Name, '') <> '';

		END
		ELSE
		BEGIN
			SELECT ROW_NUMBER() OVER(ORDER BY name) AS ID 
					, name  
			INTO #BusAdapterTables
			FROM sys.objects 
			WHERE type in (N'U') 
			AND schema_id = SCHEMA_ID('BusAdapter');

			DECLARE @i TINYINT, @maxi TINYINT;
			DECLARE @sql NVARCHAR(4000);

			SELECT @i=1, @maxi = MAX(ID)
			FROM #BusAdapterTables;

			WHILE @i <= @maxi
			BEGIN
				SELECT @sql = 'TRUNCATE TABLE [BusAdapter].[' + name + '];'
				FROM #BusAdapterTables
				WHERE ID = @i;
	
				EXEC(@sql);
	
				SET @i = @i + 1;
			END;
		END;
		
        PRINT 'Scrambling completed successfully at ...'
        PRINT GETDATE()

	-- Raise an error if no rows were selected from the Environment Data Values Table
        IF @DataRowCount = 0 
            RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
    END
  
    
