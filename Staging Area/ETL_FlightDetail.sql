CREATE OR ALTER PROCEDURE [SA].[ETL_FlightDetail]
AS
BEGIN
    MERGE [SA].[FlightDetail] AS TARGET
    USING [Source].[FlightDetail] AS SOURCE
    ON (TARGET.FlightDetailID = SOURCE.FlightDetailID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.DepartureAirportID, SOURCE.DestinationAirportID, SOURCE.DistanceKM, SOURCE.DepartureDateTime, SOURCE.ArrivalDateTime, SOURCE.AircraftID, SOURCE.FlightCapacity, SOURCE.TotalCost
        EXCEPT
        SELECT TARGET.DepartureAirportID, TARGET.DestinationAirportID, TARGET.DistanceKM, TARGET.DepartureDateTime, TARGET.ArrivalDateTime, TARGET.AircraftID, TARGET.FlightCapacity, TARGET.TotalCost
    ) THEN
        UPDATE SET
            TARGET.DepartureAirportID = SOURCE.DepartureAirportID,
            TARGET.DestinationAirportID = SOURCE.DestinationAirportID,
            TARGET.DistanceKM = SOURCE.DistanceKM,
            TARGET.DepartureDateTime = SOURCE.DepartureDateTime,
            TARGET.ArrivalDateTime = SOURCE.ArrivalDateTime,
            TARGET.AircraftID = SOURCE.AircraftID,
            TARGET.FlightCapacity = SOURCE.FlightCapacity,
            TARGET.TotalCost = SOURCE.TotalCost,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            FlightDetailID,
            DepartureAirportID,
            DestinationAirportID,
            DistanceKM,
            DepartureDateTime,
            ArrivalDateTime,
            AircraftID,
            FlightCapacity,
            TotalCost,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.FlightDetailID,
            SOURCE.DepartureAirportID,
            SOURCE.DestinationAirportID,
            SOURCE.DistanceKM,
            SOURCE.DepartureDateTime,
            SOURCE.ArrivalDateTime,
            SOURCE.AircraftID,
            SOURCE.FlightCapacity,
            SOURCE.TotalCost,
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon

END