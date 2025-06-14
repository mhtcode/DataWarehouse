-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS [Source].[PointsTransaction];
DROP TABLE IF EXISTS [Source].[Points];
DROP TABLE IF EXISTS [Source].[AccountTierHistory];
DROP TABLE IF EXISTS [Source].[Payment];
DROP TABLE IF EXISTS [Source].[CrewAssignment];
DROP TABLE IF EXISTS [Source].[FlightOperation];
DROP TABLE IF EXISTS [Source].[Reservation];
DROP TABLE IF EXISTS [Source].[SeatDetail];
DROP TABLE IF EXISTS [Source].[ServiceOffering];  -- Must drop before TravelClass
DROP TABLE IF EXISTS [Source].[CrewMember];
DROP TABLE IF EXISTS [Source].[Account];
DROP TABLE IF EXISTS [Source].[Passenger];
DROP TABLE IF EXISTS [Source].[FlightDetail];
DROP TABLE IF EXISTS [Source].[Aircraft];
DROP TABLE IF EXISTS [Source].[TravelClass];      -- Now safe to drop
DROP TABLE IF EXISTS [Source].[LoyaltyTier];
DROP TABLE IF EXISTS [Source].[Person];
DROP TABLE IF EXISTS [Source].[Airport];
DROP TABLE IF EXISTS [Source].[Airline];
DROP TABLE IF EXISTS [Source].[MaintenanceType];
DROP TABLE IF EXISTS [Source].[Technician];
DROP TABLE IF EXISTS [Source].[MaintenanceLocation];
DROP TABLE IF EXISTS [Source].[Part];