CREATE TABLE [DW].[PersonPointTransactions_ACCFact] (
  [PersonKey] int,
  [LoyaltyTierKey] int,
  [TotalPointsEarned] decimal(18,2),
  [TotalPointsRedeemed] decimal(18,2),
  [NetPointChange] decimal(18,2),
  [TotalPointValueUSD] decimal(18,2),
  [TotalNumberOfTransactions] int,
  [TotalDistinctFlightsEarnedOn] int
)
GO