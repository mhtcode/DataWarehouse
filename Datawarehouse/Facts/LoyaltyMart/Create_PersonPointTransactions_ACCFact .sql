CREATE TABLE [DW].[PersonPointTransactions_ACCFact] (
  [MonthID] date,
  [PersonKey] int,
  [LoyaltyTierKey] int,
  [PointsEarnedTotal] decimal(18,2),
  [PointsRedeemedTotal] decimal(18,2),
  [NetPointChange] decimal(18,2),
  [PointValueUSD_Total] decimal(18,2),
  [NumberOfTransactions] int,
  [DistinctFlightsEarnedOn] int
)
GO