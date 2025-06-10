BULK INSERT [DW].[DateTimeDim]
FROM 'C:\path\to\your\data.txt'
WITH 
(
    FIELDTERMINATOR = ',',   -- جداکننده فیلدها (در اینجا کاما)
    ROWTERMINATOR = '\n',    -- جداکننده ردیف‌ها (در اینجا خط جدید)
    FIRSTROW = 1            -- اگر ردیف اول شامل نام ستون‌ها است، می‌توانید این مقدار را تغییر دهید
);