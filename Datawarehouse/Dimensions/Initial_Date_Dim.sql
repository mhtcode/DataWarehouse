CREATE OR ALTER PROCEDURE [DW].[Initial_Date_Dim]
AS
BEGIN
	TRUNCATE TABLE [DW].[DimDate];
	BULK INSERT [DW].[DimDate]
	FROM 'F:\UNI\Term8\DB2\Project\data-warehouse\Files\Date1.CSV'
	WITH 
	(
		FIELDTERMINATOR = ',',   
		ROWTERMINATOR = '\n',    
		FIRSTROW = 2            
	)
END

EXEC [DW].[Initial_Date_Dim]

TRUNCATE TABLE [DW].[DimDate];

select * from [DW].[DimDate]


-- چک کردن دسترسی
-- EXEC xp_fileexist 'C:\Users\Hkr\Desktop\1403-2\DB 2\Project\data-warehouse\Files\Date1.CSV';
