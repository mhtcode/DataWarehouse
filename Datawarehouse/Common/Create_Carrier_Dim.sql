CREATE TABLE [DW].[DimCarrier] (
  [Carrier_ID] integer PRIMARY KEY,
  [Name] nvarchar(255),
  [Country] nvarchar(255),
  [Founded_Date] date,
  [Current_IATA_Code] nvarchar(255),
  [Previous_IATA_Code] nvarchar(255),
  [IATA_Code_Changed_Date] date
)
GO
