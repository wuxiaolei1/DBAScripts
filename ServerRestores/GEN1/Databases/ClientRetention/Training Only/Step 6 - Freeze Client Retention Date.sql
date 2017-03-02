USE [ClientRetention]
GO

--TO SET THE PROCEDURE TO USE A SPECIFIC DATE
--SEARCH AND REPLACE ON $(FreezeDate) WITH THE DATE YOU REQUIRE
--IN THE FORMAT 'YYYYMMDD', e.g. '20120619'
--THEN RUN THIS SCRIPT TO ALTER THE PROCEDURE AND THE REST IS GOOD

/****** Object:  StoredProcedure [dbo].[GetCommunicationStats]    Script Date: 02/08/2012 16:06:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GetCommunicationStats]
								@ReducedPayer BIT = 0,
								@FirstMonth BIT = 0,
								@UsePriorityType BIT = 0,
								@PriorityType INT = 0
AS 
BEGIN
-- ===========================================================
-- Modified By:		Robert Foley
-- Modified date:	28/11/2011
-- Description:		Changed for CHG33218 - including priority parameters for 
--								filtering, a little messy.
-- ===========================================================
-- ===========================================================
-- Modified By:		Tom Braham
-- Modified date:	20/04/2010
-- Description:		Rewritten to improve performance, removed the 
--								use of the vwCurrentCases and vwPaymentRange.
--								Changed for CHG31832
-- ===========================================================
-- Modified By:		Lee Insley
-- Modified date:	27/07/2010
-- Description:		Changed for Phase 2 - including the new 
--								ReducedPayer and FirstMonth parameters for 
--								filtering
-- ===========================================================
    SET NOCOUNT ON

-- Results required are (SMS used for an example):
--
-- Number of clients remaining to be contacted (outstanding):
--    1. No SMS has been sent for this period
--    2. No conversation has been recorded betweenStepChangeand the client for this period
-- 
-- Number of clients who have already been contacted (completed):
--    1. SMS has been sent to client for this period


    DECLARE @CurrentTime DATETIME
    SELECT  @CurrentTime = $(FreezeDate)


-- create a temp table for the results to make it easier to add stuff that [potentially] isn't there
    CREATE TABLE #CR__GetCommunicationStats
        (
          PaymentTypeID TINYINT NOT NULL,
          ContactTypeID TINYINT NOT NULL,
          NumOutstanding INT NOT NULL,
          NumCompleted INT NOT NULL,
          LastBatch DATETIME
        )

-- start off by inserting all combinations of Payment and Contact Types (so we only have to do updates later)
    INSERT  INTO #CR__GetCommunicationStats
            (
              PaymentTypeID,
              ContactTypeID,
              NumOutstanding,
              NumCompleted,
              LastBatch
            )
            SELECT DISTINCT
                    pt.PaymentTypeID,
                    ct.ContactTypeID,
                    0 NumOutstanding,
                    0 NumCompleted,
                    NULL LastBatch
            FROM    PaymentTypes pt,
                    ContactTypes ct ;
					
	If @UsePriorityType = 1
	BEGIN
		-- 4in12
		If	@PriorityType = 0
		BEGIN
					-- ***************************************************************************************
		-- 1. Work out which SMS/Email have not had an Email or SMS sent (or Email&SMS for that matter)
			WITH CTE_PaymentRange
					  AS ( SELECT   ptsd.PaymentTypeID,
									ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
									CASE WHEN @CurrentTime < ptsd.StartDate
											  AND ptsd.StartDate < pr.CutOffDate
										 THEN ptsd.StartDate		--either not valid or cut off date is valid
										 ELSE pr.StartDate
									END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
									CASE WHEN @CurrentTime < pr.CutOffDate
										 THEN @CurrentTime
										 ELSE pr.FinishDate
									END FinishDate
						   FROM     dbo.PaymentTypeStartDates ptsd
									INNER JOIN dbo.PaymentRanges pr ON pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE    @CurrentTime >= pr.StartDate
									AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( SELECT	    rc.PaymentTypeID,
																  rc.ContactTypeID,
																	SUM(CASE WHEN ec.ECommID IS NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
																				THEN 1
																			 ELSE 0
																		  END) Outstanding
						  FROM			  dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.EComms ec 
														ON		rc.RetentionCaseID = ec.RetentionCaseID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
											AND					rc.PaymentTypeID IN (
																												SELECT  PaymentTypeID
																												FROM    dbo.PaymentTypeInclusions pti
																												WHERE   pti.[Include] = 1 
																											)
											AND					rc.PaymentRangeID IN (
																													SELECT  PaymentRangeID
																													FROM    CTE_PaymentRange 
																												)
											AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
																	COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) >= calculatedRange.StartDate
											AND					COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) <= calculatedRange.FinishDate
											AND

			-- 0 meaning no Contact, so we aren't interested in contacting them (JUT 8801)
																	rc.ContactTypeID <> 0
											AND					rc.ContactTypeID <> 4
											AND					Locks.RetentionCaseID IS NULL
											AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer in (0,1)
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre4in12)
 		
						  GROUP BY		rc.PaymentTypeID,
																	rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 2. Work out which SMS/Email _have_ had an Email or SMS sent (or Email&SMS for that matter)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( SELECT		PaymentTypeID,
															ContactTypeID,
															SUM(CASE WHEN ECommID IS NOT NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
											 THEN 1
										ELSE 0
								  END) Completed
										FROM      ( 
																SELECT			rc.PaymentTypeID,
																						rc.ContactTypeID,
																						ec.ECommID
																FROM				dbo.RetentionCases rc
																INNER JOIN	vwCurrentPaymentRange cpr 
																			ON		rc.PaymentRangeID = cpr.PaymentRangeID
																LEFT JOIN		dbo.EComms ec 
																			ON		rc.RetentionCaseID = ec.RetentionCaseID
																LEFT JOIN		dbo.ECommStates ecs 
																			ON		ecs.ECommStateID = ec.ECommStateID
																WHERE				rc.ContactTypeID <> 4 /*Exc Home Telephone as they will always fail on the SMS/Email lookup*/
									AND					ecs.[Name] = 'MsgSent'
																-- Add the reduced payer and first month filter in here for Phase 2
																AND					rc.ReducedPayer in (0,1)
																AND					rc.FirstMonth = 0
																AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre4in12)
																AND					((rc.BatchPriority IS NULL) OR (rc.BatchPriority = @PriorityType))	
																
															) ContactStatus
					  GROUP BY		PaymentTypeID,
															ContactTypeID
					) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 3. Work out which cases have had completed telephone calls against them 
		--    (note we're just looking at RetentionCase.DirectContactID and linking this to DirectContactOutcomes to exclude Sys.PaidByRefresh - JUT12887 CR Phase 2 - LI)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( 
										SELECT			RC.PaymentTypeID,
																RC.ContactTypeID,
																Completed = COUNT(*)
										FROM				dbo.RetentionCases rc
										INNER JOIN	vwCurrentPaymentRange cpr 
														ON	rc.PaymentRangeID = cpr.PaymentRangeID
										INNER JOIN	DirectContacts DC
													ON		RC.DirectContactID = DC.DirectContactID
										INNER JOIN	DirectContactOutcomes DCO
													ON		DC.DirectContactOutcomeID = DCO.DirectContactOutcomeID
													AND		DCO.[Name] <> 'Sys.PaidByRefresh'  -- Don't want to include system closed cases 
										WHERE				rc.ContactTypeID = 4
										-- Add the reduced payer and first month filter in here for Phase 2
										AND					rc.ReducedPayer in (0,1)
										AND					rc.FirstMonth = 0
										AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre4in12) 	
										GROUP BY		RC.PaymentTypeID,
																RC.ContactTypeID
									) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID;
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 4. Work out which cases have had outstanding telephone calls against them  
		--    (note we're just looking at RetentionCase.DirectContactID here rather than linked across to DirectContactOutcomes.CompletedCase)
			WITH    CTE_PaymentRange
					  AS ( SELECT			ptsd.PaymentTypeID,
																	ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
																	CASE WHEN @CurrentTime < ptsd.StartDate
																						AND ptsd.StartDate < pr.CutOffDate
																			 THEN ptsd.StartDate		--either not valid or cut off date is valid
																			 ELSE pr.StartDate
																	END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
																	CASE WHEN @CurrentTime < pr.CutOffDate
																			 THEN @CurrentTime
																			 ELSE pr.FinishDate
																	END FinishDate
						   FROM				dbo.PaymentTypeStartDates ptsd
						   INNER JOIN dbo.PaymentRanges pr 
															ON	pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE			@CurrentTime >= pr.StartDate
																	AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( 
											SELECT			rc.PaymentTypeID,
																	rc.ContactTypeID,
																	SUM(CASE WHEN rc.DirectContactID IS NULL
											 THEN 1
											 ELSE 0
									  END) Outstanding
						  FROM				dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
						  AND					rc.PaymentTypeID IN (
																											SELECT  PaymentTypeID
																											FROM    dbo.PaymentTypeInclusions pti
																											WHERE   pti.[Include] = 1 
																											)
						  AND					rc.PaymentRangeID IN (
																												SELECT  PaymentRangeID
																												FROM    CTE_PaymentRange 
																												)
						  AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
									COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) >= calculatedRange.StartDate
						  AND				COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) <= calculatedRange.FinishDate
						  AND				rc.ContactTypeID = 4
						  AND				Locks.RetentionCaseID IS NULL
			-- Add the reduced payer and first month filters in here for Phase 2
											AND					rc.ReducedPayer in (1,0)
										AND					rc.FirstMonth = 0
											AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre4in12)
											AND ((rc.NoContactNextContactTime < getdate()) or (rc.NoContactNextContactTime is null)) 	
						  GROUP BY  rc.PaymentTypeID,
									rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************	
		-- 3. Get the last batch info
		-- TODO for priority type
			UPDATE  #CR__GetCommunicationStats
			SET     LastBatch = batches.LastBatch
			FROM    ( SELECT    PaymentTypeID,
								ContactTypeID,
								MAX(Created) LastBatch
					  FROM      dbo.ECommBatches
									-- Add the reduced payer and first month filters in here for Phase 2
								--	WHERE			ReducedPayer = @ReducedPayer
								--	AND				FirstMonth = @FirstMonth
					  GROUP BY  PaymentTypeID,
								ContactTypeID
					) batches
			WHERE   batches.ContactTypeID = #CR__GetCommunicationStats.ContactTypeID
					AND batches.PaymentTypeID = #CR__GetCommunicationStats.PaymentTypeID
		-- ***************************************************************************************
		-- and return the results, flipped around into the format we want
			SELECT  *
			FROM    #CR__GetCommunicationStats
			ORDER BY PaymentTypeID,
					ContactTypeID
			DROP TABLE #CR__GetCommunicationStats
		END
		-- 3 in a row
		If	@PriorityType = 1
		BEGIN
		-- ***************************************************************************************
		-- 1. Work out which SMS/Email have not had an Email or SMS sent (or Email&SMS for that matter)
			WITH CTE_PaymentRange
					  AS ( SELECT   ptsd.PaymentTypeID,
									ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
									CASE WHEN @CurrentTime < ptsd.StartDate
											  AND ptsd.StartDate < pr.CutOffDate
										 THEN ptsd.StartDate		--either not valid or cut off date is valid
										 ELSE pr.StartDate
									END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
									CASE WHEN @CurrentTime < pr.CutOffDate
										 THEN @CurrentTime
										 ELSE pr.FinishDate
									END FinishDate
						   FROM     dbo.PaymentTypeStartDates ptsd
									INNER JOIN dbo.PaymentRanges pr ON pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE    @CurrentTime >= pr.StartDate
									AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( SELECT	    rc.PaymentTypeID,
																  rc.ContactTypeID,
																	SUM(CASE WHEN ec.ECommID IS NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
																				THEN 1
																			 ELSE 0
																		  END) Outstanding
						  FROM			  dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.EComms ec 
														ON		rc.RetentionCaseID = ec.RetentionCaseID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
											AND					rc.PaymentTypeID IN (
																												SELECT  PaymentTypeID
																												FROM    dbo.PaymentTypeInclusions pti
																												WHERE   pti.[Include] = 1 
																											)
											AND					rc.PaymentRangeID IN (
																													SELECT  PaymentRangeID
																													FROM    CTE_PaymentRange 
																												)
											AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
																	COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) >= calculatedRange.StartDate
											AND					COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) <= calculatedRange.FinishDate
											AND

			-- 0 meaning no Contact, so we aren't interested in contacting them (JUT 8801)
																	rc.ContactTypeID <> 0
											AND					rc.ContactTypeID <> 4
											AND					Locks.RetentionCaseID IS NULL
											AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer in (0,1)
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre3inRow) 		
						  GROUP BY		rc.PaymentTypeID,
																	rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 2. Work out which SMS/Email _have_ had an Email or SMS sent (or Email&SMS for that matter)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( SELECT		PaymentTypeID,
															ContactTypeID,
															SUM(CASE WHEN ECommID IS NOT NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
											 THEN 1
										ELSE 0
								  END) Completed
										FROM      ( 
																SELECT			rc.PaymentTypeID,
																						rc.ContactTypeID,
																						ec.ECommID
																FROM				dbo.RetentionCases rc
																INNER JOIN	vwCurrentPaymentRange cpr 
																			ON		rc.PaymentRangeID = cpr.PaymentRangeID
																LEFT JOIN		dbo.EComms ec 
																			ON		rc.RetentionCaseID = ec.RetentionCaseID
																LEFT JOIN		dbo.ECommStates ecs 
																			ON		ecs.ECommStateID = ec.ECommStateID
																WHERE				rc.ContactTypeID <> 4 /*Exc Home Telephone as they will always fail on the SMS/Email lookup*/
									AND					ecs.[Name] = 'MsgSent'
																-- Add the reduced payer and first month filter in here for Phase 2
																AND					rc.ReducedPayer in (0,1)
																AND					rc.FirstMonth = 0
																AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre3inRow)
										 						AND					((rc.BatchPriority IS NULL) OR (rc.BatchPriority = @PriorityType))	
																
															) ContactStatus
					  GROUP BY		PaymentTypeID,
															ContactTypeID
					) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 3. Work out which cases have had completed telephone calls against them 
		--    (note we're just looking at RetentionCase.DirectContactID and linking this to DirectContactOutcomes to exclude Sys.PaidByRefresh - JUT12887 CR Phase 2 - LI)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( 
										SELECT			RC.PaymentTypeID,
																RC.ContactTypeID,
																Completed = COUNT(*)
										FROM				dbo.RetentionCases rc
										INNER JOIN	vwCurrentPaymentRange cpr 
														ON	rc.PaymentRangeID = cpr.PaymentRangeID
										INNER JOIN	DirectContacts DC
													ON		RC.DirectContactID = DC.DirectContactID
										INNER JOIN	DirectContactOutcomes DCO
													ON		DC.DirectContactOutcomeID = DCO.DirectContactOutcomeID
													AND		DCO.[Name] <> 'Sys.PaidByRefresh'  -- Don't want to include system closed cases 
										WHERE				rc.ContactTypeID = 4
										-- Add the reduced payer and first month filter in here for Phase 2
										AND					rc.ReducedPayer in (0,1)
										AND					rc.FirstMonth = 0
										AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre3inRow)	
										GROUP BY		RC.PaymentTypeID,
																RC.ContactTypeID
									) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID;
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 4. Work out which cases have had outstanding telephone calls against them  
		--    (note we're just looking at RetentionCase.DirectContactID here rather than linked across to DirectContactOutcomes.CompletedCase)
			WITH    CTE_PaymentRange
					  AS ( SELECT			ptsd.PaymentTypeID,
																	ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
																	CASE WHEN @CurrentTime < ptsd.StartDate
																						AND ptsd.StartDate < pr.CutOffDate
																			 THEN ptsd.StartDate		--either not valid or cut off date is valid
																			 ELSE pr.StartDate
																	END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
																	CASE WHEN @CurrentTime < pr.CutOffDate
																			 THEN @CurrentTime
																			 ELSE pr.FinishDate
																	END FinishDate
						   FROM				dbo.PaymentTypeStartDates ptsd
						   INNER JOIN dbo.PaymentRanges pr 
															ON	pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE			@CurrentTime >= pr.StartDate
																	AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( 
											SELECT			rc.PaymentTypeID,
																	rc.ContactTypeID,
																	SUM(CASE WHEN rc.DirectContactID IS NULL
											 THEN 1
											 ELSE 0
									  END) Outstanding
						  FROM				dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
						  AND					rc.PaymentTypeID IN (
																											SELECT  PaymentTypeID
																											FROM    dbo.PaymentTypeInclusions pti
																											WHERE   pti.[Include] = 1 
																											)
						  AND					rc.PaymentRangeID IN (
																												SELECT  PaymentRangeID
																												FROM    CTE_PaymentRange 
																												)
						  AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
									COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) >= calculatedRange.StartDate
						  AND				COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) <= calculatedRange.FinishDate
						  AND				rc.ContactTypeID = 4
						  AND				Locks.RetentionCaseID IS NULL
			-- Add the reduced payer and first month filters in here for Phase 2
											AND					rc.ReducedPayer in (0,1)
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre3inRow)
											AND ((rc.NoContactNextContactTime < getdate()) or (rc.NoContactNextContactTime is null)) 	
						  GROUP BY  rc.PaymentTypeID,
									rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************	
		-- 3. Get the last batch info
		-- TODO for priority type
			UPDATE  #CR__GetCommunicationStats
			SET     LastBatch = batches.LastBatch
			FROM    ( SELECT    PaymentTypeID,
								ContactTypeID,
								MAX(Created) LastBatch
					  FROM      dbo.ECommBatches
									-- Add the reduced payer and first month filters in here for Phase 2
									--WHERE			ReducedPayer = @ReducedPayer
									--AND				FirstMonth = @FirstMonth
					  GROUP BY  PaymentTypeID,
								ContactTypeID
					) batches
			WHERE   batches.ContactTypeID = #CR__GetCommunicationStats.ContactTypeID
					AND batches.PaymentTypeID = #CR__GetCommunicationStats.PaymentTypeID
		-- ***************************************************************************************
		-- and return the results, flipped around into the format we want
			SELECT  *
			FROM    #CR__GetCommunicationStats
			ORDER BY PaymentTypeID,
					ContactTypeID

			DROP TABLE #CR__GetCommunicationStats
		END
		-- 1st Month
		If	@PriorityType = 2
		BEGIN
			-- ***************************************************************************************
			-- 1. Work out which SMS/Email have not had an Email or SMS sent (or Email&SMS for that matter)
			WITH CTE_PaymentRange
					  AS ( SELECT   ptsd.PaymentTypeID,
									ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
									CASE WHEN @CurrentTime < ptsd.StartDate
											  AND ptsd.StartDate < pr.CutOffDate
										 THEN ptsd.StartDate		--either not valid or cut off date is valid
										 ELSE pr.StartDate
									END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
									CASE WHEN @CurrentTime < pr.CutOffDate
										 THEN @CurrentTime
										 ELSE pr.FinishDate
									END FinishDate
						   FROM     dbo.PaymentTypeStartDates ptsd
									INNER JOIN dbo.PaymentRanges pr ON pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE    @CurrentTime >= pr.StartDate
									AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( SELECT	    rc.PaymentTypeID,
																  rc.ContactTypeID,
																	SUM(CASE WHEN ec.ECommID IS NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
																				THEN 1
																			 ELSE 0
																		  END) Outstanding
						  FROM			  dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.EComms ec 
														ON		rc.RetentionCaseID = ec.RetentionCaseID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
											AND					rc.PaymentTypeID IN (
																												SELECT  PaymentTypeID
																												FROM    dbo.PaymentTypeInclusions pti
																												WHERE   pti.[Include] = 1 
																											)
											AND					rc.PaymentRangeID IN (
																													SELECT  PaymentRangeID
																													FROM    CTE_PaymentRange 
																												)
											AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
																	COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) >= calculatedRange.StartDate
											AND					COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) <= calculatedRange.FinishDate
											AND

			-- 0 meaning no Contact, so we aren't interested in contacting them (JUT 8801)
																	rc.ContactTypeID <> 0
											AND					rc.ContactTypeID <> 4
											AND					Locks.RetentionCaseID IS NULL
											AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer = 0
											AND					rc.FirstMonth = 1		
						  GROUP BY		rc.PaymentTypeID,
																	rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 2. Work out which SMS/Email _have_ had an Email or SMS sent (or Email&SMS for that matter)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( SELECT		PaymentTypeID,
															ContactTypeID,
															SUM(CASE WHEN ECommID IS NOT NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
											 THEN 1
										ELSE 0
								  END) Completed
										FROM      ( 
																SELECT			rc.PaymentTypeID,
																						rc.ContactTypeID,
																						ec.ECommID
																FROM				dbo.RetentionCases rc
																INNER JOIN	vwCurrentPaymentRange cpr 
																			ON		rc.PaymentRangeID = cpr.PaymentRangeID
																LEFT JOIN		dbo.EComms ec 
																			ON		rc.RetentionCaseID = ec.RetentionCaseID
																LEFT JOIN		dbo.ECommStates ecs 
																			ON		ecs.ECommStateID = ec.ECommStateID
																WHERE				rc.ContactTypeID <> 4 /*Exc Home Telephone as they will always fail on the SMS/Email lookup*/
									AND					ecs.[Name] = 'MsgSent'
																-- Add the reduced payer and first month filter in here for Phase 2
																AND					rc.ReducedPayer = 0
																AND					rc.FirstMonth = 1
																AND					((rc.BatchPriority IS NULL) OR (rc.BatchPriority = @PriorityType))	
																
																
															) ContactStatus
					  GROUP BY		PaymentTypeID,
															ContactTypeID
					) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 3. Work out which cases have had completed telephone calls against them 
		--    (note we're just looking at RetentionCase.DirectContactID and linking this to DirectContactOutcomes to exclude Sys.PaidByRefresh - JUT12887 CR Phase 2 - LI)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( 
										SELECT			RC.PaymentTypeID,
																RC.ContactTypeID,
																Completed = COUNT(*)
										FROM				dbo.RetentionCases rc
										INNER JOIN	vwCurrentPaymentRange cpr 
														ON	rc.PaymentRangeID = cpr.PaymentRangeID
										INNER JOIN	DirectContacts DC
													ON		RC.DirectContactID = DC.DirectContactID
										INNER JOIN	DirectContactOutcomes DCO
													ON		DC.DirectContactOutcomeID = DCO.DirectContactOutcomeID
													AND		DCO.[Name] <> 'Sys.PaidByRefresh'  -- Don't want to include system closed cases 
										WHERE				rc.ContactTypeID = 4
										-- Add the reduced payer and first month filter in here for Phase 2
										AND					rc.ReducedPayer = 0
										AND					rc.FirstMonth = 1
										
										GROUP BY		RC.PaymentTypeID,
																RC.ContactTypeID
									) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID;
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 4. Work out which cases have had outstanding telephone calls against them  
		--    (note we're just looking at RetentionCase.DirectContactID here rather than linked across to DirectContactOutcomes.CompletedCase)
			WITH    CTE_PaymentRange
					  AS ( SELECT			ptsd.PaymentTypeID,
																	ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
																	CASE WHEN @CurrentTime < ptsd.StartDate
																						AND ptsd.StartDate < pr.CutOffDate
																			 THEN ptsd.StartDate		--either not valid or cut off date is valid
																			 ELSE pr.StartDate
																	END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
																	CASE WHEN @CurrentTime < pr.CutOffDate
																			 THEN @CurrentTime
																			 ELSE pr.FinishDate
																	END FinishDate
						   FROM				dbo.PaymentTypeStartDates ptsd
						   INNER JOIN dbo.PaymentRanges pr 
															ON	pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE			@CurrentTime >= pr.StartDate
																	AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( 
											SELECT			rc.PaymentTypeID,
																	rc.ContactTypeID,
																	SUM(CASE WHEN rc.DirectContactID IS NULL
											 THEN 1
											 ELSE 0
									  END) Outstanding
						  FROM				dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
						  AND					rc.PaymentTypeID IN (
																											SELECT  PaymentTypeID
																											FROM    dbo.PaymentTypeInclusions pti
																											WHERE   pti.[Include] = 1 
																											)
						  AND					rc.PaymentRangeID IN (
																												SELECT  PaymentRangeID
																												FROM    CTE_PaymentRange 
																												)
						  AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
									COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) >= calculatedRange.StartDate
						  AND				COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) <= calculatedRange.FinishDate
						  AND				rc.ContactTypeID = 4
						  AND				Locks.RetentionCaseID IS NULL
			-- Add the reduced payer and first month filters in here for Phase 2
											AND					rc.ReducedPayer = 0
											AND					rc.FirstMonth = 1
											AND ((rc.NoContactNextContactTime < getdate()) or (rc.NoContactNextContactTime is null)) 	
										
						  GROUP BY  rc.PaymentTypeID,
									rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************	
		-- 3. Get the last batch info
		-- TODO for priority type
			UPDATE  #CR__GetCommunicationStats
			SET     LastBatch = batches.LastBatch
			FROM    ( SELECT    PaymentTypeID,
								ContactTypeID,
								MAX(Created) LastBatch
					  FROM      dbo.ECommBatches
									-- Add the reduced payer and first month filters in here for Phase 2
									--WHERE			ReducedPayer = @ReducedPayer
									--AND				FirstMonth = @FirstMonth
					  GROUP BY  PaymentTypeID,
								ContactTypeID
					) batches
			WHERE   batches.ContactTypeID = #CR__GetCommunicationStats.ContactTypeID
					AND batches.PaymentTypeID = #CR__GetCommunicationStats.PaymentTypeID
		-- ***************************************************************************************
		-- and return the results, flipped around into the format we want
			SELECT  *
			FROM    #CR__GetCommunicationStats
			ORDER BY PaymentTypeID,
					ContactTypeID

			DROP TABLE #CR__GetCommunicationStats
		END
		-- 3 missed in 12
		If	@PriorityType = 3
		BEGIN		
		-- ***************************************************************************************
		-- 1. Work out which SMS/Email have not had an Email or SMS sent (or Email&SMS for that matter)
			WITH CTE_PaymentRange
					  AS ( SELECT   ptsd.PaymentTypeID,
									ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
									CASE WHEN @CurrentTime < ptsd.StartDate
											  AND ptsd.StartDate < pr.CutOffDate
										 THEN ptsd.StartDate		--either not valid or cut off date is valid
										 ELSE pr.StartDate
									END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
									CASE WHEN @CurrentTime < pr.CutOffDate
										 THEN @CurrentTime
										 ELSE pr.FinishDate
									END FinishDate
						   FROM     dbo.PaymentTypeStartDates ptsd
									INNER JOIN dbo.PaymentRanges pr ON pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE    @CurrentTime >= pr.StartDate
									AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( SELECT	    rc.PaymentTypeID,
																  rc.ContactTypeID,
																	SUM(CASE WHEN ec.ECommID IS NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
																				THEN 1
																			 ELSE 0
																		  END) Outstanding
						  FROM			  dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.EComms ec 
														ON		rc.RetentionCaseID = ec.RetentionCaseID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
											AND					rc.PaymentTypeID IN (
																												SELECT  PaymentTypeID
																												FROM    dbo.PaymentTypeInclusions pti
																												WHERE   pti.[Include] = 1 
																											)
											AND					rc.PaymentRangeID IN (
																													SELECT  PaymentRangeID
																													FROM    CTE_PaymentRange 
																												)
											AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
																	COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) >= calculatedRange.StartDate
											AND					COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) <= calculatedRange.FinishDate
											AND

			-- 0 meaning no Contact, so we aren't interested in contacting them (JUT 8801)
																	rc.ContactTypeID <> 0
											AND					rc.ContactTypeID <> 4
											AND					Locks.RetentionCaseID IS NULL
											AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer = 0
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre3in12)		
						  GROUP BY		rc.PaymentTypeID,
																	rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 2. Work out which SMS/Email _have_ had an Email or SMS sent (or Email&SMS for that matter)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( SELECT		PaymentTypeID,
															ContactTypeID,
															SUM(CASE WHEN ECommID IS NOT NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
											 THEN 1
										ELSE 0
								  END) Completed
										FROM      ( 
																SELECT			rc.PaymentTypeID,
																						rc.ContactTypeID,
																						ec.ECommID
																FROM				dbo.RetentionCases rc
																INNER JOIN	vwCurrentPaymentRange cpr 
																			ON		rc.PaymentRangeID = cpr.PaymentRangeID
																LEFT JOIN		dbo.EComms ec 
																			ON		rc.RetentionCaseID = ec.RetentionCaseID
																LEFT JOIN		dbo.ECommStates ecs 
																			ON		ecs.ECommStateID = ec.ECommStateID
																WHERE				rc.ContactTypeID <> 4 /*Exc Home Telephone as they will always fail on the SMS/Email lookup*/
									AND					ecs.[Name] = 'MsgSent'
																-- Add the reduced payer and first month filter in here for Phase 2
																AND					rc.ReducedPayer = 0
																AND					rc.FirstMonth = 0
																AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre3in12)
																AND					((rc.BatchPriority IS NULL) OR (rc.BatchPriority = @PriorityType))	
																
															) ContactStatus
					  GROUP BY		PaymentTypeID,
															ContactTypeID
					) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 3. Work out which cases have had completed telephone calls against them 
		--    (note we're just looking at RetentionCase.DirectContactID and linking this to DirectContactOutcomes to exclude Sys.PaidByRefresh - JUT12887 CR Phase 2 - LI)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( 
										SELECT			RC.PaymentTypeID,
																RC.ContactTypeID,
																Completed = COUNT(*)
										FROM				dbo.RetentionCases rc
										INNER JOIN	vwCurrentPaymentRange cpr 
														ON	rc.PaymentRangeID = cpr.PaymentRangeID
										INNER JOIN	DirectContacts DC
													ON		RC.DirectContactID = DC.DirectContactID
										INNER JOIN	DirectContactOutcomes DCO
													ON		DC.DirectContactOutcomeID = DCO.DirectContactOutcomeID
													AND		DCO.[Name] <> 'Sys.PaidByRefresh'  -- Don't want to include system closed cases 
										WHERE				rc.ContactTypeID = 4
										-- Add the reduced payer and first month filter in here for Phase 2
										AND					rc.ReducedPayer = 0
										AND					rc.FirstMonth = 0
										AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre3in12)
										GROUP BY		RC.PaymentTypeID,
																RC.ContactTypeID
									) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID;
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 4. Work out which cases have had outstanding telephone calls against them  
		--    (note we're just looking at RetentionCase.DirectContactID here rather than linked across to DirectContactOutcomes.CompletedCase)
			WITH    CTE_PaymentRange
					  AS ( SELECT			ptsd.PaymentTypeID,
																	ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
																	CASE WHEN @CurrentTime < ptsd.StartDate
																						AND ptsd.StartDate < pr.CutOffDate
																			 THEN ptsd.StartDate		--either not valid or cut off date is valid
																			 ELSE pr.StartDate
																	END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
																	CASE WHEN @CurrentTime < pr.CutOffDate
																			 THEN @CurrentTime
																			 ELSE pr.FinishDate
																	END FinishDate
						   FROM				dbo.PaymentTypeStartDates ptsd
						   INNER JOIN dbo.PaymentRanges pr 
															ON	pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE			@CurrentTime >= pr.StartDate
																	AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( 
											SELECT			rc.PaymentTypeID,
																	rc.ContactTypeID,
																	SUM(CASE WHEN rc.DirectContactID IS NULL
											 THEN 1
											 ELSE 0
									  END) Outstanding
						  FROM				dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
						  AND					rc.PaymentTypeID IN (
																											SELECT  PaymentTypeID
																											FROM    dbo.PaymentTypeInclusions pti
																											WHERE   pti.[Include] = 1 
																											)
						  AND					rc.PaymentRangeID IN (
																												SELECT  PaymentRangeID
																												FROM    CTE_PaymentRange 
																												)
						  AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
									COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) >= calculatedRange.StartDate
						  AND				COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) <= calculatedRange.FinishDate
						  AND				rc.ContactTypeID = 4
						  AND				Locks.RetentionCaseID IS NULL
			-- Add the reduced payer and first month filters in here for Phase 2
											AND					rc.ReducedPayer = 0
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre3in12)
											AND ((rc.NoContactNextContactTime < getdate()) or (rc.NoContactNextContactTime is null)) 	
						  GROUP BY  rc.PaymentTypeID,
									rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************	
		-- 3. Get the last batch info
		-- TODO for priority type
			UPDATE  #CR__GetCommunicationStats
			SET     LastBatch = batches.LastBatch
			FROM    ( SELECT    PaymentTypeID,
								ContactTypeID,
								MAX(Created) LastBatch
					  FROM      dbo.ECommBatches
									-- Add the reduced payer and first month filters in here for Phase 2
									--WHERE			ReducedPayer = @ReducedPayer
									--AND				FirstMonth = @FirstMonth
					  GROUP BY  PaymentTypeID,
								ContactTypeID
					) batches
			WHERE   batches.ContactTypeID = #CR__GetCommunicationStats.ContactTypeID
					AND batches.PaymentTypeID = #CR__GetCommunicationStats.PaymentTypeID
		-- ***************************************************************************************
		-- and return the results, flipped around into the format we want
			SELECT  *
			FROM    #CR__GetCommunicationStats
			ORDER BY PaymentTypeID,
					ContactTypeID

			DROP TABLE #CR__GetCommunicationStats
		END
		-- 2 in a row
		If	@PriorityType = 4
		BEGIN
			-- ***************************************************************************************
		-- 1. Work out which SMS/Email have not had an Email or SMS sent (or Email&SMS for that matter)
			WITH CTE_PaymentRange
					  AS ( SELECT   ptsd.PaymentTypeID,
									ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
									CASE WHEN @CurrentTime < ptsd.StartDate
											  AND ptsd.StartDate < pr.CutOffDate
										 THEN ptsd.StartDate		--either not valid or cut off date is valid
										 ELSE pr.StartDate
									END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
									CASE WHEN @CurrentTime < pr.CutOffDate
										 THEN @CurrentTime
										 ELSE pr.FinishDate
									END FinishDate
						   FROM     dbo.PaymentTypeStartDates ptsd
									INNER JOIN dbo.PaymentRanges pr ON pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE    @CurrentTime >= pr.StartDate
									AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( SELECT	    rc.PaymentTypeID,
																  rc.ContactTypeID,
																	SUM(CASE WHEN ec.ECommID IS NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
																				THEN 1
																			 ELSE 0
																		  END) Outstanding
						  FROM			  dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.EComms ec 
														ON		rc.RetentionCaseID = ec.RetentionCaseID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
											AND					rc.PaymentTypeID IN (
																												SELECT  PaymentTypeID
																												FROM    dbo.PaymentTypeInclusions pti
																												WHERE   pti.[Include] = 1 
																											)
											AND					rc.PaymentRangeID IN (
																													SELECT  PaymentRangeID
																													FROM    CTE_PaymentRange 
																												)
											AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
																	COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) >= calculatedRange.StartDate
											AND					COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) <= calculatedRange.FinishDate
											AND

			-- 0 meaning no Contact, so we aren't interested in contacting them (JUT 8801)
																	rc.ContactTypeID <> 0
											AND					rc.ContactTypeID <> 4
											AND					Locks.RetentionCaseID IS NULL
											AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer = 0
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre2inRow)		
						  GROUP BY		rc.PaymentTypeID,
																	rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 2. Work out which SMS/Email _have_ had an Email or SMS sent (or Email&SMS for that matter)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( SELECT		PaymentTypeID,
															ContactTypeID,
															SUM(CASE WHEN ECommID IS NOT NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
											 THEN 1
										ELSE 0
								  END) Completed
										FROM      ( 
																SELECT			rc.PaymentTypeID,
																						rc.ContactTypeID,
																						ec.ECommID
																FROM				dbo.RetentionCases rc
																INNER JOIN	vwCurrentPaymentRange cpr 
																			ON		rc.PaymentRangeID = cpr.PaymentRangeID
																LEFT JOIN		dbo.EComms ec 
																			ON		rc.RetentionCaseID = ec.RetentionCaseID
																LEFT JOIN		dbo.ECommStates ecs 
																			ON		ecs.ECommStateID = ec.ECommStateID
																WHERE				rc.ContactTypeID <> 4 /*Exc Home Telephone as they will always fail on the SMS/Email lookup*/
									AND					ecs.[Name] = 'MsgSent'
																-- Add the reduced payer and first month filter in here for Phase 2
																AND					rc.ReducedPayer = 0
																AND					rc.FirstMonth = 0
																AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre2inRow)
																AND					((rc.BatchPriority IS NULL) OR (rc.BatchPriority = @PriorityType))	
																
															) ContactStatus
					  GROUP BY		PaymentTypeID,
															ContactTypeID
					) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 3. Work out which cases have had completed telephone calls against them 
		--    (note we're just looking at RetentionCase.DirectContactID and linking this to DirectContactOutcomes to exclude Sys.PaidByRefresh - JUT12887 CR Phase 2 - LI)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( 
										SELECT			RC.PaymentTypeID,
																RC.ContactTypeID,
																Completed = COUNT(*)
										FROM				dbo.RetentionCases rc
										INNER JOIN	vwCurrentPaymentRange cpr 
														ON	rc.PaymentRangeID = cpr.PaymentRangeID
										INNER JOIN	DirectContacts DC
													ON		RC.DirectContactID = DC.DirectContactID
										INNER JOIN	DirectContactOutcomes DCO
													ON		DC.DirectContactOutcomeID = DCO.DirectContactOutcomeID
													AND		DCO.[Name] <> 'Sys.PaidByRefresh'  -- Don't want to include system closed cases 
										WHERE				rc.ContactTypeID = 4
										-- Add the reduced payer and first month filter in here for Phase 2
										AND					rc.ReducedPayer = 0
										AND					rc.FirstMonth = 0
										AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre2inRow)
										GROUP BY		RC.PaymentTypeID,
																RC.ContactTypeID
									) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID;
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 4. Work out which cases have had outstanding telephone calls against them  
		--    (note we're just looking at RetentionCase.DirectContactID here rather than linked across to DirectContactOutcomes.CompletedCase)
			WITH    CTE_PaymentRange
					  AS ( SELECT			ptsd.PaymentTypeID,
																	ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
																	CASE WHEN @CurrentTime < ptsd.StartDate
																						AND ptsd.StartDate < pr.CutOffDate
																			 THEN ptsd.StartDate		--either not valid or cut off date is valid
																			 ELSE pr.StartDate
																	END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
																	CASE WHEN @CurrentTime < pr.CutOffDate
																			 THEN @CurrentTime
																			 ELSE pr.FinishDate
																	END FinishDate
						   FROM				dbo.PaymentTypeStartDates ptsd
						   INNER JOIN dbo.PaymentRanges pr 
															ON	pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE			@CurrentTime >= pr.StartDate
																	AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( 
											SELECT			rc.PaymentTypeID,
																	rc.ContactTypeID,
																	SUM(CASE WHEN rc.DirectContactID IS NULL
											 THEN 1
											 ELSE 0
									  END) Outstanding
						  FROM				dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
						  AND					rc.PaymentTypeID IN (
																											SELECT  PaymentTypeID
																											FROM    dbo.PaymentTypeInclusions pti
																											WHERE   pti.[Include] = 1 
																											)
						  AND					rc.PaymentRangeID IN (
																												SELECT  PaymentRangeID
																												FROM    CTE_PaymentRange 
																												)
						  AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
									COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) >= calculatedRange.StartDate
						  AND				COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) <= calculatedRange.FinishDate
						  AND				rc.ContactTypeID = 4
						  AND				Locks.RetentionCaseID IS NULL
			-- Add the reduced payer and first month filters in here for Phase 2
											AND					rc.ReducedPayer = 0
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber in (SELECT DCSNumber FROM dbo.vwPre2inRow)
											AND ((rc.NoContactNextContactTime < getdate()) or (rc.NoContactNextContactTime is null)) 	
						  GROUP BY  rc.PaymentTypeID,
									rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************	
		-- 3. Get the last batch info
		-- TODO for priority type
			UPDATE  #CR__GetCommunicationStats
			SET     LastBatch = batches.LastBatch
			FROM    ( SELECT    PaymentTypeID,
								ContactTypeID,
								MAX(Created) LastBatch
					  FROM      dbo.ECommBatches
									-- Add the reduced payer and first month filters in here for Phase 2
								--	WHERE			ReducedPayer = @ReducedPayer
								--	AND				FirstMonth = @FirstMonth
					  GROUP BY  PaymentTypeID,
								ContactTypeID
					) batches
			WHERE   batches.ContactTypeID = #CR__GetCommunicationStats.ContactTypeID
					AND batches.PaymentTypeID = #CR__GetCommunicationStats.PaymentTypeID
		-- ***************************************************************************************
		-- and return the results, flipped around into the format we want
			SELECT  *
			FROM    #CR__GetCommunicationStats
			ORDER BY PaymentTypeID,
					ContactTypeID

			DROP TABLE #CR__GetCommunicationStats
		END
		-- Isolated Miss
		If	@PriorityType = 5
		BEGIN
			-- ***************************************************************************************
			-- 1. Work out which SMS/Email have not had an Email or SMS sent (or Email&SMS for that matter)
			WITH CTE_PaymentRange
					  AS ( SELECT   ptsd.PaymentTypeID,
									ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
									CASE WHEN @CurrentTime < ptsd.StartDate
											  AND ptsd.StartDate < pr.CutOffDate
										 THEN ptsd.StartDate		--either not valid or cut off date is valid
										 ELSE pr.StartDate
									END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
									CASE WHEN @CurrentTime < pr.CutOffDate
										 THEN @CurrentTime
										 ELSE pr.FinishDate
									END FinishDate
						   FROM     dbo.PaymentTypeStartDates ptsd
									INNER JOIN dbo.PaymentRanges pr ON pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE    @CurrentTime >= pr.StartDate
									AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( SELECT	    rc.PaymentTypeID,
																  rc.ContactTypeID,
																	SUM(CASE WHEN ec.ECommID IS NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
																				THEN 1
																			 ELSE 0
																		  END) Outstanding
						  FROM			  dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.EComms ec 
														ON		rc.RetentionCaseID = ec.RetentionCaseID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
											AND					rc.PaymentTypeID IN (
																												SELECT  PaymentTypeID
																												FROM    dbo.PaymentTypeInclusions pti
																												WHERE   pti.[Include] = 1 
																											)
											AND					rc.PaymentRangeID IN (
																													SELECT  PaymentRangeID
																													FROM    CTE_PaymentRange 
																												)
											AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
																	COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) >= calculatedRange.StartDate
											AND					COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) <= calculatedRange.FinishDate
											AND

			-- 0 meaning no Contact, so we aren't interested in contacting them (JUT 8801)
																	rc.ContactTypeID <> 0
											AND					rc.ContactTypeID <> 4
											AND					Locks.RetentionCaseID IS NULL
											AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer = 0
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber not in (SELECT DCSNumber FROM dbo.vwIsolated) 		
						  GROUP BY		rc.PaymentTypeID,
																	rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 2. Work out which SMS/Email _have_ had an Email or SMS sent (or Email&SMS for that matter)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( SELECT		PaymentTypeID,
															ContactTypeID,
															SUM(CASE WHEN ECommID IS NOT NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
											 THEN 1
										ELSE 0
								  END) Completed
										FROM      ( 
																SELECT			rc.PaymentTypeID,
																						rc.ContactTypeID,
																						ec.ECommID
																FROM				dbo.RetentionCases rc
																INNER JOIN	vwCurrentPaymentRange cpr 
																			ON		rc.PaymentRangeID = cpr.PaymentRangeID
																LEFT JOIN		dbo.EComms ec 
																			ON		rc.RetentionCaseID = ec.RetentionCaseID
																LEFT JOIN		dbo.ECommStates ecs 
																			ON		ecs.ECommStateID = ec.ECommStateID
																WHERE				rc.ContactTypeID <> 4 /*Exc Home Telephone as they will always fail on the SMS/Email lookup*/
									AND					ecs.[Name] = 'MsgSent'
																-- Add the reduced payer and first month filter in here for Phase 2
																AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer = 0
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber not in (SELECT DCSNumber FROM dbo.vwIsolated) 
											AND					((rc.BatchPriority IS NULL) OR (rc.BatchPriority = @PriorityType))			
																
															) ContactStatus
					  GROUP BY		PaymentTypeID,
															ContactTypeID
					) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 3. Work out which cases have had completed telephone calls against them 
		--    (note we're just looking at RetentionCase.DirectContactID and linking this to DirectContactOutcomes to exclude Sys.PaidByRefresh - JUT12887 CR Phase 2 - LI)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( 
										SELECT			RC.PaymentTypeID,
																RC.ContactTypeID,
																Completed = COUNT(*)
										FROM				dbo.RetentionCases rc
										INNER JOIN	vwCurrentPaymentRange cpr 
														ON	rc.PaymentRangeID = cpr.PaymentRangeID
										INNER JOIN	DirectContacts DC
													ON		RC.DirectContactID = DC.DirectContactID
										INNER JOIN	DirectContactOutcomes DCO
													ON		DC.DirectContactOutcomeID = DCO.DirectContactOutcomeID
													AND		DCO.[Name] <> 'Sys.PaidByRefresh'  -- Don't want to include system closed cases 
										WHERE				rc.ContactTypeID = 4
										AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer = 0
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber not in (SELECT DCSNumber FROM dbo.vwIsolated) 	
										GROUP BY		RC.PaymentTypeID,
																RC.ContactTypeID
									) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID;
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 4. Work out which cases have had outstanding telephone calls against them  
		--    (note we're just looking at RetentionCase.DirectContactID here rather than linked across to DirectContactOutcomes.CompletedCase)
			WITH    CTE_PaymentRange
					  AS ( SELECT			ptsd.PaymentTypeID,
																	ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
																	CASE WHEN @CurrentTime < ptsd.StartDate
																						AND ptsd.StartDate < pr.CutOffDate
																			 THEN ptsd.StartDate		--either not valid or cut off date is valid
																			 ELSE pr.StartDate
																	END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
																	CASE WHEN @CurrentTime < pr.CutOffDate
																			 THEN @CurrentTime
																			 ELSE pr.FinishDate
																	END FinishDate
						   FROM				dbo.PaymentTypeStartDates ptsd
						   INNER JOIN dbo.PaymentRanges pr 
															ON	pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE			@CurrentTime >= pr.StartDate
																	AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( 
											SELECT			rc.PaymentTypeID,
																	rc.ContactTypeID,
																	SUM(CASE WHEN rc.DirectContactID IS NULL
											 THEN 1
											 ELSE 0
									  END) Outstanding
						  FROM				dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
						  AND					rc.PaymentTypeID IN (
																											SELECT  PaymentTypeID
																											FROM    dbo.PaymentTypeInclusions pti
																											WHERE   pti.[Include] = 1 
																											)
						  AND					rc.PaymentRangeID IN (
																												SELECT  PaymentRangeID
																												FROM    CTE_PaymentRange 
																												)
						  AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
									COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) >= calculatedRange.StartDate
						  AND				COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) <= calculatedRange.FinishDate
						  AND				rc.ContactTypeID = 4
						  AND				Locks.RetentionCaseID IS NULL
			AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer = 0
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber not in (SELECT DCSNumber FROM dbo.vwIsolated)
											AND ((rc.NoContactNextContactTime < getdate()) or (rc.NoContactNextContactTime is null)) 	 	
						  GROUP BY  rc.PaymentTypeID,
									rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************	
		-- 3. Get the last batch info
		-- TODO for priority type
			UPDATE  #CR__GetCommunicationStats
			SET     LastBatch = batches.LastBatch
			FROM    ( SELECT    PaymentTypeID,
								ContactTypeID,
								MAX(Created) LastBatch
					  FROM      dbo.ECommBatches
									-- Add the reduced payer and first month filters in here for Phase 2
								--	WHERE			ReducedPayer = @ReducedPayer
								--	AND				FirstMonth = @FirstMonth
					  GROUP BY  PaymentTypeID,
								ContactTypeID
					) batches
			WHERE   batches.ContactTypeID = #CR__GetCommunicationStats.ContactTypeID
					AND batches.PaymentTypeID = #CR__GetCommunicationStats.PaymentTypeID
		-- ***************************************************************************************
		-- and return the results, flipped around into the format we want
			SELECT  *
			FROM    #CR__GetCommunicationStats
			ORDER BY PaymentTypeID,
					ContactTypeID

			DROP TABLE #CR__GetCommunicationStats
		END
		-- Reduced 1st Month
		If	@PriorityType = 6
		BEGIN
		-- ***************************************************************************************
		-- 1. Work out which SMS/Email have not had an Email or SMS sent (or Email&SMS for that matter)
			WITH CTE_PaymentRange
					  AS ( SELECT   ptsd.PaymentTypeID,
									ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
									CASE WHEN @CurrentTime < ptsd.StartDate
											  AND ptsd.StartDate < pr.CutOffDate
										 THEN ptsd.StartDate		--either not valid or cut off date is valid
										 ELSE pr.StartDate
									END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
									CASE WHEN @CurrentTime < pr.CutOffDate
										 THEN @CurrentTime
										 ELSE pr.FinishDate
									END FinishDate
						   FROM     dbo.PaymentTypeStartDates ptsd
									INNER JOIN dbo.PaymentRanges pr ON pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE    @CurrentTime >= pr.StartDate
									AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( SELECT	    rc.PaymentTypeID,
																  rc.ContactTypeID,
																	SUM(CASE WHEN ec.ECommID IS NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
																				THEN 1
																			 ELSE 0
																		  END) Outstanding
						  FROM			  dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.EComms ec 
														ON		rc.RetentionCaseID = ec.RetentionCaseID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
											AND					rc.PaymentTypeID IN (
																												SELECT  PaymentTypeID
																												FROM    dbo.PaymentTypeInclusions pti
																												WHERE   pti.[Include] = 1 
																											)
											AND					rc.PaymentRangeID IN (
																													SELECT  PaymentRangeID
																													FROM    CTE_PaymentRange 
																												)
											AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
																	COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) >= calculatedRange.StartDate
											AND					COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) <= calculatedRange.FinishDate
											AND

			-- 0 meaning no Contact, so we aren't interested in contacting them (JUT 8801)
																	rc.ContactTypeID <> 0
											AND					rc.ContactTypeID <> 4
											AND					Locks.RetentionCaseID IS NULL
											AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer = 1
											AND					rc.FirstMonth = 1		
						  GROUP BY		rc.PaymentTypeID,
																	rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 2. Work out which SMS/Email _have_ had an Email or SMS sent (or Email&SMS for that matter)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( SELECT		PaymentTypeID,
															ContactTypeID,
															SUM(CASE WHEN ECommID IS NOT NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
											 THEN 1
										ELSE 0
								  END) Completed
										FROM      ( 
																SELECT			rc.PaymentTypeID,
																						rc.ContactTypeID,
																						ec.ECommID
																FROM				dbo.RetentionCases rc
																INNER JOIN	vwCurrentPaymentRange cpr 
																			ON		rc.PaymentRangeID = cpr.PaymentRangeID
																LEFT JOIN		dbo.EComms ec 
																			ON		rc.RetentionCaseID = ec.RetentionCaseID
																LEFT JOIN		dbo.ECommStates ecs 
																			ON		ecs.ECommStateID = ec.ECommStateID
																WHERE				rc.ContactTypeID <> 4 /*Exc Home Telephone as they will always fail on the SMS/Email lookup*/
									AND					ecs.[Name] = 'MsgSent'
																-- Add the reduced payer and first month filter in here for Phase 2
																AND					rc.ReducedPayer = 1
																AND					rc.FirstMonth = 1
																AND					((rc.BatchPriority IS NULL) OR (rc.BatchPriority = @PriorityType))	
																
																
															) ContactStatus
					  GROUP BY		PaymentTypeID,
															ContactTypeID
					) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 3. Work out which cases have had completed telephone calls against them 
		--    (note we're just looking at RetentionCase.DirectContactID and linking this to DirectContactOutcomes to exclude Sys.PaidByRefresh - JUT12887 CR Phase 2 - LI)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( 
										SELECT			RC.PaymentTypeID,
																RC.ContactTypeID,
																Completed = COUNT(*)
										FROM				dbo.RetentionCases rc
										INNER JOIN	vwCurrentPaymentRange cpr 
														ON	rc.PaymentRangeID = cpr.PaymentRangeID
										INNER JOIN	DirectContacts DC
													ON		RC.DirectContactID = DC.DirectContactID
										INNER JOIN	DirectContactOutcomes DCO
													ON		DC.DirectContactOutcomeID = DCO.DirectContactOutcomeID
													AND		DCO.[Name] <> 'Sys.PaidByRefresh'  -- Don't want to include system closed cases 
										WHERE				rc.ContactTypeID = 4
										-- Add the reduced payer and first month filter in here for Phase 2
										AND					rc.ReducedPayer = 1
										AND					rc.FirstMonth = 1
										
										GROUP BY		RC.PaymentTypeID,
																RC.ContactTypeID
									) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID;
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 4. Work out which cases have had outstanding telephone calls against them  
		--    (note we're just looking at RetentionCase.DirectContactID here rather than linked across to DirectContactOutcomes.CompletedCase)
			WITH    CTE_PaymentRange
					  AS ( SELECT			ptsd.PaymentTypeID,
																	ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
																	CASE WHEN @CurrentTime < ptsd.StartDate
																						AND ptsd.StartDate < pr.CutOffDate
																			 THEN ptsd.StartDate		--either not valid or cut off date is valid
																			 ELSE pr.StartDate
																	END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
																	CASE WHEN @CurrentTime < pr.CutOffDate
																			 THEN @CurrentTime
																			 ELSE pr.FinishDate
																	END FinishDate
						   FROM				dbo.PaymentTypeStartDates ptsd
						   INNER JOIN dbo.PaymentRanges pr 
															ON	pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE			@CurrentTime >= pr.StartDate
																	AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( 
											SELECT			rc.PaymentTypeID,
																	rc.ContactTypeID,
																	SUM(CASE WHEN rc.DirectContactID IS NULL
											 THEN 1
											 ELSE 0
									  END) Outstanding
						  FROM				dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
						  AND					rc.PaymentTypeID IN (
																											SELECT  PaymentTypeID
																											FROM    dbo.PaymentTypeInclusions pti
																											WHERE   pti.[Include] = 1 
																											)
						  AND					rc.PaymentRangeID IN (
																												SELECT  PaymentRangeID
																												FROM    CTE_PaymentRange 
																												)
						  AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
									COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) >= calculatedRange.StartDate
						  AND				COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) <= calculatedRange.FinishDate
						  AND				rc.ContactTypeID = 4
						  AND				Locks.RetentionCaseID IS NULL
			-- Add the reduced payer and first month filters in here for Phase 2
											AND					rc.ReducedPayer = 1
											AND					rc.FirstMonth = 1
											AND ((rc.NoContactNextContactTime < getdate()) or (rc.NoContactNextContactTime is null)) 	
						  GROUP BY  rc.PaymentTypeID,
									rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************	
		-- 3. Get the last batch info
		-- TODO for priority type
			UPDATE  #CR__GetCommunicationStats
			SET     LastBatch = batches.LastBatch
			FROM    ( SELECT    PaymentTypeID,
								ContactTypeID,
								MAX(Created) LastBatch
					  FROM      dbo.ECommBatches
									-- Add the reduced payer and first month filters in here for Phase 2
									--WHERE			ReducedPayer = @ReducedPayer
									--AND				FirstMonth = @FirstMonth
					  GROUP BY  PaymentTypeID,
								ContactTypeID
					) batches
			WHERE   batches.ContactTypeID = #CR__GetCommunicationStats.ContactTypeID
					AND batches.PaymentTypeID = #CR__GetCommunicationStats.PaymentTypeID
		-- ***************************************************************************************
		-- and return the results, flipped around into the format we want
			SELECT  *
			FROM    #CR__GetCommunicationStats
			ORDER BY PaymentTypeID,
					ContactTypeID

			DROP TABLE #CR__GetCommunicationStats
		END
		-- 1st Reduced in 12
		If	@PriorityType = 7
		BEGIN
			--Reduced
		   -- ***************************************************************************************
		-- 1. Work out which SMS/Email have not had an Email or SMS sent (or Email&SMS for that matter)
			WITH CTE_PaymentRange
					  AS ( SELECT   ptsd.PaymentTypeID,
									ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
									CASE WHEN @CurrentTime < ptsd.StartDate
											  AND ptsd.StartDate < pr.CutOffDate
										 THEN ptsd.StartDate		--either not valid or cut off date is valid
										 ELSE pr.StartDate
									END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
									CASE WHEN @CurrentTime < pr.CutOffDate
										 THEN @CurrentTime
										 ELSE pr.FinishDate
									END FinishDate
						   FROM     dbo.PaymentTypeStartDates ptsd
									INNER JOIN dbo.PaymentRanges pr ON pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE    @CurrentTime >= pr.StartDate
									AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( SELECT	    rc.PaymentTypeID,
																  rc.ContactTypeID,
																	SUM(CASE WHEN ec.ECommID IS NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
																				THEN 1
																			 ELSE 0
																		  END) Outstanding
						  FROM			  dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.EComms ec 
														ON		rc.RetentionCaseID = ec.RetentionCaseID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
											AND					rc.PaymentTypeID IN (
																												SELECT  PaymentTypeID
																												FROM    dbo.PaymentTypeInclusions pti
																												WHERE   pti.[Include] = 1 
																											)
											AND					rc.PaymentRangeID IN (
																													SELECT  PaymentRangeID
																													FROM    CTE_PaymentRange 
																												)
											AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
																	COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) >= calculatedRange.StartDate
											AND					COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) <= calculatedRange.FinishDate
											AND

			-- 0 meaning no Contact, so we aren't interested in contacting them (JUT 8801)
																	rc.ContactTypeID <> 0
											AND					rc.ContactTypeID <> 4
											AND					Locks.RetentionCaseID IS NULL
											AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer = 1
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber not in (SELECT DCSNumber FROM dbo.vwReduced) 		
						  GROUP BY		rc.PaymentTypeID,
																	rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 2. Work out which SMS/Email _have_ had an Email or SMS sent (or Email&SMS for that matter)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( SELECT		PaymentTypeID,
															ContactTypeID,
															SUM(CASE WHEN ECommID IS NOT NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
											 THEN 1
										ELSE 0
								  END) Completed
										FROM      ( 
																SELECT			rc.PaymentTypeID,
																						rc.ContactTypeID,
																						ec.ECommID
																FROM				dbo.RetentionCases rc
																INNER JOIN	vwCurrentPaymentRange cpr 
																			ON		rc.PaymentRangeID = cpr.PaymentRangeID
																LEFT JOIN		dbo.EComms ec 
																			ON		rc.RetentionCaseID = ec.RetentionCaseID
																LEFT JOIN		dbo.ECommStates ecs 
																			ON		ecs.ECommStateID = ec.ECommStateID
																WHERE				rc.ContactTypeID <> 4 /*Exc Home Telephone as they will always fail on the SMS/Email lookup*/
									AND					ecs.[Name] = 'MsgSent'
																-- Add the reduced payer and first month filter in here for Phase 2
																AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer = 1
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber not in (SELECT DCSNumber FROM dbo.vwReduced)
											AND					((rc.BatchPriority IS NULL) OR (rc.BatchPriority = @PriorityType))	 		
																
															) ContactStatus
					  GROUP BY		PaymentTypeID,
															ContactTypeID
					) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 3. Work out which cases have had completed telephone calls against them 
		--    (note we're just looking at RetentionCase.DirectContactID and linking this to DirectContactOutcomes to exclude Sys.PaidByRefresh - JUT12887 CR Phase 2 - LI)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( 
										SELECT			RC.PaymentTypeID,
																RC.ContactTypeID,
																Completed = COUNT(*)
										FROM				dbo.RetentionCases rc
										INNER JOIN	vwCurrentPaymentRange cpr 
														ON	rc.PaymentRangeID = cpr.PaymentRangeID
										INNER JOIN	DirectContacts DC
													ON		RC.DirectContactID = DC.DirectContactID
										INNER JOIN	DirectContactOutcomes DCO
													ON		DC.DirectContactOutcomeID = DCO.DirectContactOutcomeID
													AND		DCO.[Name] <> 'Sys.PaidByRefresh'  -- Don't want to include system closed cases 
										WHERE				rc.ContactTypeID = 4
										AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer = 1
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber not in (SELECT DCSNumber FROM dbo.vwReduced) 	
										GROUP BY		RC.PaymentTypeID,
																RC.ContactTypeID
									) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID;
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 4. Work out which cases have had outstanding telephone calls against them  
		--    (note we're just looking at RetentionCase.DirectContactID here rather than linked across to DirectContactOutcomes.CompletedCase)
			WITH    CTE_PaymentRange
					  AS ( SELECT			ptsd.PaymentTypeID,
																	ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
																	CASE WHEN @CurrentTime < ptsd.StartDate
																						AND ptsd.StartDate < pr.CutOffDate
																			 THEN ptsd.StartDate		--either not valid or cut off date is valid
																			 ELSE pr.StartDate
																	END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
																	CASE WHEN @CurrentTime < pr.CutOffDate
																			 THEN @CurrentTime
																			 ELSE pr.FinishDate
																	END FinishDate
						   FROM				dbo.PaymentTypeStartDates ptsd
						   INNER JOIN dbo.PaymentRanges pr 
															ON	pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE			@CurrentTime >= pr.StartDate
																	AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( 
											SELECT			rc.PaymentTypeID,
																	rc.ContactTypeID,
																	SUM(CASE WHEN rc.DirectContactID IS NULL
											 THEN 1
											 ELSE 0
									  END) Outstanding
						  FROM				dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
						  AND					rc.PaymentTypeID IN (
																											SELECT  PaymentTypeID
																											FROM    dbo.PaymentTypeInclusions pti
																											WHERE   pti.[Include] = 1 
																											)
						  AND					rc.PaymentRangeID IN (
																												SELECT  PaymentRangeID
																												FROM    CTE_PaymentRange 
																												)
						  AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
									COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) >= calculatedRange.StartDate
						  AND				COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) <= calculatedRange.FinishDate
						  AND				rc.ContactTypeID = 4
						  AND				Locks.RetentionCaseID IS NULL
			AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer = 1
											AND					rc.FirstMonth = 0
											AND					rc.DCSNumber not in (SELECT DCSNumber FROM dbo.vwReduced) 
											AND ((rc.NoContactNextContactTime < getdate()) or (rc.NoContactNextContactTime is null)) 		
						  GROUP BY  rc.PaymentTypeID,
									rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************	
		-- 3. Get the last batch info
		-- TODO for priority type
			UPDATE  #CR__GetCommunicationStats
			SET     LastBatch = batches.LastBatch
			FROM    ( SELECT    PaymentTypeID,
								ContactTypeID,
								MAX(Created) LastBatch
					  FROM      dbo.ECommBatches
									-- Add the reduced payer and first month filters in here for Phase 2
								--	WHERE			ReducedPayer = @ReducedPayer
								--	AND				FirstMonth = @FirstMonth
					  GROUP BY  PaymentTypeID,
								ContactTypeID
					) batches
			WHERE   batches.ContactTypeID = #CR__GetCommunicationStats.ContactTypeID
					AND batches.PaymentTypeID = #CR__GetCommunicationStats.PaymentTypeID
		-- ***************************************************************************************
		-- and return the results, flipped around into the format we want
			SELECT  *
			FROM    #CR__GetCommunicationStats
			ORDER BY PaymentTypeID,
					ContactTypeID

			DROP TABLE #CR__GetCommunicationStats
		END
		If	@PriorityType = 8
		BEGIN
			--ALL
		   -- ***************************************************************************************
		-- 1. Work out which SMS/Email have not had an Email or SMS sent (or Email&SMS for that matter)
			WITH CTE_PaymentRange
					  AS ( SELECT   ptsd.PaymentTypeID,
									ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
									CASE WHEN @CurrentTime < ptsd.StartDate
											  AND ptsd.StartDate < pr.CutOffDate
										 THEN ptsd.StartDate		--either not valid or cut off date is valid
										 ELSE pr.StartDate
									END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
									CASE WHEN @CurrentTime < pr.CutOffDate
										 THEN @CurrentTime
										 ELSE pr.FinishDate
									END FinishDate
						   FROM     dbo.PaymentTypeStartDates ptsd
									INNER JOIN dbo.PaymentRanges pr ON pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE    @CurrentTime >= pr.StartDate
									AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( SELECT	    rc.PaymentTypeID,
																  rc.ContactTypeID,
																	SUM(CASE WHEN ec.ECommID IS NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
																				THEN 1
																			 ELSE 0
																		  END) Outstanding
						  FROM			  dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.EComms ec 
														ON		rc.RetentionCaseID = ec.RetentionCaseID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
											AND					rc.PaymentTypeID IN (
																												SELECT  PaymentTypeID
																												FROM    dbo.PaymentTypeInclusions pti
																												WHERE   pti.[Include] = 1 
																											)
											AND					rc.PaymentRangeID IN (
																													SELECT  PaymentRangeID
																													FROM    CTE_PaymentRange 
																												)
											AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
																	COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) >= calculatedRange.StartDate
											AND					COALESCE(rc.ScheduledPaymentDate,
																					 calculatedRange.StartDate) <= calculatedRange.FinishDate
											AND

			-- 0 meaning no Contact, so we aren't interested in contacting them (JUT 8801)
																	rc.ContactTypeID <> 0
											AND					rc.ContactTypeID <> 4
											AND					Locks.RetentionCaseID IS NULL
											AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer in (0,1)
											AND					rc.FirstMonth in (0,1)
											--AND					rc.DCSNumber not in (SELECT DCSNumber FROM dbo.vwReduced) 		
						  GROUP BY		rc.PaymentTypeID,
																	rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 2. Work out which SMS/Email _have_ had an Email or SMS sent (or Email&SMS for that matter)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( SELECT		PaymentTypeID,
															ContactTypeID,
															SUM(CASE WHEN ECommID IS NOT NULL  /*SMS/Email not sent*/ --and HasBeenCalled = 0 /*No calls to client*/
											 THEN 1
										ELSE 0
								  END) Completed
										FROM      ( 
																SELECT			rc.PaymentTypeID,
																						rc.ContactTypeID,
																						ec.ECommID
																FROM				dbo.RetentionCases rc
																INNER JOIN	vwCurrentPaymentRange cpr 
																			ON		rc.PaymentRangeID = cpr.PaymentRangeID
																LEFT JOIN		dbo.EComms ec 
																			ON		rc.RetentionCaseID = ec.RetentionCaseID
																LEFT JOIN		dbo.ECommStates ecs 
																			ON		ecs.ECommStateID = ec.ECommStateID
																WHERE				rc.ContactTypeID <> 4 /*Exc Home Telephone as they will always fail on the SMS/Email lookup*/
									AND					ecs.[Name] = 'MsgSent'
																-- Add the reduced payer and first month filter in here for Phase 2
																AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer in (1,0)
											AND					rc.FirstMonth in (0,1)
											AND					((rc.BatchPriority IS NULL) OR (rc.BatchPriority = @PriorityType))	
											--AND					rc.DCSNumber not in (SELECT DCSNumber FROM dbo.vwReduced) 		
																
															) ContactStatus
					  GROUP BY		PaymentTypeID,
															ContactTypeID
					) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 3. Work out which cases have had completed telephone calls against them 
		--    (note we're just looking at RetentionCase.DirectContactID and linking this to DirectContactOutcomes to exclude Sys.PaidByRefresh - JUT12887 CR Phase 2 - LI)
			UPDATE		#CR__GetCommunicationStats
			SET				NumCompleted = ContactStatusTotals.Completed
			FROM			( 
										SELECT			RC.PaymentTypeID,
																RC.ContactTypeID,
																Completed = COUNT(*)
										FROM				dbo.RetentionCases rc
										INNER JOIN	vwCurrentPaymentRange cpr 
														ON	rc.PaymentRangeID = cpr.PaymentRangeID
										INNER JOIN	DirectContacts DC
													ON		RC.DirectContactID = DC.DirectContactID
										INNER JOIN	DirectContactOutcomes DCO
													ON		DC.DirectContactOutcomeID = DCO.DirectContactOutcomeID
													AND		DCO.[Name] <> 'Sys.PaidByRefresh'  -- Don't want to include system closed cases 
										WHERE				rc.ContactTypeID = 4
										AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer in (0,1)
											AND					rc.FirstMonth in (0,1)
										--	AND					rc.DCSNumber not in (SELECT DCSNumber FROM dbo.vwReduced) 	
										GROUP BY		RC.PaymentTypeID,
																RC.ContactTypeID
									) ContactStatusTotals
			WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
					AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID;
		-- ***************************************************************************************
		-- ***************************************************************************************
		-- 4. Work out which cases have had outstanding telephone calls against them  
		--    (note we're just looking at RetentionCase.DirectContactID here rather than linked across to DirectContactOutcomes.CompletedCase)
			WITH    CTE_PaymentRange
					  AS ( SELECT			ptsd.PaymentTypeID,
																	ptsd.PaymentRangeID,
			
			-- Ensure we only return the PaymentType start date when we are before the start date and it
			-- is not superceded by the cut off date.
																	CASE WHEN @CurrentTime < ptsd.StartDate
																						AND ptsd.StartDate < pr.CutOffDate
																			 THEN ptsd.StartDate		--either not valid or cut off date is valid
																			 ELSE pr.StartDate
																	END StartDate,

			-- When we hit the cut off date, give me the full range.  Otherwise just until NOW
																	CASE WHEN @CurrentTime < pr.CutOffDate
																			 THEN @CurrentTime
																			 ELSE pr.FinishDate
																	END FinishDate
						   FROM				dbo.PaymentTypeStartDates ptsd
						   INNER JOIN dbo.PaymentRanges pr 
															ON	pr.PaymentRangeID = ptsd.PaymentRangeID
						   WHERE			@CurrentTime >= pr.StartDate
																	AND @CurrentTime <= pr.FinishDate
						 )
				UPDATE  #CR__GetCommunicationStats
				SET     NumOutstanding = ContactStatusTotals.Outstanding
				FROM    ( 
											SELECT			rc.PaymentTypeID,
																	rc.ContactTypeID,
																	SUM(CASE WHEN rc.DirectContactID IS NULL
											 THEN 1
											 ELSE 0
									  END) Outstanding
						  FROM				dbo.RetentionCases rc
						  INNER JOIN	CTE_PaymentRange calculatedRange 
														ON		rc.PaymentTypeID = calculatedRange.PaymentTypeID
						  LEFT JOIN		dbo.Locks 
														ON		rc.RetentionCaseID = Locks.RetentionCaseID
						  WHERE				-- Ignore any cases that have been completed (remember DirectContactID being null means we've solved them)
																	rc.DirectContactID IS NULL
						  AND					rc.PaymentTypeID IN (
																											SELECT  PaymentTypeID
																											FROM    dbo.PaymentTypeInclusions pti
																											WHERE   pti.[Include] = 1 
																											)
						  AND					rc.PaymentRangeID IN (
																												SELECT  PaymentRangeID
																												FROM    CTE_PaymentRange 
																												)
						  AND
			
			-- DD Unpaid dates will be null, so default those to the start of the range we're working with
			-- so them come in at the earliest opportunity
									COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) >= calculatedRange.StartDate
						  AND				COALESCE(rc.ScheduledPaymentDate,
											 calculatedRange.StartDate) <= calculatedRange.FinishDate
						  AND				rc.ContactTypeID = 4
						  AND				Locks.RetentionCaseID IS NULL
			AND

			-- Add the reduced payer and first month filter in here for Phase 2
																	rc.ReducedPayer in (0,1)
											AND					rc.FirstMonth in (0,1)
											AND ((rc.NoContactNextContactTime < getdate()) or (rc.NoContactNextContactTime is null)) 		
						  GROUP BY  rc.PaymentTypeID,
									rc.ContactTypeID
						) ContactStatusTotals
				WHERE   #CR__GetCommunicationStats.PaymentTypeID = ContactStatusTotals.PaymentTypeID
						AND #CR__GetCommunicationStats.ContactTypeID = ContactStatusTotals.ContactTypeID
		-- ***************************************************************************************	
		-- 3. Get the last batch info
		-- TODO for priority type
			UPDATE  #CR__GetCommunicationStats
			SET     LastBatch = batches.LastBatch
			FROM    ( SELECT    PaymentTypeID,
								ContactTypeID,
								MAX(Created) LastBatch
					  FROM      dbo.ECommBatches
									-- Add the reduced payer and first month filters in here for Phase 2
								--	WHERE			ReducedPayer = @ReducedPayer
								--	AND				FirstMonth = @FirstMonth
					  GROUP BY  PaymentTypeID,
								ContactTypeID
					) batches
			WHERE   batches.ContactTypeID = #CR__GetCommunicationStats.ContactTypeID
					AND batches.PaymentTypeID = #CR__GetCommunicationStats.PaymentTypeID
		-- ***************************************************************************************
		-- and return the results, flipped around into the format we want
			SELECT  *
			FROM    #CR__GetCommunicationStats
			ORDER BY PaymentTypeID,
					ContactTypeID

			DROP TABLE #CR__GetCommunicationStats
		END
	
	END
					
END
GO

USE [ClientRetention]
GO

/****** Object:  UserDefinedFunction [dbo].[GetCurrentTime]    Script Date: 02/08/2012 16:14:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER function [dbo].[GetCurrentTime]()
returns datetime
begin

	-- IN LIVE THIS SHOULD _ALWAYS_ BE CURRENT_TIMESTAMP
--	return '10-Apr-09' 
	return $(FreezeDate)

end

GO

USE [ClientRetention]
GO

/****** Object:  View [dbo].[vwCurrentCases]    Script Date: 02/08/2012 16:18:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [dbo].[vwCurrentCases] --WITH SCHEMABINDING

AS

-- Note: The top (99.999999) is a bodge which forces 2005 to return an orderby indexed view
	-- There are hotfixes available for this, see http://cf-bill.blogspot.com/2007/01/sql-server-order-view.html
	-- for further details
	-- ANYTHING that uses this view MUST use the order by filters illustrated at the bottom of the view definition
	--
	-- Also note that for a:
	--    "Get Next" you want to filter on TotalComms > 0
	--    "Send Next" you want to filter on TotalComms = 0

	-- Alias for working out if a) Number of calls Client has had, and b) when the latest call was (well the ID of it)
	-- Replaced calls to dbo_GetCurrentTime() with CURRENT_TIMESTAMP
-- CHG33128 Add additional column to deal with 'No Contact' Clients
-- CHG31815 - Lee Insley - 14/01/2010
	-- Modified CTE_CallHistory so TotalCalls exludes System messages (which are not contacts with the client)
	-- (Sys.PaidByRefresh, Sys.DisbursementStarted, Sys.UnPaidByRefresh)

-- Phase 2 - Lee Insley - 26/07/2010
	-- Add the new fields ReducedPayer, FirstMonth and PercentagePaid to the output of the view

	WITH CTE_CallHistory AS
		(
			SELECT			RetentionCaseID, 
									LastCallID				= MAX(DirectContactID), 
									TotalCalls				= COUNT(DirectContactID)	
			FROM				dbo.DirectContacts dc
			INNER JOIN	dbo.DirectContactOutcomes dco
						ON		dc.DirectContactOutcomeID = dco.DirectContactOutcomeID
						AND		dco.ContactDirectionID <> 3		-- CHG31815 - This excludes System messages
			GROUP BY		RetentionCaseID
		), 
	
	-- Alias for retrieving any locks in place
	CTE_Locks AS
		(
			SELECT			RetentionCaseID
			FROM				dbo.vwUserLocks
		), 

	-- Alias for getting all PaymentTypes that are currently excluded
	CTE_PTI AS 
		(
			SELECT			PaymentTypeID 
			FROM				dbo.PaymentTypeInclusions pti 
			WHERE				pti.[Include] = 1
		),        

	-- Alias for working out if a) Client has had any ecomms sent, and b) how many they've had
	CTE_CommHistory AS      
		(
			SELECT            
									ec.RetentionCaseID,
									MAX(ec.ECommID) LastCommID,
									COALESCE(COUNT(ec.ECommID),0) TotalComms
			FROM
									dbo.EComms ec
			LEFT JOIN 
									dbo.ECommBatches ecb 
						ON
									ec.ECommBatchID = ecb.ECommBatchID
			INNER JOIN
									dbo.ECommStates ecs
						ON
									ec.ECommStateID = ecs.ECommStateID
						AND		ecs.[Name] NOT IN ('StateChange', 'NowPaid')
			GROUP BY
									RetentionCaseID
		),

	-- Alias to discover which PaymentTypes are within the current period range
	CTE_PaymentRange AS    
	(
		SELECT      
									ptsd.PaymentTypeID,
									ptsd.PaymentRangeID,
			
									-- Ensure we only return the PaymentType start date WHEN we are before the start date and it
									-- is not superceded by the cut off date.
									CASE 
										WHEN $(FreezeDate) < ptsd.StartDate AND ptsd.StartDate < pr.CutOffDate 
											THEN ptsd.StartDate		--either not valid or cut off date is valid
										ELSE pr.StartDate 
									END AS StartDate,

									-- WHEN we hit the cut off date, give me the full range.  Otherwise just until NOW
									CASE
										WHEN $(FreezeDate) < pr.CutOffDate THEN $(FreezeDate)
										ELSE pr.FinishDate
									END FinishDate
		FROM
									dbo.PaymentTypeStartDates ptsd
		INNER JOIN 
									dbo.PaymentRanges pr 
						ON
									pr.PaymentRangeID = ptsd.PaymentRangeID
		WHERE
									$(FreezeDate) >= pr.StartDate
		AND						$(FreezeDate) <= pr.FinishDate 
	),


	CTE_DDFailureCodes AS
		(
			SELECT
									FailureReasonCodeID,    
									Priority
			FROM
									DDFailureCodes
		),


	-- Alias for discovering which CASEs are valid to contact
	CTE_RetentionCases AS 
		(
			SELECT      
									calculatedRange.StartDate AS CalcStartDate,
									calculatedRange.FinishDate AS CalcFinishDate,
									rc.RetentionCaseID,
									rc.PaymentRangeID,
									rc.PaymentTypeID,
									rc.DirectContactID,
									rc.ContactTypeID,
									rc.DCSNumber,
									-- Note use of GetDate() here is deliberate, don't change to CURRENT_TIMESTAMP!
									COALESCE(rc.NextContactTime, GETDATE() ) NextContactTime,	-- Note use of GetDate() here is deliberate, don't change to CURRENT_TIMESTAMP!
									rc.ScheduledPaymentDate,
									rc.FailureReasonCodeID,
									rc.ReducedPayer,
									rc.FirstMonth,
									rc.PercentagePaid,
									rc.NoContactNextContactTime
			FROM
									dbo.RetentionCases rc
			INNER JOIN 
									CTE_PaymentRange calculatedRange 
						ON
									rc.PaymentTypeID = calculatedRange.PaymentTypeID
			WHERE
									-- Ignore any CASEs that have been completed (remember DirectContactID being null means we've solved them)
									rc.DirectContactID IS NULL
			AND					rc.PaymentTypeID IN (SELECT PaymentTypeID FROM CTE_PTI)
			AND					rc.PaymentRangeID IN (SELECT PaymentRangeID from CTE_PaymentRange)
									
									-- DD Unpaid dates will be null, so default those to the start of the range we're working with
									-- so them come in at the earliest opportunity
			AND					coalesce(rc.ScheduledPaymentDate, calculatedRange.StartDate) >= calculatedRange.StartDate 
			AND					coalesce(rc.ScheduledPaymentDate, calculatedRange.StartDate) <= calculatedRange.FinishDate

									-- 0 meaning no Contact, so we aren't interested in contacting them (JUT 8801)
			AND					rc.ContactTypeID <> 0 
		)

	SELECT TOP (99.999999) PERCENT
								-- debug
								--	rc.CalcStartDate,
								--	rc.CalcFinishDate,
								-- debug
								rc.RetentionCaseID,
								rc.PaymentRangeID,
								rc.PaymentTypeID,
								rc.DirectContactID,
								rc.ContactTypeID,
								rc.DCSNumber,

								-- If there's no appoinment booked for the Client, we want to contact them now
								-- Note: use of GetDate() here is deliberate, don't change to CURRENT_TIMESTAMP!
								COALESCE(rc.NextContactTime, GETDATE()) AS NextContactTime,

								-- If the Client has had calls they go to the bottom of the list
								COALESCE(ch.TotalCalls, 0) AS TotalCalls,
								
								-- If the Client has had an email/SMS we don't sent them another one.
								COALESCE(comH.TotalComms, 0) AS TotalComms,
								
								MostRecentCall.ContactDate AS LastContactTime,

								-- DD Unpaids will have a null payment date, so default them to the start of the range so we can
								-- see them straight away
								COALESCE(rc.ScheduledPaymentDate, rc.CalcStartDate) AS ScheduledPaymentDate,
								
								fc.Priority,
								rc.ReducedPayer,
								rc.FirstMonth,
								rc.PercentagePaid,
								rc.NoContactNextContactTime

	FROM
								CTE_RetentionCases rc
	INNER JOIN
								CTE_DDFailureCodes fc
					ON
								fc.FailureReasonCodeID = rc.FailureReasonCodeID
	LEFT JOIN 
								CTE_CallHistory ch 
					ON
								rc.RetentionCaseID = ch.RetentionCaseID
	LEFT JOIN 
								dbo.DirectContacts MostRecentCall 
					ON
								ch.LastCallID = MostRecentCall.DirectContactID
	LEFT JOIN 
								CTE_CommHistory comH 
					ON
								rc.RetentionCaseID = comH.RetentionCaseID  
	LEFT JOIN
								CTE_Locks ul
								-- Remove any CASEs that are locked as they are being processed elsewhere in the system
					ON
								ul.RetentionCaseID = rc.RetentionCaseID
	WHERE
								ul.RetentionCaseID IS NULL
	

	-- debug
	--	where rc.DCSNumber = 174729
	-- debug
	GROUP BY 
								rc.CalcStartDate,
								rc.CalcFinishDate,
								rc.RetentionCaseID,
								ch.RetentionCaseID,
								ch.LastCallID,
								MostRecentCall.ContactDate,
								ch.TotalCalls,
								comH.TotalComms,
								rc.PaymentRangeID,
								rc.PaymentTypeID,
								rc.DirectContactID,
								rc.ContactTypeID,
								rc.NextContactTime,
								rc.DCSNumber,
								rc.ScheduledPaymentDate,
								fc.Priority,
								rc.ReducedPayer,
								rc.FirstMonth,
								rc.PercentagePaid,
								rc.NoContactNextContactTime

	ORDER BY
								-- make sure we get those we haven't contacted yet
								NextContactTime, 
								TotalCalls,
								fc.Priority,
								MostRecentCall.ContactDate,   -- alias = LastContactTime
								rc.RetentionCaseID            -- (this last one is really here to help testing ... can go afterwards)

GO

USE [ClientRetention]
GO

/****** Object:  View [dbo].[vwCurrentPaymentRange]    Script Date: 02/08/2012 16:24:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



	-- Replaced calls to dbo_GetCurrentTime() with CURRENT_TIMESTAMP

ALTER view [dbo].[vwCurrentPaymentRange] --WITH SCHEMABINDING
as
	select top 100 percent
		PaymentRangeID,
		MonthIndex,
		StartDate,
		FinishDate,
		UserID,
		ModifiedWhen,
		CutOffDate,
		PostDisbursementStartDate
	from
		dbo.PaymentRanges pr
	where
		$(FreezeDate) >= StartDate and
		$(FreezeDate) <= FinishDate 
	order by startdate

GO

