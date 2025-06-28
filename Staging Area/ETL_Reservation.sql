CREATE OR ALTER PROCEDURE [SA].[ETL_Reservation]
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
    )
    VALUES (
        'ETL_Reservation',
        'Source.Reservation',
        'SA.Reservation',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        MERGE [SA].[Reservation] AS TARGET
        USING [Source].[Reservation] AS SOURCE
          ON TARGET.ReservationID = SOURCE.ReservationID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.PassengerID,
                SOURCE.FlightDetailID,
                SOURCE.ReservationDate,
                SOURCE.SeatDetailID,
                SOURCE.Status
            EXCEPT
            SELECT
                TARGET.PassengerID,
                TARGET.FlightDetailID,
                TARGET.ReservationDate,
                TARGET.SeatDetailID,
                TARGET.Status
        ) THEN
            UPDATE SET
                TARGET.PassengerID                   = SOURCE.PassengerID,
                TARGET.FlightDetailID                = SOURCE.FlightDetailID,
                TARGET.ReservationDate               = SOURCE.ReservationDate,
                TARGET.SeatDetailID                  = SOURCE.SeatDetailID,
                TARGET.Status                        = NULLIF(TRIM(SOURCE.Status), ''),
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

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
