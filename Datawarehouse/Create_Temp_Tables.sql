IF OBJECT_ID('[DW].[Temp_Person_table]', 'U') IS NULL
BEGIN
	CREATE TABLE [DW].[Temp_Person_table] (
	  [PersonID]       INT           NOT NULL PRIMARY KEY,
	  [NationalCode]   NVARCHAR(255) NULL,
	  [PassportNumber] NVARCHAR(255) NULL,
	  [Name]           NVARCHAR(255) NULL,
	  [Gender]         NVARCHAR(255) NULL,
	  [DateOfBirth]    DATE          NULL,
	  [City]           NVARCHAR(255) NULL,
	  [Country]        NVARCHAR(255) NULL,
	  [Email]          NVARCHAR(255) NULL,
	  [Phone]          NVARCHAR(255) NULL,
	  [Address]        NVARCHAR(255) NULL,
	  [PostalCode]     NVARCHAR(255) NULL
	);
	END;
GO


IF OBJECT_ID('[DW].[Temp_Aircraft_table]', 'U') IS NULL
BEGIN
  CREATE TABLE [DW].[Temp_Aircraft_table] (
    [AircraftID]        INT           NOT NULL PRIMARY KEY,
    [Model]             NVARCHAR(255) NULL,
    [Type]              NVARCHAR(255) NULL,
    [ManufacturerDate]  DATE          NULL,
    [Capacity]          INT           NULL,
    [Price]             DECIMAL(18,2) NULL
  );
END;
GO


IF OBJECT_ID('[DW].[Temp_Account_table]', 'U') IS NULL
BEGIN
  CREATE TABLE [DW].[Temp_Account_table] (
    AccountID       INT             NOT NULL PRIMARY KEY,
    AccountNumber   NVARCHAR(255)   NULL,
    AccountType     NVARCHAR(255)   NULL,
    CreatedDate     DATETIME        NULL,
    IsActive        BIT             NULL
  );
END;
GO


IF OBJECT_ID('[DW].[Temp_Airline_table]', 'U') IS NULL
BEGIN
  CREATE TABLE [DW].[Temp_Airline_table] (
    AirlineID     INT            NOT NULL PRIMARY KEY,
    Name          NVARCHAR(255)  NULL,
    Country       NVARCHAR(255)  NULL,
    FoundedYear   INT            NULL,
    FleetSize     INT            NULL,
    Website       NVARCHAR(255)  NULL
  );
END;
GO


IF OBJECT_ID('[DW].[Temp_Airport_table]', 'U') IS NULL
BEGIN
  CREATE TABLE [DW].[Temp_Airport_table] (
    AirportID               INT            NOT NULL PRIMARY KEY,
    Name                    NVARCHAR(255)  NULL,
    City                    NVARCHAR(255)  NULL,
    Country                 NVARCHAR(255)  NULL,
    IATACode                NVARCHAR(255)  NULL,
    ElevationMeter          INT            NULL,
    TimeZone                NVARCHAR(255)  NULL,
    NumberOfTerminals       INT            NULL,
    AnnualPassengerTraffic  BIGINT         NULL,
    Latitude                DECIMAL(18,6)  NULL,
    Longitude               DECIMAL(18,6)  NULL
  );
END;
GO


IF OBJECT_ID('[DW].[Temp_Crew_table]', 'U') IS NULL
BEGIN
  CREATE TABLE [DW].[Temp_Crew_table] (
    Crew_ID        INT             NOT NULL PRIMARY KEY,
    NAT_CODE       NVARCHAR(255)   NULL,
    Name           NVARCHAR(255)   NULL,
    Phone          NVARCHAR(255)   NULL,
    Email          NVARCHAR(255)   NULL,
    Address        NVARCHAR(255)   NULL,
    City           NVARCHAR(255)   NULL,
    Country        NVARCHAR(255)   NULL,
    Date_Of_Birth  DATE            NULL,
    Gender         NVARCHAR(255)   NULL,
    Postal_Code    NVARCHAR(255)   NULL,
    Role           NVARCHAR(255)   NULL
  );
END;
GO


IF OBJECT_ID('[DW].[Temp_LoyaltyTier_table]', 'U') IS NULL
BEGIN
  CREATE TABLE [DW].[Temp_LoyaltyTier_table] (
    LoyaltyTierID   INT           NOT NULL PRIMARY KEY,
    Name            NVARCHAR(255) NULL,
    MinPoints       INT           NULL,
    Benefits        NVARCHAR(255) NULL
  );
END;
GO


IF OBJECT_ID('[DW].[Temp_LoyaltyTransactionType_table]', 'U') IS NULL
BEGIN
  CREATE TABLE [DW].[Temp_LoyaltyTransactionType_table] (
    TransactionTypeName NVARCHAR(255) NOT NULL PRIMARY KEY
  );
END;
GO


IF OBJECT_ID('[DW].[Temp_Payment_table]', 'U') IS NULL
BEGIN
  CREATE TABLE [DW].[Temp_Payment_table] (
    PaymentID        INT            NOT NULL PRIMARY KEY,
    PaymentMethod    NVARCHAR(255)  NULL,
    PaymentStatus    NVARCHAR(255)  NULL,
    PaymentTimestamp DATETIME       NULL
  );
END;
GO


IF OBJECT_ID('[DW].[Temp_Flight_table]', 'U') IS NULL
BEGIN
  CREATE TABLE [DW].[Temp_Flight_table] (
  FlightID INT NOT NULL PRIMARY KEY,
  DepartureDateTime DATETIME,
  ArrivalDateTime DATETIME,
  FlightDurationMinutes INT,
  AircraftKey INT,
  FlightCapacity INT,
  TotalCost INT
  );
END;
GO


IF OBJECT_ID('[DW].[Temp_AirlineAirportService_table]', 'U') IS NULL
BEGIN
  CREATE TABLE [DW].[Temp_AirlineAirportService_table] (
    [ServiceTypeCode] VARCHAR(50) NOT NULL,
    [FlightTypeCode] VARCHAR(50) NOT NULL,
    [ServiceTypeName] VARCHAR(100) NULL,
    [FlightTypeName] VARCHAR(100) NULL,
    [ContractStartDate] DATE NULL,
    [ContractEndDate] DATE NULL,
    [LandingFeeRate] DECIMAL(18,4) NULL,
    [PassengerServiceRate] DECIMAL(18,4) NULL
  );
END;
GO

