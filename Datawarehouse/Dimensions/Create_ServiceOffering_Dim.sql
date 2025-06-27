CREATE TABLE [DW].[DimServiceOffering] (
  [ServiceOfferingID] INT PRIMARY KEY,
  [OfferingName] NVARCHAR(100),
  [Description] NVARCHAR(300),
  [TravelClassName] NVARCHAR(50),         
  [TotalCost] DECIMAL(18,2),
  [ItemsSummary] NVARCHAR(400)            -- Computed from SA relations, comma separated
);
GO
