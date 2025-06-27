CREATE OR ALTER PROCEDURE [SA].[ETL_SeatDetail]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
        @RowsAffected  INT,
        @LogID         BIGINT;

    -- 1) Assume fatal: insert initial log entry
    INSERT INTO [SA].[ETL_Log] (
        ProcedureName,
        SourceTable,
        TargetTable,
        ChangeDescription,
        ActionTime,
        Status
    ) VALUES (
        'ETL_SeatDetail',
        'Source.SeatDetail',
        'SA.SeatDetail',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2) Perform the merge
        MERGE [SA].[SeatDetail] AS TARGET
        USING [Source].[SeatDetail] AS SOURCE
          ON TARGET.SeatDetailID = SOURCE.SeatDetailID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.AircraftID,
                SOURCE.SeatNo,
                SOURCE.SeatType,
                SOURCE.TravelClassID,
                SOURCE.ReservationID
            EXCEPT
            SELECT
                TARGET.AircraftID,
                TARGET.SeatNo,
                TARGET.SeatType,
                TARGET.TravelClassID,
                TARGET.ReservationID
        ) THEN
            UPDATE SET
                TARGET.AircraftID                    = SOURCE.AircraftID,
                TARGET.SeatNo                        = SOURCE.SeatNo,
                TARGET.SeatType                      = NULLIF(TRIM(SOURCE.SeatType), ''),
                TARGET.TravelClassID                 = SOURCE.TravelClassID,
                TARGET.ReservationID                 = SOURCE.ReservationID,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

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
            ) VALUES (
                SOURCE.SeatDetailID,
                SOURCE.AircraftID,
                SOURCE.SeatNo,
                NULLIF(TRIM(SOURCE.SeatType), ''),
                SOURCE.TravelClassID,
                SOURCE.ReservationID,
                GETUTCDATE(),
                'OperationalDB'
            );

        SET @RowsAffected = @@ROWCOUNT;

        -- 3) Update log to Success
        UPDATE [SA].[ETL_Log]
        SET
            ChangeDescription = CONCAT('Merge complete: rows affected=', @RowsAffected),
            RowsAffected      = @RowsAffected,
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Success'
        WHERE LogID = @LogID;

    END TRY
    BEGIN CATCH
        -- 4) Update log to Error
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
