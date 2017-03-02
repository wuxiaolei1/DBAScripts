Declare @TableName varchar(256)
Declare @ColumnName varchar(256)
Declare @search varchar(256)

CREATE TABLE #Results (ColumnName nvarchar(370), ColumnValue nvarchar(500))

set @TableName = ''
set @search = '%road%'
/*
Character search Format '%@%'
Number search a leading 0 followed by a number ending in any string format '0[0-9]_%'
*/

WHILE @TableName IS NOT NULL
Begin
		set @TableName = (
		SELECT MIN(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME))
		FROM 	INFORMATION_SCHEMA.TABLES
		WHERE 		TABLE_TYPE = 'BASE TABLE'
		AND	QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) > @TableName
		)
	--Print @TableName
	SET @ColumnName = ''
	WHILE (@TableName IS NOT NULL) AND (@ColumnName IS NOT NULL)
	BEGIN
		SET @ColumnName = (
			SELECT MIN(QUOTENAME(COLUMN_NAME))
			FROM 	INFORMATION_SCHEMA.COLUMNS
			WHERE 		TABLE_SCHEMA	= PARSENAME(@TableName, 2)
			AND	TABLE_NAME	= PARSENAME(@TableName, 1)
			AND	QUOTENAME(COLUMN_NAME) > @ColumnName
			)
	--Print @ColumnName
	IF @ColumnName IS NOT NULL
			BEGIN
			INSERT INTO #Results
				EXEC
				( 'SELECT Top 1 ''' + @TableName + '.' + @ColumnName + ''', LEFT(' + @ColumnName + ', 500) 
					FROM ' + @TableName + ' (NOLOCK) ' +
					' WHERE ' + @ColumnName + ' LIKE '''+ @Search + ''''
				)		
			END
	End
End
select * from #Results

Drop Table #Results
