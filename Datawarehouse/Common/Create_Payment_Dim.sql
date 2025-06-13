CREATE TABLE [DimPayment] (
  [PaymentKey] int PRIMARY KEY,
  [PaymentMethod] nvarchar(255),
  [PaymentStatus] nvarchar(255),
  [PaymentTimestamp] datetime
)
GO
