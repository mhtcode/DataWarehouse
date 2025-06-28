CREATE TABLE [DW].[DimFlightOperationType] (
  [OperationTypeID]    INT PRIMARY KEY,
  [OperationTypeName]   NVARCHAR(50) NOT NULL,
  [OperationTypeDescription] NVARCHAR(255) NULL
);
GO