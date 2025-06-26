CREATE SCHEMA [Source]

CREATE TABLE [Source].[Airline] (
  [AirlineID] integer PRIMARY KEY,
  [Name] varchar(100),
  [Country] varchar(50),
  [FoundedDate] date,
  [HeadquartersNumber] varchar(50),
  [FleetSize] integer,
  [Website] varchar(200),
  [Current_IATA_Code] varchar(3) NULL,  
  [Previous_IATA_Code] varchar(3) NULL,
  [IATA_Code_Changed_Date] date NULL
)
GO

CREATE TABLE [Source].[Airport] (
  [AirportID] integer PRIMARY KEY,
  [City] varchar(50),
  [Country] varchar(50),
  [IATACode] varchar(3),
  [ElevationMeter] integer,
  [TimeZone] varchar(50),
  [NumberOfTerminals] integer,
  [AnnualPassengerTraffic] bigint,
  [Latitude] decimal(9,6),
  [Longitude] decimal(9,6),
  [ManagerName] varchar(100)
)
GO

CREATE TABLE [Source].[Aircraft] (
  [AircraftID] integer PRIMARY KEY,
  [Model] varchar(50),
  [Type] varchar(50),
  [ManufacturerDate] date,
  [Capacity] integer,
  [Price] decimal(18,2),
  [AirlineID] integer NOT NULL
)
GO

CREATE TABLE [Source].[Person] (
  [PersonID] integer PRIMARY KEY,
  [NatCode] varchar(20) NOT NULL,
  [Name] varchar(100) NOT NULL,
  [Phone] varchar(20),
  [Email] varchar(100) UNIQUE,
  [Address] varchar(200),
  [City] varchar(50),
  [Country] varchar(50),
  [DateOfBirth] date,
  [Gender] varchar(10),
  [PostalCode] varchar(20)
)
GO

CREATE TABLE [Source].[Passenger] (
  [PassengerID] integer PRIMARY KEY,
  [PersonID] integer NOT NULL,
  [PassportNumber] varchar(50) UNIQUE
)
GO

CREATE TABLE [Source].[Account] (
  [AccountID] integer PRIMARY KEY,
  [PassengerID] integer NOT NULL,
  [RegistrationDate] datetime,
  [LoyaltyTierID] integer NOT NULL
)
GO

CREATE TABLE [Source].[LoyaltyTransactionType] (
  [LoyaltyTransactionTypeID] INT PRIMARY KEY,
  [TypeName] VARCHAR(50)
)
GO

CREATE TABLE [Source].[PointConversionRate] (
  [PointConversionRateID] INT PRIMARY KEY IDENTITY(1,1),
  [EffectiveFrom] DATETIME NOT NULL,
  [EffectiveTo] DATETIME,
  [ConversionRate] DECIMAL(18,6) NOT NULL,
  [CurrencyCode] VARCHAR(10) DEFAULT 'USD',
  [IsCurrent] BIT DEFAULT 1
)
GO

CREATE TABLE [Source].[PointsTransaction] (
  [PointsTransactionID] INT PRIMARY KEY,
  [AccountID] INT NOT NULL,
  [TransactionDate] DATETIME NOT NULL,
  [LoyaltyTransactionTypeID] INT NOT NULL,
  [PointsChange] DECIMAL(18,2) NOT NULL,
  [BalanceAfterTransaction] DECIMAL(18,2) NOT NULL,
  [USDValue] DECIMAL(18,2),
  [ConversionRate] DECIMAL(18,6),
  [PointConversionRateID] INT,
  [Description] VARCHAR(200),
  [ServiceOfferingID] INT,
  [FlightDetailID] INT
)
GO

CREATE TABLE [Source].[TravelClass] (
  [TravelClassID] INT PRIMARY KEY,
  [ClassName] VARCHAR(50) NOT NULL,
  [Capacity] INT,
  [BaseCost] DECIMAL(18,2)
)
GO

CREATE TABLE [Source].[Item] (
  [ItemID] INT PRIMARY KEY,
  [ItemName] VARCHAR(100),
  [Description] VARCHAR(300),
  [BasePrice] DECIMAL(18,2),
  [IsLoyaltyRedeemable] BIT DEFAULT 0
)
GO

CREATE TABLE [Source].[ServiceOffering] (
  [ServiceOfferingID] INT PRIMARY KEY,
  [TravelClassID] INT,
  [OfferingName] VARCHAR(100),
  [Description] VARCHAR(300),
  [TotalCost] DECIMAL(18,2)
)
GO

CREATE TABLE [Source].[ServiceOfferingItem] (
  [ServiceOfferingID] INT,
  [ItemID] INT,
  [Quantity] INT,
  PRIMARY KEY ([ServiceOfferingID], [ItemID])
)
GO

CREATE TABLE [Source].[Points] (
  [PointsID] integer PRIMARY KEY,
  [AccountID] integer NOT NULL,
  [PointsBalance] decimal(18,2) DEFAULT (0),
  [EffectiveDate] datetime NOT NULL
)
GO


