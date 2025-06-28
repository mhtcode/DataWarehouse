CREATE TABLE [DW].[FactLoyaltyPointTransaction_Transactional] (
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
