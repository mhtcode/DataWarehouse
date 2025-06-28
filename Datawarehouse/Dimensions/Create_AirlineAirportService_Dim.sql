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