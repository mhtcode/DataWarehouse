-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS [PointsTransaction];
DROP TABLE IF EXISTS [Points];
DROP TABLE IF EXISTS [AccountTierHistory];
DROP TABLE IF EXISTS [Payment];
DROP TABLE IF EXISTS [CrewAssignment];
DROP TABLE IF EXISTS [FlightOperation];
DROP TABLE IF EXISTS [Reservation];
DROP TABLE IF EXISTS [SeatDetail];
DROP TABLE IF EXISTS [ServiceOffering];  -- Must drop before TravelClass
DROP TABLE IF EXISTS [CrewMember];
DROP TABLE IF EXISTS [Account];
DROP TABLE IF EXISTS [Passenger];
DROP TABLE IF EXISTS [FlightDetail];
DROP TABLE IF EXISTS [Aircraft];
DROP TABLE IF EXISTS [TravelClass];      -- Now safe to drop
DROP TABLE IF EXISTS [LoyaltyTier];
DROP TABLE IF EXISTS [Person];
DROP TABLE IF EXISTS [Airport];
DROP TABLE IF EXISTS [Airline];