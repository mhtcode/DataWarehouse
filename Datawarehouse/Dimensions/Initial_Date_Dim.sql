CREATE OR ALTER PROCEDURE [DW].[Initial_Date_Dim]
AS
BEGIN
	TRUNCATE TABLE [DW].[DimDate];
	BULK INSERT [DW].[DimDate]
	FROM 'C:\Users\Hkr\Desktop\1403-2\DB 2\Project\data-warehouse\Files\Date2.CSV' --'D:\Uni\Current Semester\DB2\Project\data-warehouse\Files\Date1.CSV' --'F:\UNI\Term8\DB2\Project\data-warehouse\Files\Date1.CSV'
	WITH 
	(
		FIELDTERMINATOR = ',',   
		ROWTERMINATOR = '\n',    
		FIRSTROW = 2,
		CODEPAGE = '65001'            
	)
END
GO
