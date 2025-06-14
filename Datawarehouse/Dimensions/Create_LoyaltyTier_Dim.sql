CREATE TABLE [DW].[DimLoyaltyTier] (
  [LoyaltyTierKey] int PRIMARY KEY,
  [Name] nvarchar(255),
  [MinPoints] int,
  [Benefits] nvarchar(255),
  [EffectiveFrom] datetime,
  [EffectiveTo] datetime,
  [NameIsCurrent] bit
)
GO
