CREATE OR ALTER PROCEDURE [SA].[ETL_Aircraft]
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
        'ETL_Aircraft',
        'Source.Aircraft',
        'SA.Aircraft',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2) Perform the merge
        MERGE [SA].[Aircraft] AS TARGET
        USING [Source].[Aircraft] AS SOURCE
        ON (TARGET.AircraftID = SOURCE.AircraftID)

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.Model,
                SOURCE.[Type],
                SOURCE.ManufacturerDate,
                SOURCE.Capacity,
                SOURCE.Price,
                SOURCE.AirlineID
            EXCEPT
            SELECT
                TARGET.Model,
                TARGET.[Type],
                TARGET.ManufacturerDate,
                TARGET.Capacity,
                TARGET.Price,
                TARGET.AirlineID
        ) THEN
            UPDATE SET
                TARGET.Model                          = NULLIF(TRIM(SOURCE.Model), ''),
                TARGET.[Type]                         = NULLIF(TRIM(SOURCE.[Type]), ''),
                TARGET.ManufacturerDate              = SOURCE.ManufacturerDate,
                TARGET.Capacity                      = SOURCE.Capacity,
                TARGET.Price                         = SOURCE.Price,
                TARGET.AirlineID                     = SOURCE.AirlineID,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                AircraftID,
                Model,
                [Type],
                ManufacturerDate,
                Capacity,
                Price,
                AirlineID,
                StagingLoadTimestampUTC,
                SourceSystem
            ) VALUES (
                SOURCE.AircraftID,
                NULLIF(TRIM(SOURCE.Model), ''),
                NULLIF(TRIM(SOURCE.[Type]), ''),
                SOURCE.ManufacturerDate,
                SOURCE.Capacity,
                SOURCE.Price,
                SOURCE.AirlineID,
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
