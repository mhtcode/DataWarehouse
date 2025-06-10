BULK INSERT [DW].[DateTimeDim]
FROM 'C:\Users\Hkr\Desktop\1403-2\DB 2\Project\data-warehouse\Files\Date.txt'
WITH 
(
    FIELDTERMINATOR = '\t',   
    ROWTERMINATOR = '\n',    
    FIRSTROW = 2            
);

select top 100 * 
from [DW].[DateTimeDim]

SELECT * 
FROM OPENROWSET(BULK 'C:\Users\Hkr\Desktop\1403-2\DB 2\Project\data-warehouse\Files\Date.txt', SINGLE_CLOB) AS DataFile