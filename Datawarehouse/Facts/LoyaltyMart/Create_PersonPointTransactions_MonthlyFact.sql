CREATE TABLE [DW].[PersonPointTransactions_MonthlyFact] (
  [MonthID] date,
  [PersonKey] int,
  [LoyaltyTierKey] int,
  [MonthlyPointsEarned] decimal(18,2),
  [MonthlyPointsRedeemed] decimal(18,2),
  [NetPointChange] decimal(18,2),
  [MonthlyPointValueUSD] decimal(18,2),
  [MonthlyNumberOfTransactions] int,
  [MonthlyDistinctFlightsEarnedOn] int
)
GO
