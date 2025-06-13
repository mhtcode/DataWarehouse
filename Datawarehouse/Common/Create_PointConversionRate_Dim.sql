CREATE TABLE [DW].[DimPointConversionRate] (
  [ConversionRateKey] int PRIMARY KEY,
  [EffectiveFrom] datetime,
  [EffectiveTo] datetime,
  [Rate] decimal(18,6),
  [Currency] nvarchar(255),
  [IsCurrent] bit
)
GO
