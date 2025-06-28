CREATE TABLE [DW].[DimLoyaltyTransactionType] (
  LoyaltyTransactionTypeID INT PRIMARY KEY,   -- Use business key, no need for a surrogate
  TypeName NVARCHAR(250)
);
GO

CREATE NONCLUSTERED INDEX IX_DimLoyaltyTransactionType_TypeName
ON [DW].[DimLoyaltyTransactionType] (TypeName);
GO
