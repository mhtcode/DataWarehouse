CREATE TABLE [DW].[DimPayment] (
  [PaymentKey] int PRIMARY KEY,
  [PaymentMethod] nvarchar(255),
  [PaymentStatus] nvarchar(255),
  [PaymentTimestamp] datetime
)
GO


CREATE NONCLUSTERED INDEX IX_DimPayment_PaymentStatus
ON [DW].[DimPayment] (PaymentStatus);
GO

CREATE NONCLUSTERED INDEX IX_DimPayment_PaymentMethod
ON [DW].[DimPayment] (PaymentMethod);
GO

CREATE NONCLUSTERED INDEX IX_DimPayment_PaymentTimestamp
ON [DW].[DimPayment] (PaymentTimestamp);
GO
