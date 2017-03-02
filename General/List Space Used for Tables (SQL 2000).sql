DECLARE	@TableID INT, @MaxTableID INT, @TableName varchar(100)

CREATE TABLE dbo.#TableNames
(
	TableID INT IDENTITY(1, 1),
    TableName varchar(100)
)

CREATE TABLE dbo.#Results
(
    TableName varchar(100),
    NumberOfRows varchar(100),
    ReservedSize varchar(100),
    DataSize varchar(100),
    IndexSize varchar(100),
    UnusedSize varchar(100)
)

INSERT	dbo.#TableNames
SELECT	[name] AS TableName
FROM	dbo.sysobjects
WHERE	OBJECTPROPERTY(id, N'IsUserTable') = 1

SELECT	@TableID = 1, @MaxTableID = MAX(TableID)
FROM	dbo.#TableNames

WHILE	@TableID <= @MaxTableID
BEGIN
		SELECT	@TableName = TableName
		FROM	dbo.#TableNames
		WHERE	TableID = @TableID

		INSERT	dbo.#Results
		EXEC	sp_spaceused @TableName

		SET	@TableID = @TableID + 1
END

SELECT	*
FROM	dbo.#Results

DROP TABLE	dbo.#TableNames
DROP TABLE	dbo.#Results
