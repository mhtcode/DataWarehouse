CREATE SCHEMA [SA]
GO

-- Account
CREATE TABLE [SA].[Account] (
  [AccountID] integer PRIMARY KEY,
  [PassengerID] integer NOT NULL,
  [RegistrationDate] datetime,
  [LoyaltyTierID] integer NOT NULL,
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- AccountTierHistory
CREATE TABLE [SA].[AccountTierHistory] (
  [HistoryID] integer PRIMARY KEY,
  [AccountID] integer NOT NULL,
  [LoyaltyTierID] integer NOT NULL,
  [EffectiveFrom] datetime NOT NULL,
  [EffectiveTo] datetime,
  [CurrentFlag] bit DEFAULT (1),
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- Aircraft
CREATE TABLE [SA].[Aircraft] (
  [AircraftID] integer PRIMARY KEY,
  [Model] varchar(50),
  [Type] varchar(50),
  [ManufacturerDate] date,
  [Capacity] integer,
  [Price] decimal(18,2),
  [AirlineID] integer NOT NULL,
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- Airline
CREATE TABLE [SA].[Airline] (
  [AirlineID] integer PRIMARY KEY,
  [Name] varchar(100),
  [Country] varchar(50),
  [FoundedDate] date,
  [HeadquartersNumber] varchar(50),
  [FleetSize] integer,
  [Website] varchar(200),
  [Current_IATA_Code] varchar(3) NULL,
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- AirlineAirportService
CREATE TABLE [SA].[AirlineAirportService] (
  [ServiceTypeCode] varchar(50) NOT NULL,
  [FlightTypeCode] varchar(50) NOT NULL,
  [ServiceTypeName] varchar(100) NOT NULL,
  [FlightTypeName] varchar(100) NOT NULL,
  [ContractStartDate] date NOT NULL,
  [ContractEndDate] date,
  [LandingFeeRate] decimal(18,4),
  [PassengerServiceRate] decimal(18,4),
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200),
  CONSTRAINT [PK_SA_AirlineAirportService] PRIMARY KEY ([ServiceTypeCode], [FlightTypeCode])
)
GO

-- Airport
CREATE TABLE [SA].[Airport] (
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
  [ManagerName] varchar(100),
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- CrewAssignment
CREATE TABLE [SA].[CrewAssignment] (
  [CrewAssignmentID] integer PRIMARY KEY,
  [FlightDetailID] integer NOT NULL,
  [CrewMemberID] integer NOT NULL,
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- CrewMember
CREATE TABLE [SA].[CrewMember] (
  [CrewMemberID] integer PRIMARY KEY,
  [PersonID] integer NOT NULL,
  [Role] varchar(50),
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- FlightDetail
CREATE TABLE [SA].[FlightDetail] (
  [FlightDetailID] integer PRIMARY KEY,
  [DepartureAirportID] integer NOT NULL,
  [DestinationAirportID] integer NOT NULL,
  [DistanceKM] integer NOT NULL,
  [DepartureDateTime] datetime NOT NULL,
  [ArrivalDateTime] datetime NOT NULL,
  [AircraftID] integer,
  [FlightCapacity] integer NOT NULL,
  [TotalCost] decimal(18,2),
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- FlightOperation
CREATE TABLE [SA].[FlightOperation] (
  [FlightOperationID] integer PRIMARY KEY,
  [FlightDetailID] integer NOT NULL,
  [ActualDepartureDateTime] datetime,
  [ActualArrivalDateTime] datetime,
  [DelayMinutes] integer DEFAULT (0),
  [CancelFlag] bit DEFAULT (0),
  [LoadFactor] float,
  [DelaySeverityScore] float,
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- Item
CREATE TABLE [SA].[Item] (
  [ItemID] INT PRIMARY KEY,
  [ItemName] VARCHAR(100),
  [Description] VARCHAR(300),
  [BasePrice] DECIMAL(18,2),
  [IsLoyaltyRedeemable] BIT DEFAULT 0,
  [StagingLoadTimestampUTC] DATETIME,
  [StagingLastUpdateTimestampUTC] DATETIME,
  [SourceSystem] VARCHAR(200)
)
GO

-- LoyaltyTier
CREATE TABLE [SA].[LoyaltyTier] (
  [LoyaltyTierID] integer PRIMARY KEY,
  [Name] varchar(50) NOT NULL,
  [MinPoints] integer NOT NULL,
  [Benefits] varchar(200),
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- LoyaltyTransactionType
CREATE TABLE [SA].[LoyaltyTransactionType] (
  [LoyaltyTransactionTypeID] INT PRIMARY KEY,
  [TypeName] VARCHAR(50),
  [StagingLoadTimestampUTC] DATETIME,
  [StagingLastUpdateTimestampUTC] DATETIME,
  [SourceSystem] VARCHAR(200)
)
GO

-- MaintenanceLocation
CREATE TABLE [SA].[MaintenanceLocation] (
  [MaintenanceLocationID] varchar(100) PRIMARY KEY,
  [Name] varchar(100),
  [City] varchar(50),
  [Country] varchar(50),
  [InhouseFlag] bit,
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- MaintenanceType
CREATE TABLE [SA].[MaintenanceType] (
  [MaintenanceTypeID] integer PRIMARY KEY,
  [Name] varchar(100),
  [Category] varchar(50),
  [Description] varchar(500),
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- Part
CREATE TABLE [SA].[Part] (
  [PartID] integer PRIMARY KEY,
  [Name] varchar(100),
  [PartNumber] varchar(50),
  [Manufacturer] varchar(100),
  [WarrantyPeriodMonths] int,
  [Category] varchar(50),
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- Passenger
CREATE TABLE [SA].[Passenger] (
  [PassengerID] integer PRIMARY KEY,
  [PersonID] integer NOT NULL,
  [PassportNumber] varchar(50) UNIQUE,
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- Payment
CREATE TABLE [SA].[Payment] (
  [PaymentID] integer PRIMARY KEY,
  [ReservationID] integer NOT NULL,
  [BuyerID] integer NOT NULL,
  [Status] varchar(20) DEFAULT 'Pending',
  [RealPrice] decimal(18,2),
  [TicketPrice] decimal(18,2) NOT NULL,
  [Discount] decimal(18,2) DEFAULT (0),
  [Tax] decimal(18,2) DEFAULT (10),
  [Method] varchar(50),
  [PaymentDateTime] datetime,
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- Person
CREATE TABLE [SA].[Person] (
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
  [PostalCode] varchar(20),
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- PointConversionRate
CREATE TABLE [SA].[PointConversionRate] (
  [PointConversionRateID] INT PRIMARY KEY,
  [ConversionRate] DECIMAL(18,6) NOT NULL,
  [CurrencyCode] VARCHAR(10) DEFAULT 'USD',
  [StagingLoadTimestampUTC] DATETIME,
  [StagingLastUpdateTimestampUTC] DATETIME,
  [SourceSystem] VARCHAR(200)
)
GO

-- Points
CREATE TABLE [SA].[Points] (
  [PointsID] integer PRIMARY KEY,
  [AccountID] integer NOT NULL,
  [PointsBalance] decimal(18,2) DEFAULT (0),
  [EffectiveDate] datetime NOT NULL,
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- PointsTransaction
CREATE TABLE [SA].[PointsTransaction] (
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
  [FlightDetailID] INT,
  [StagingLoadTimestampUTC] DATETIME,
  [StagingLastUpdateTimestampUTC] DATETIME,
  [SourceSystem] VARCHAR(200)
)
GO

-- Reservation
CREATE TABLE [SA].[Reservation] (
  [ReservationID] integer PRIMARY KEY,
  [PassengerID] integer NOT NULL,
  [FlightDetailID] integer NOT NULL,
  [ReservationDate] datetime,
  [SeatDetailID] integer,
  [Status] varchar(20) DEFAULT 'Booked',
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- SeatDetail
CREATE TABLE [SA].[SeatDetail] (
  [SeatDetailID] integer PRIMARY KEY,
  [AircraftID] integer NOT NULL,
  [SeatNo] integer NOT NULL,
  [SeatType] varchar(20),
  [TravelClassID] integer,
  [ReservationID] integer,
  [StagingLoadTimestampUTC] datetime,
  [StagingLastUpdateTimestampUTC] datetime,
  [SourceSystem] varchar(200)
)
GO

-- ServiceOffering
CREATE TABLE [SA].[ServiceOffering] (
  [ServiceOfferingID] INT PRIMARY KEY,
  [TravelClassID] INT,
  [OfferingName] VARCHAR(100),
  [Description] VARCHAR(300),
  [TotalCost] DECIMAL(18,2),
  [StagingLoadTimestampUTC] DATETIME,
  [StagingLastUpdateTimestampUTC] DATETIME,
  [SourceSystem] VARCHAR(200)
)

GO

-- ServiceOfferingItem
CREATE TABLE [SA].[ServiceOfferingItem] (
  [ServiceOfferingID] INT NOT NULL,
  [ItemID] INT NOT NULL,
  [Quantity] INT,
  [StagingLoadTimestampUTC] DATETIME,
  [StagingLastUpdateTimestampUTC] DATETIME,
  [SourceSystem] VARCHAR(200),
  CONSTRAINT [PK_SA_ServiceOfferingItem] PRIMARY KEY ([ServiceOfferingID], [ItemID])
)

GO

-- Technician
CREATE TABLE [SA].[Technician] (
  [TechnicianID] INT PRIMARY KEY,
  [PersonID] INT,
  [Specialty] VARCHAR(100),
  [StagingLoadTimestampUTC] DATETIME,
  [StagingLastUpdateTimestampUTC] DATETIME,
  [SourceSystem] VARCHAR(200)
)

GO

-- TravelClass
CREATE TABLE [SA].[TravelClass] (
  [TravelClassID] INT PRIMARY KEY,
  [ClassName] VARCHAR(50),
  [Capacity] INT,
  [BaseCost] DECIMAL(18,2),
  [StagingLoadTimestampUTC] DATETIME,
  [StagingLastUpdateTimestampUTC] DATETIME,
  [SourceSystem] VARCHAR(200)
)

GO