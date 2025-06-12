CREATE OR ALTER PROCEDURE [SA].[ETL_SeatDetail]
AS
BEGIN
    MERGE [SA].[SeatDetail] AS TARGET
    USING [Source].[SeatDetail] AS SOURCE
    ON (TARGET.SeatDetailID = SOURCE.SeatDetailID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.AircraftID, SOURCE.SeatNo, SOURCE.SeatType, SOURCE.TravelClassID, SOURCE.ReservationID
        EXCEPT
        SELECT TARGET.AircraftID, TARGET.SeatNo, TARGET.SeatType, TARGET.TravelClassID, TARGET.ReservationID
    ) THEN
        UPDATE SET
            TARGET.AircraftID = SOURCE.AircraftID,
            TARGET.SeatNo = SOURCE.SeatNo,
            TARGET.SeatType = NULLIF(TRIM(SOURCE.SeatType), ''),
            TARGET.TravelClassID = SOURCE.TravelClassID,
            TARGET.ReservationID = SOURCE.ReservationID,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            SeatDetailID,
            AircraftID,
            SeatNo,
            SeatType,
            TravelClassID,
            ReservationID,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.SeatDetailID,
            SOURCE.AircraftID,
            SOURCE.SeatNo,
            NULLIF(TRIM(SOURCE.SeatType), ''),
            SOURCE.TravelClassID,
            SOURCE.ReservationID,
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon

END