
/* --- 
SS 13/12/2010
Altered to be called from SQLCMD line
sqlcmd -S systems37\sql2005 -i "\\ldsfileproapp01\systems\Tech support shared data\SQL Server\ServerRestores\DMSPRODBA01\DMS\Step 3 - Update Application Settings .sql"

--- */
SET NOCOUNT ON
GO
SET ANSI_NULLS ON
GO
SET ANSI_WARNINGS ON
GO
Print 'Step 3 - Update Application Settings - CPF_BACS'

USE CPF_BACS
GO

	UPDATE dbo.EmailAddresses
	SET emailaddress = 'Environments@Stepchange.org', Internal = 1

DECLARE @Environment varchar(50) 
DECLARE @EMailAddress VARCHAR(255)
DECLARE @DataRowCount INT

--SET DEFAULTS...
SET @EMailAddress = 'thisisadummyemail@notstepchange.co.na' --'no-reply@stepchange.org'
--ALTERNATIVE FOR INTERNAL USE: 'Environments@stepchange.org'
SET @Environment = $(Environment)
SET @DataRowCount = 0

--Read the specific settings if available...
SELECT	@EMailAddress = EDV.EMail
FROM EnviroDataLinkedServer.DataScramble.dbo.EnviroDataValues EDV
WHERE Environment = @Environment

SET @DataRowCount = @@Rowcount

--Update Application Settings 

--27-6-2012 REPLACED 'E:\Live' with 'C:\Applications\CPF BACs\Pipelines'
--in Paramaters strings at request of Environment team

		UPDATE dbo.PipelineParameters
		SET
			Bound_String=CASE
				WHEN PipelineID=8 and ParameterID=2
					THEN @EMailAddress
				WHEN PipelineID=1 and ParameterID=3
					THEN 'C:\Applications\CPF BACs\Pipelines\CPF\BACS\DISB.txt'
				WHEN PipelineID=2 and ParameterID=3
					THEN 'C:\Applications\CPF BACs\Pipelines\CPF\BACS\FSC.txt'
				WHEN PipelineID=5 and ParameterID=6
					THEN 'C:\Applications\CPF BACs\Pipelines\CPF'
				WHEN PipelineID=6 and ParameterID=3
					THEN 'C:\Applications\CPF BACs\Pipelines\Drops and Non Payers\NonPayments{0:MMMyyyy}.pdf'
				WHEN PipelineID=7 and ParameterID=3
					THEN 'C:\Applications\CPF BACs\Pipelines\Drops and Non Payers\Drops{0:MMMyyyy}.pdf'
			END
		WHERE
		(PipelineID=8 and ParameterID=2) or
		(PipelineID=1 and ParameterID=3) or
		(PipelineID=2 and ParameterID=3) or
		(PipelineID=5 and ParameterID=6) or
		(PipelineID=6 and ParameterID=3) or
		(PipelineID=7 and ParameterID=3)

		UPDATE dbo.ExecutionParameters
		SET
			StringVal=CASE
				WHEN PipelineID=8 and ParameterID=2
					THEN @EMailAddress
				WHEN PipelineID=1 and ParameterID=3
					THEN 'C:\Applications\CPF BACs\Pipelines\CPF\BACS\DISB.txt'
				WHEN PipelineID=2 and ParameterID=3
					THEN 'C:\Applications\CPF BACs\Pipelines\CPF\BACS\FSC.txt'
				WHEN PipelineID=5 and ParameterID=6
					THEN 'C:\Applications\CPF BACs\Pipelines\CPF'
				WHEN PipelineID=6 and ParameterID=3
					THEN 'C:\Applications\CPF BACs\Pipelines\Drops and Non Payers\NonPayments{0:MMMyyyy}.pdf'
				WHEN PipelineID=7 and ParameterID=3
					THEN 'C:\Applications\CPF BACs\Pipelines\Drops and Non Payers\Drops{0:MMMyyyy}.pdf'
			END
		WHERE
		(PipelineID=8 and ParameterID=2) or
		(PipelineID=1 and ParameterID=3) or
		(PipelineID=2 and ParameterID=3) or
		(PipelineID=5 and ParameterID=6) or
		(PipelineID=6 and ParameterID=3) or
		(PipelineID=7 and ParameterID=3)
	
	-- Raise an error if no rows were selected from the Environment Data Values Table
	IF @DataRowCount = 0
	RAISERROR ('*** No Rows Selected from Data Table - Data Not Scrambled Correctly ***',16,1)