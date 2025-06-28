CREATE TABLE [DW].[DimAirlineAirportService] (
    [ServiceDimKey] INT NOT NULL PRIMARY KEY,
    [ServiceTypeCode] NVARCHAR(50) NOT NULL,
    [FlightTypeCode] NVARCHAR(50) NOT NULL,
    [ServiceTypeName] NVARCHAR(100) NOT NULL,
    [FlightTypeName] NVARCHAR(100) NOT NULL,
    [ContractStartDate] DATE NOT NULL,
    [ContractEndDate] DATE,
    [LandingFeeRate] DECIMAL(18,4),
    [PassengerServiceRate] DECIMAL(18,4)
);
GO

CREATE NONCLUSTERED INDEX IX_DimAirlineAirportService_BusinessKeys
ON [DW].[DimAirlineAirportService] (ServiceTypeCode, FlightTypeCode);
GO

CREATE NONCLUSTERED INDEX IX_DimAirlineAirportService_ServiceTypeName
ON [DW].[DimAirlineAirportService] (ServiceTypeName);
GO

CREATE NONCLUSTERED INDEX IX_DimAirlineAirportService_FlightTypeName
ON [DW].[DimAirlineAirportService] (FlightTypeName);
GO

CREATE NONCLUSTERED INDEX IX_DimAirlineAirportService_ContractDates
ON [DW].[DimAirlineAirportService] (ContractStartDate, ContractEndDate);
GO
