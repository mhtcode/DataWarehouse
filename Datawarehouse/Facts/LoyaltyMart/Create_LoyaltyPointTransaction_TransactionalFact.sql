CREATE TABLE [DW].[LoyaltyPointTransaction_TransactionalFact] (
    -- Dimensional Surrogate Keys
    [TransactionDateKey] datetime NOT NULL,             -- From PointsTransaction.TransactionDate, FK to DimDateTime
    [PersonKey] int NOT NULL,                           -- Resolved via Account -> Passenger -> Person, FK to DimPerson
    [AccountKey] int NOT NULL,                          -- PointsTransaction.AccountID, FK to DimAccount
    [LoyaltyTierKey] int NOT NULL,                      -- Tier active at TransactionDate, FK to DimLoyaltyTier
    [TransactionTypeKey] int NOT NULL,                  -- PointsTransaction.LoyaltyTransactionTypeID, FK to DimLoyaltyTransactionType
    [ConversionRateKey] int NULL,                       -- PointsTransaction.PointConversionRateID, FK to DimPointConversionRate (nullable)
    [FlightKey] int NULL,                               -- PointsTransaction.FlightDetailID, FK to DimFlight (nullable)
    [ServiceOfferingKey] int NULL,                      -- PointsTransaction.ServiceOfferingID, FK to DimServiceOffering (nullable)

    -- Business Measures
    [PointsEarned] decimal(18,2) NULL,                  -- If PointsTransaction.PointsChange > 0, set to PointsChange; otherwise, NULL or 0
    [PointsRedeemed] decimal(18,2) NULL,                -- If PointsTransaction.PointsChange < 0, set to ABS(PointsChange); otherwise, NULL or 0
    [CurrencyValue] decimal(18,2) NULL,                 -- Direct from PointsTransaction.CurrencyValue
    [ConversionRateSnapshot] decimal(18,6) NULL,        -- Direct from PointsTransaction.ConversionRate
    [BalanceAfterTransaction] decimal(18,2) NULL,       -- Direct from PointsTransaction.BalanceAfterTransaction
)
GO

CREATE NONCLUSTERED INDEX IX_LoyaltyPointTransaction_TransactionalFact_TransactionDateKey
ON [DW].[LoyaltyPointTransaction_TransactionalFact] (TransactionDateKey);
GO

CREATE NONCLUSTERED INDEX IX_LoyaltyPointTransaction_TransactionalFact_AccountKey
ON [DW].[LoyaltyPointTransaction_TransactionalFact] (AccountKey);
GO

CREATE NONCLUSTERED INDEX IX_LoyaltyPointTransaction_TransactionalFact_LoyaltyTierKey
ON [DW].[LoyaltyPointTransaction_TransactionalFact] (LoyaltyTierKey);
GO

CREATE NONCLUSTERED INDEX IX_LoyaltyPointTransaction_TransactionalFact_FlightKey
ON [DW].[LoyaltyPointTransaction_TransactionalFact] (FlightKey);
GO


CREATE NONCLUSTERED INDEX IX_LoyaltyPointTransaction_TransactionalFact_PersonKey
ON [DW].[LoyaltyPointTransaction_TransactionalFact] (PersonKey);
GO

CREATE NONCLUSTERED INDEX IX_LoyaltyPointTransaction_TransactionalFact_ServiceOfferingKey
ON [DW].[LoyaltyPointTransaction_TransactionalFact] (ServiceOfferingKey);
GO

CREATE NONCLUSTERED INDEX IX_LoyaltyPointTransaction_TransactionalFact_ConversionRateKey
ON [DW].[LoyaltyPointTransaction_TransactionalFact] (ConversionRateKey);
GO

CREATE NONCLUSTERED INDEX IX_LoyaltyPointTransaction_TransactionalFact_TransactionTypeKey
ON [DW].[LoyaltyPointTransaction_TransactionalFact] (TransactionTypeKey);
GO
