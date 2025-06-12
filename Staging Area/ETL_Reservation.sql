CREATE OR ALTER PROCEDURE [SA].[ETL_Reservation]
AS
BEGIN
    MERGE [SA].[Reservation] AS TARGET
    USING [Source].[Reservation] AS SOURCE
    ON (TARGET.ReservationID = SOURCE.ReservationID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.PassengerID, SOURCE.FlightDetailID, SOURCE.ReservationDate, SOURCE.SeatDetailID, SOURCE.Status
        EXCEPT
        SELECT TARGET.PassengerID, TARGET.FlightDetailID, TARGET.ReservationDate, TARGET.SeatDetailID, TARGET.Status
    ) THEN
        UPDATE SET
            TARGET.PassengerID = SOURCE.PassengerID,
            TARGET.FlightDetailID = SOURCE.FlightDetailID,
            TARGET.ReservationDate = SOURCE.ReservationDate,
            TARGET.SeatDetailID = SOURCE.SeatDetailID,
            TARGET.Status = NULLIF(TRIM(SOURCE.Status), ''),
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            ReservationID,
            PassengerID,
            FlightDetailID,
            ReservationDate,
            SeatDetailID,
            Status,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.ReservationID,
            SOURCE.PassengerID,
            SOURCE.FlightDetailID,
            SOURCE.ReservationDate,
            SOURCE.SeatDetailID,
            NULLIF(TRIM(SOURCE.Status), ''),
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon

END