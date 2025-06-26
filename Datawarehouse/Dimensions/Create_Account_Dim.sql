CREATE TABLE [DW].[DimAccount] (
  [AccountID] INT PRIMARY KEY,           -- Use AccountID from SA (business key)
  [PassengerName] NVARCHAR(100),         -- From SA.Person (via SA.Passenger)
  [RegistrationDate] DATETIME,           -- From SA.Account
  [LoyaltyTierName] NVARCHAR(50)         -- From SA.LoyaltyTier
)
GO
