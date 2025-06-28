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

CREATE NONCLUSTERED INDEX IX_PersonPointTransactions_MonthlyFact_PersonKey
ON [DW].[PersonPointTransactions_MonthlyFact] (PersonKey);
GO

CREATE NONCLUSTERED INDEX IX_PersonPointTransactions_MonthlyFact_LoyaltyTierKey
ON [DW].[PersonPointTransactions_MonthlyFact] (LoyaltyTierKey);
GO

CREATE NONCLUSTERED INDEX IX_PersonPointTransactions_MonthlyFact_MonthID
ON [DW].[PersonPointTransactions_MonthlyFact] (MonthID);
GO