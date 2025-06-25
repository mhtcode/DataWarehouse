CREATE TABLE [DW].[DimAirlineAirportService] (
    [ServiceDimKey] INT NOT NULL PRIMARY KEY,
    [ServiceTypeCode] VARCHAR(50) NOT NULL,
    [FlightTypeCode] VARCHAR(50) NOT NULL,
    [ServiceTypeName] VARCHAR(100) NOT NULL,
    [FlightTypeName] VARCHAR(100) NOT NULL,
    [ContractStartDate] DATE NOT NULL,
    [ContractEndDate] DATE,
    [LandingFeeRate] DECIMAL(18,4),
    [PassengerServiceRate] DECIMAL(18,4)
);
GO