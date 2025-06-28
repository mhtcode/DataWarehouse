CREATE TABLE [DW].[DimFlightOperationType] (
  [OperationTypeID]    INT PRIMARY KEY,
  [OperationTypeName]   NVARCHAR(50) NOT NULL,
  [OperationTypeDescription] NVARCHAR(255) NULL
);
GO

CREATE NONCLUSTERED INDEX IX_DimFlightOperationType_OperationTypeName
ON [DW].[DimFlightOperationType] (OperationTypeName);
GO
