CREATE TABLE [DW].[DimAccount] (
  [AccountID] INT PRIMARY KEY,           -- Use AccountID from SA (business key)
  [PassengerName] NVARCHAR(100),         -- From SA.Person (via SA.Passenger)
  [RegistrationDate] DATETIME,           -- From SA.Account
  [LoyaltyTierName] NVARCHAR(50)         -- From SA.LoyaltyTier
)
GO

CREATE NONCLUSTERED INDEX IX_DimAccount_LoyaltyTierName
ON [DW].[DimAccount] (LoyaltyTierName);
GO

CREATE NONCLUSTERED INDEX IX_DimAccount_PassengerName
ON [DW].[DimAccount] (PassengerName);
GO

CREATE NONCLUSTERED INDEX IX_DimAccount_RegistrationDate
ON [DW].[DimAccount] (RegistrationDate);
GO