CREATE TABLE [Source].[LoyaltyTier] (
  [LoyaltyTierID] integer PRIMARY KEY,
  [Name] varchar(50) NOT NULL,
  [MinPoints] integer NOT NULL,
  [Benefits] varchar(200)
)
GO

CREATE TABLE [Source].[AccountTierHistory] (
  [HistoryID] integer PRIMARY KEY,
  [AccountID] integer NOT NULL,
  [LoyaltyTierID] integer NOT NULL,
  [EffectiveFrom] datetime NOT NULL,
  [EffectiveTo] datetime,
  [CurrentFlag] bit DEFAULT (1)
)
GO

CREATE TABLE [Source].[CrewMember] (
  [CrewMemberID] integer PRIMARY KEY,
  [PersonID] integer NOT NULL,
  [Role] varchar(50)
)
GO

CREATE TABLE [Source].[FlightDetail] (
  [FlightDetailID] integer PRIMARY KEY,
  [DepartureAirportID] integer NOT NULL,
  [DestinationAirportID] integer NOT NULL,
  [DistanceKM] integer NOT NULL,
  [DepartureDateTime] datetime NOT NULL,
  [ArrivalDateTime] datetime NOT NULL,
  [AircraftID] integer,
  [FlightCapacity] integer NOT NULL,
  [TotalCost] decimal(18,2)
)
GO

CREATE TABLE [Source].[SeatDetail] (
  [SeatDetailID] integer PRIMARY KEY,
  [AircraftID] integer NOT NULL,
  [SeatNo] integer NOT NULL,
  [SeatType] varchar(20),
  [TravelClassID] integer,
  [ReservationID] integer
)
GO

CREATE TABLE [Source].[Reservation] (
  [ReservationID] integer PRIMARY KEY,
  [PassengerID] integer NOT NULL,
  [FlightDetailID] integer NOT NULL,
  [ReservationDate] datetime,
  [SeatDetailID] integer,
  [Status] varchar(20) DEFAULT 'Booked'
)
GO

CREATE TABLE [Source].[Payment] (
  [PaymentID] integer PRIMARY KEY,
  [ReservationID] integer NOT NULL,
  [BuyerID] integer NOT NULL,
  [Status] varchar(20) DEFAULT 'Pending',
  [RealPrice] decimal(18,2),
  [TicketPrice] decimal(18,2) NOT NULL,
  [Discount] decimal(18,2) DEFAULT (0),
  [Tax] decimal(18,2) DEFAULT (10),
  [Method] varchar(50),
  [PaymentDateTime] datetime
)
GO

CREATE TABLE [Source].[CrewAssignment] (
  [CrewAssignmentID] integer PRIMARY KEY,
  [FlightDetailID] integer NOT NULL,
  [CrewMemberID] integer NOT NULL
)
GO

CREATE TABLE [Source].[FlightOperation] (
  [FlightOperationID] integer PRIMARY KEY,
  [FlightDetailID] integer NOT NULL,
  [ActualDepartureDateTime] datetime,
  [ActualArrivalDateTime] datetime,
  [DelayMinutes] integer DEFAULT (0),
  [CancelFlag] bit DEFAULT (0),
  [LoadFactor] float,
  [DelaySeverityScore] float
)
GO

CREATE TABLE [Source].[MaintenanceType] (
  [ID]          integer PRIMARY KEY,
  [Name]        varchar(100),
  [Category]    varchar(50),
  [Description] varchar(500)
);
GO

CREATE TABLE [Source].[Technician] (
  [Technician_ID]       integer PRIMARY KEY,
  [Name]                varchar(100),
  [Certification_Level] varchar(10),
  [Employment_Type]     varchar(50),
  [Active_Status]       bit
);
GO

CREATE TABLE [Source].[MaintenanceLocation] (
  [Location_NK]   varchar(100) PRIMARY KEY,
  [Name]          varchar(100),
  [City]          varchar(50),
  [Country]       varchar(50),
  [Inhouse_Flag]  bit
);
GO

CREATE TABLE [Source].[Part] (
  [ID]                     integer PRIMARY KEY,
  [Name]                   varchar(100),
  [PartNumber]             varchar(50),
  [Manufacturer]           varchar(100),
  [Warranty_Period_Months] int,
  [Category]               varchar(50)
);
GO

CREATE TABLE [Source].[AirlineAirportService] (
    [ServiceTypeCode] VARCHAR(50) NOT NULL,
    [FlightTypeCode] VARCHAR(50) NOT NULL,
    [ServiceTypeName] VARCHAR(100) NOT NULL,
    [FlightTypeName] VARCHAR(100) NOT NULL,
    [ContractStartDate] DATE NOT NULL,
    [ContractEndDate] DATE,
    [LandingFeeRate] DECIMAL(18,4),
    [PassengerServiceRate] DECIMAL(18,4),
    CONSTRAINT [PK_Source_AirlineAirportService] PRIMARY KEY ([ServiceTypeCode], [FlightTypeCode])
);
GO