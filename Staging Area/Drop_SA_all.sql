-- Drop all staging tables in the SA schema
-- Order is arranged to drop dependent tables before their parents

DROP TABLE IF EXISTS [SA].[Payment];
DROP TABLE IF EXISTS [SA].[Reservation];
DROP TABLE IF EXISTS [SA].[SeatDetail];
DROP TABLE IF EXISTS [SA].[ServiceOffering];
DROP TABLE IF EXISTS [SA].[TravelClass];

DROP TABLE IF EXISTS [SA].[FlightDetail];
DROP TABLE IF EXISTS [SA].[FlightOperation];

DROP TABLE IF EXISTS [SA].[CrewAssignment];
DROP TABLE IF EXISTS [SA].[CrewMember];

DROP TABLE IF EXISTS [SA].[AccountTierHistory];
DROP TABLE IF EXISTS [SA].[PointsTransaction];
DROP TABLE IF EXISTS [SA].[Points];
DROP TABLE IF EXISTS [SA].[Account];

DROP TABLE IF EXISTS [SA].[Passenger];
DROP TABLE IF EXISTS [SA].[Person];

DROP TABLE IF EXISTS [SA].[Aircraft];
DROP TABLE IF EXISTS [SA].[Airport];
DROP TABLE IF EXISTS [SA].[Airline];
