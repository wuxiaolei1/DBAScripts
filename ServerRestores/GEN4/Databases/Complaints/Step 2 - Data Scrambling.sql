:r "\\ldsfileproapp01\Systems\Tech support shared data\SQL Server\DBA Scripts\ServerRestores\SHARED\CreateFunctions.sql"
:on error exit
SET NOCOUNT ON
PRINT 'Step 2 - Scramble Data - Complaints'

USE Complaints
GO

/* Decision made by the project team (Dave Lambert and Bob Collins that only the surname needs to be scrambled. 
Highlighted the fact that personal data could be stored in the case details field but Bob Collins decided that 
the data does not need to be scrambled. I have copied the email chain at the bottom of the script. */

DECLARE @DataScramble BIT
		, @Environment VARCHAR(30)
		, @DataRowCount INT
		, @DataScrambleName INT -- 1 = Yes Scramble Name

--SET DEFAULTS...
SET @DataScramble = 1
SET @Environment = $(Environment)
SET @DataRowCount = 0
SET @DataScrambleName = 1

--Read the specific settings if available...
SELECT	@DataScramble = EDV.DataScramble
		, @DataScrambleName = EDV.DataScrambleName
FROM EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE Environment = @Environment

SET @DataRowCount = @@Rowcount

-- Perform Updates
IF @DataScramble = 1
BEGIN
-- Scramble Client Names if required
		IF  @DataScrambleName = 1
		BEGIN
			BEGIN TRAN UpdateNames

			--TABLE: [Complainant].[Complainants]
			UPDATE [Complainant].[Complainants]
			SET	[Surname] = CASE WHEN Surname <> '' THEN [tempdb].[dbo].[FN_ScrambleName]([Surname],0) END;

			COMMIT TRAN UpdateNames
		END

		/*
		-- Remove Case details (they may contain contact information and no way or removing it
		UPDATE [Case].[Cases]
		SET Details = 'Complaint details have been removed intentionally';
		*/

	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)
	
END


/*
Bob has made the decision 

On 29 Jun 2015, at 10:38, Thomas Braham <Thomas.Braham@stepchange.org> wrote:
Yes please Dave, I feel uncomfortable if we already know that the users will be entering this information and not doing anything to ensure it doesn’t get scrambled in non-live. Who operationally has made the decision on scrambling, does Bob have an opinion on it?
 
Cheers
Tom
 

Thomas Braham
Senior Database Administrator
StepChange Debt Charity
60182

Dave Lambert
Project Manager
StepChange Debt Charity
60165
From: Dave Lambert 
Sent: 29 June 2015 10:31
To: Thomas Braham
Subject: RE: Complaints data scrambling for non-live
 
No, it doesn’t, and no we don’t.
 
I explained the situation (that users could use this field for anything, inc personal/contact details), and I have still been told that only names need to be scrambled. I can push back again if you feel uncomfortable.
 
Thanks
Dave
 

Dave Lambert
Project Manager
StepChange Debt Charity
60165
From: Thomas Braham 
Sent: 29 June 2015 10:30
To: Dave Lambert
Subject: RE: Complaints data scrambling for non-live
 
Thanks Dave. Does this mean that no users will enter any contact information in the Details section of the complaint? And if so do we any way to enforce this?
 
Thanks
Tom
 

Thomas Braham
Senior Database Administrator
StepChange Debt Charity
60182
From: Dave Lambert 
Sent: 29 June 2015 10:28
To: Thomas Braham
Subject: RE: Complaints data scrambling for non-live
 
Hi Tom,
 
It has been confirmed that we only need to scramble first name and surname (as you have already stated).
 
I will log this on the project.
 
Thanks
Dave
 

Dave Lambert
Project Manager
StepChange Debt Charity
60165
From: Thomas Braham 
Sent: 19 June 2015 14:23
To: Crystal Chapman-Smith
Cc: Dave Lambert; Chris Murphy; Ben Fieldsend
Subject: Complaints data scrambling for non-live
 
Hi Crystal,
 
As part of the automatic restore of the Complaints database we are required to scramble any client personal data. To achieve this we will scramble the following:
 
Complainant First Name ([Complainant].[Complainants].[Firstname])
Complainant Surname ([Complainant].[Complainants].[Surname])
 
As this database may store potentially sensitive information are there any other requirements either operationally or regulatory to scramble any further data in the non-live environments?
 
As no contact information is stored in the Complaints database there was talk of users entering contact information in the “Details of dissatisfaction/complaint” field which would mean there is no way of removing or scrambling this piece of data therefore we would need to remove all data from this field when it is restored into non live. Can you confirm that a) the “Details of dissatisfaction/complaint” field and therefore will need to scrambled/removed and b) if it needs to be scrambled/removed should the text be removed or replaced with a static string?
 
Thanks
Tom

Thomas Braham
Senior Database Administrator
StepChange Debt Charity
60182

*/