CREATE OR ALTER PROCEDURE [SA].[ETL_FlightDetail]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
        @RowsAffected  INT,
        @LogID         BIGINT;

    INSERT INTO [SA].[ETL_Log] (
        ProcedureName,
        SourceTable,
        TargetTable,
        ChangeDescription,
        ActionTime,
        Status
    ) VALUES (
        'ETL_FlightDetail',
        'Source.FlightDetail',
        'SA.FlightDetail',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        MERGE [SA].[FlightDetail] AS TARGET
        USING [Source].[FlightDetail] AS SOURCE
          ON TARGET.FlightDetailID = SOURCE.FlightDetailID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.DepartureAirportID,
                SOURCE.DestinationAirportID,
                SOURCE.DistanceKM,
                SOURCE.DepartureDateTime,
                SOURCE.ArrivalDateTime,
                SOURCE.AircraftID,
                SOURCE.FlightCapacity,
                SOURCE.TotalCost
            EXCEPT
            SELECT
                TARGET.DepartureAirportID,
                TARGET.DestinationAirportID,
                TARGET.DistanceKM,
                TARGET.DepartureDateTime,
                TARGET.ArrivalDateTime,
                TARGET.AircraftID,
                TARGET.FlightCapacity,
                TARGET.TotalCost
        ) THEN
            UPDATE SET
                TARGET.DepartureAirportID             = SOURCE.DepartureAirportID,
                TARGET.DestinationAirportID           = SOURCE.DestinationAirportID,
                TARGET.DistanceKM                     = SOURCE.DistanceKM,
                TARGET.DepartureDateTime             = SOURCE.DepartureDateTime,
                TARGET.ArrivalDateTime               = SOURCE.ArrivalDateTime,
                TARGET.AircraftID                    = SOURCE.AircraftID,
                TARGET.FlightCapacity                = SOURCE.FlightCapacity,
                TARGET.TotalCost                     = SOURCE.TotalCost,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

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
            ) VALUES (
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
            );

        SET @RowsAffected = @@ROWCOUNT;

        UPDATE [SA].[ETL_Log]
        SET
            ChangeDescription = CONCAT('Merge complete: rows affected=', @RowsAffected),
            RowsAffected      = @RowsAffected,
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Success'
        WHERE LogID = @LogID;

    END TRY
    BEGIN CATCH
        UPDATE [SA].[ETL_Log]
        SET
            ChangeDescription = 'Merge failed',
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Error',
            Message           = ERROR_MESSAGE()
        WHERE LogID = @LogID;
        THROW;
    END CATCH
END;
GO
