CREATE OR ALTER PROCEDURE [SA].[ETL_Airport]
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
        'ETL_Airport',
        'Source.Airport',
        'SA.Airport',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        MERGE [SA].[Airport] AS TARGET
        USING [Source].[Airport] AS SOURCE
          ON (TARGET.AirportID = SOURCE.AirportID)

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.City,
                SOURCE.Country,
                SOURCE.IATACode,
                SOURCE.ElevationMeter,
                SOURCE.TimeZone,
                SOURCE.NumberOfTerminals,
                SOURCE.AnnualPassengerTraffic,
                SOURCE.Latitude,
                SOURCE.Longitude,
                SOURCE.ManagerName
            EXCEPT
            SELECT
                TARGET.City,
                TARGET.Country,
                TARGET.IATACode,
                TARGET.ElevationMeter,
                TARGET.TimeZone,
                TARGET.NumberOfTerminals,
                TARGET.AnnualPassengerTraffic,
                TARGET.Latitude,
                TARGET.Longitude,
                TARGET.ManagerName
        ) THEN
            UPDATE SET
                TARGET.City                          = NULLIF(TRIM(SOURCE.City), ''),
                TARGET.Country                       = NULLIF(TRIM(SOURCE.Country), ''),
                TARGET.IATACode                      = NULLIF(TRIM(SOURCE.IATACode), ''),
                TARGET.ElevationMeter                = SOURCE.ElevationMeter,
                TARGET.TimeZone                      = NULLIF(TRIM(SOURCE.TimeZone), ''),
                TARGET.NumberOfTerminals             = SOURCE.NumberOfTerminals,
                TARGET.AnnualPassengerTraffic        = SOURCE.AnnualPassengerTraffic,
                TARGET.Latitude                      = SOURCE.Latitude,
                TARGET.Longitude                     = SOURCE.Longitude,
                TARGET.ManagerName                   = NULLIF(TRIM(SOURCE.ManagerName), ''),
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                AirportID,
                City,
                Country,
                IATACode,
                ElevationMeter,
                TimeZone,
                NumberOfTerminals,
                AnnualPassengerTraffic,
                Latitude,
                Longitude,
                ManagerName,
                StagingLoadTimestampUTC,
                SourceSystem
            ) VALUES (
                SOURCE.AirportID,
                NULLIF(TRIM(SOURCE.City), ''),
                NULLIF(TRIM(SOURCE.Country), ''),
                NULLIF(TRIM(SOURCE.IATACode), ''),
                SOURCE.ElevationMeter,
                NULLIF(TRIM(SOURCE.TimeZone), ''),
                SOURCE.NumberOfTerminals,
                SOURCE.AnnualPassengerTraffic,
                SOURCE.Latitude,
                SOURCE.Longitude,
                NULLIF(TRIM(SOURCE.ManagerName), ''),
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
