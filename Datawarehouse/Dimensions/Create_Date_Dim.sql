CREATE TABLE [DW].[DimDate] (
  [DateKey] date PRIMARY KEY,
  [FullDateAlternateKey] date,
  [PersianFullDateAlternateKey] nvarchar(12),
  [DayNumberOfWeek] int,
  [PersianDayNumberOfWeek] int,
  [EnglishDayNameOfWeek] nvarchar(255),
  [PersianDayNameOfWeek] nvarchar(255),
  [DayNumberOfMonth] int,
  [PersianDayNumberOfMonth] int,
  [DayNumberOfYear] int,
  [PersianDayNumberOfYear] int,
  [WeekNumberOfYear] int,
  [PersianWeekNumberOfYear] int,
  [EnglishMonthName] nvarchar(255),
  [PersianMonthName] nvarchar(255),
  [MonthNumberOfYear] int,
  [PersianMonthNumberOfYear] int,
  [CalendarQuarter] int,
  [PersianCalendarQuarter] int,
  [CalendarYear] int,
  [PersianCalendarYear] int,
  [CalendarSemester] int,
  [PersianCalendarSemester] int,
)
GO

CREATE NONCLUSTERED INDEX IX_DimDate_GregorianHierarchy
ON [DW].[DimDate] (CalendarYear, MonthNumberOfYear, DayNumberOfMonth);
GO

CREATE NONCLUSTERED INDEX IX_DimDate_PersianHierarchy
ON [DW].[DimDate] (PersianCalendarYear, PersianMonthNumberOfYear, PersianDayNumberOfMonth);
GO

CREATE NONCLUSTERED INDEX IX_DimDate_FullDateAlternateKey
ON [DW].[DimDate] (FullDateAlternateKey);
GO

DROP INDEX IF EXISTS IX_DimDate_GregorianHierarchy ON [DW].[DimDate];
GO

DROP INDEX IF EXISTS IX_DimDate_PersianHierarchy ON [DW].[DimDate];
GO

DROP INDEX IF EXISTS IX_DimDate_FullDateAlternateKey ON [DW].[DimDate];
GO