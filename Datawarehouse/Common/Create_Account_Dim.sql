CREATE TABLE [DW].[DimAccount] (
  [AccountKey] int PRIMARY KEY,
  [AccountNumber] nvarchar(255),
  [AccountType] nvarchar(255),
  [CreatedDate] datetime,
  [IsActive] bit
)
GO
