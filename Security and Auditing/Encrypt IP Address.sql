declare	@IPAddress varchar(15)
set @IPAddress = '209.190.71.67'

begin
	declare @p1 varchar(3)
	declare @p2 varchar(3)
	declare @p3 varchar(3)
	declare @p4 varchar(3)
	
	declare @dotInd int
	set @dotInd = CHARINDEX('.',@IPAddress)
	set @p1 = SUBSTRING(@IPAddress,1,@dotInd-1)
	set @IPAddress = SUBSTRING(@IPAddress,@dotInd+1,15)
	set @dotInd = CHARINDEX('.',@IPAddress)
	set @p2 = SUBSTRING(@IPAddress,1,@dotInd-1)
	set @IPAddress = SUBSTRING(@IPAddress,@dotInd+1,15)
	set @dotInd = CHARINDEX('.',@IPAddress)
	set @p3 = SUBSTRING(@IPAddress,1,@dotInd-1)
	set @p4 = SUBSTRING(@IPAddress,@dotInd+1,15)
	
	declare @p1Int int
	declare @p2Int int
	declare @p3Int int
	declare @p4Int int
	
	select
		@p1Int = CONVERT(int,@p1),
		@p2Int = CONVERT(int,@p2),
		@p3Int = CONVERT(int,@p3),
		@p4Int = CONVERT(int,@p4)
	
	declare @tot bigint
	set @tot = (CONVERT(bigint,@p1Int) * 256 * 256 * 256) + (@p2Int * 256 * 256) + (@p3Int * 256) + @p4Int
	
	if @tot < 2147483647
		select CONVERT(int,@tot)
	
	SELECT CONVERT(int,-2147483648 + (@tot - 2147483648))
end
go




