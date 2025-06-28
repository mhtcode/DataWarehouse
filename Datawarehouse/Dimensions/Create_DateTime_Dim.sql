CREATE TABLE [DW].[DimDateTime] (
  [DateTimeKey] datetime PRIMARY KEY,
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
  [Time] time,
  [Hour] int,
  [Minute] int
)
GO

CREATE NONCLUSTERED INDEX IX_DimDateTime_GregorianHierarchy
ON [DW].[DimDateTime] (CalendarYear, MonthNumberOfYear, DayNumberOfMonth);
GO

CREATE NONCLUSTERED INDEX IX_DimDateTime_PersianHierarchy
ON [DW].[DimDateTime] (PersianCalendarYear, PersianMonthNumberOfYear, PersianDayNumberOfMonth);
GO

CREATE NONCLUSTERED INDEX IX_DimDateTime_FullDateAlternateKey
ON [DW].[DimDateTime] (FullDateAlternateKey);
GO

CREATE NONCLUSTERED INDEX IX_DimDateTime_TimeHierarchy
ON [DW].[DimDateTime] (Hour, Minute);
GO
