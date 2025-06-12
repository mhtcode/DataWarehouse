CREATE SCHEMA [SA]

CREATE TABLE [SA].[Airline] (
  [AirlineID] integer PRIMARY KEY,
  [Name] varchar(100),
  [Country] varchar(50),
  [FoundedDate] date,
  [HeadquartersNumber] varchar(50),
  [FleetSize] integer,
  [Website] varchar(200)
)
GO

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
  [ManagerName] varchar(100)
)
GO

CREATE TABLE [SA].[Aircraft] (
  [AircraftID] integer PRIMARY KEY,
  [Model] varchar(50),
  [Type] varchar(50),
  [ManufacturerDate] date,
  [Capacity] integer,
  [Price] decimal(18,2),
  [AirlineID] integer NOT NULL
)
GO

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
  [PostalCode] varchar(20)
)
GO

CREATE TABLE [SA].[Passenger] (
  [PassengerID] integer PRIMARY KEY,
  [PersonID] integer NOT NULL,
  [PassportNumber] varchar(50) UNIQUE
)
GO

CREATE TABLE [SA].[Account] (
  [AccountID] integer PRIMARY KEY,
  [PassengerID] integer NOT NULL,
  [RegistrationDate] datetime,
  [LoyaltyTierID] integer NOT NULL
)
GO

CREATE TABLE [SA].[Points] (
  [PointsID] integer PRIMARY KEY,
  [AccountID] integer NOT NULL,
  [PointsBalance] decimal(18,2) DEFAULT (0),
  [EffectiveDate] datetime NOT NULL
)
GO

CREATE TABLE [SA].[PointsTransaction] (
  [TransactionID] integer PRIMARY KEY,
  [AccountID] integer NOT NULL,
  [TransactionDate] datetime NOT NULL,
  [TransactionType] varchar(10) NOT NULL,
  [PointsChange] decimal(18,2) NOT NULL,
  [Description] varchar(200),
  [ServiceOfferingID] integer
)
GO

CREATE TABLE [SA].[LoyaltyTier] (
  [LoyaltyTierID] integer PRIMARY KEY,
  [Name] varchar(50) NOT NULL,
  [MinPoints] integer NOT NULL,
  [Benefits] varchar(200)
)
GO

CREATE TABLE [SA].[AccountTierHistory] (
  [HistoryID] integer PRIMARY KEY,
  [AccountID] integer NOT NULL,
  [LoyaltyTierID] integer NOT NULL,
  [EffectiveFrom] datetime NOT NULL,
  [EffectiveTo] datetime,
  [CurrentFlag] bit DEFAULT (1)
)
GO

CREATE TABLE [SA].[CrewMember] (
  [CrewMemberID] integer PRIMARY KEY,
  [PersonID] integer NOT NULL,
  [Role] varchar(50)
)
GO

CREATE TABLE [SA].[FlightDetail] (
  [FlightDetailID] integer PRIMARY KEY,
  [DepartureAirportID] integer NOT NULL,
  [DestinationAirportID] integer NOT NULL,
  [DepartureDateTime] datetime NOT NULL,
  [ArrivalDateTime] datetime NOT NULL,
  [AircraftID] integer,
  [FlightCapacity] integer NOT NULL,
  [TotalCost] decimal(18,2)
)
GO

CREATE TABLE [SA].[TravelClass] (
  [TravelClassID] integer PRIMARY KEY,
  [Name] varchar(50) NOT NULL,
  [Capacity] integer,
  [Cost] decimal(18,2)
)
GO

CREATE TABLE [SA].[ServiceOffering] (
  [ServiceOfferingID] integer PRIMARY KEY,
  [TravelClassID] integer,
  [Name] varchar(100),
  [Cost] decimal(18,2)
)
GO

CREATE TABLE [SA].[SeatDetail] (
  [SeatDetailID] integer PRIMARY KEY,
  [AircraftID] integer NOT NULL,
  [SeatNo] integer NOT NULL,
  [SeatType] varchar(20),
  [TravelClassID] integer,
  [ReservationID] integer
)
GO

CREATE TABLE [SA].[Reservation] (
  [ReservationID] integer PRIMARY KEY,
  [PassengerID] integer NOT NULL,
  [FlightDetailID] integer NOT NULL,
  [ReservationDate] datetime,
  [SeatDetailID] integer,
  [Status] varchar(20) DEFAULT 'Booked'
)
GO

CREATE TABLE [SA].[Payment] (
  [PaymentID] integer PRIMARY KEY,
  [ReservationID] integer NOT NULL,
  [Status] varchar(20) DEFAULT 'Pending',
  [Amount] decimal(18,2) NOT NULL,
  [RealPrice] decimal(18,2),
  [Discount] decimal(18,2) DEFAULT (0),
  [Method] varchar(50),
  [PaymentDateTime] datetime
)
GO

CREATE TABLE [SA].[CrewAssignment] (
  [CrewAssignmentID] integer PRIMARY KEY,
  [FlightDetailID] integer NOT NULL,
  [CrewMemberID] integer NOT NULL
)
GO

CREATE TABLE [SA].[FlightOperation] (
  [FlightOperationID] integer PRIMARY KEY,
  [FlightDetailID] integer NOT NULL,
  [ActualDepartureDateTime] datetime,
  [ActualArrivalDateTime] datetime,
  [DelayMinutes] integer DEFAULT (0),
  [CancelFlag] bit DEFAULT (0)
)
GO

