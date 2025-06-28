CREATE OR ALTER PROCEDURE [SA].[ETL_TravelClass]
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
        'ETL_TravelClass',
        'Source.TravelClass',
        'SA.TravelClass',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        MERGE [SA].[TravelClass] AS TARGET
        USING [Source].[TravelClass] AS SOURCE
          ON TARGET.TravelClassID = SOURCE.TravelClassID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.ClassName,
                SOURCE.Capacity,
                SOURCE.BaseCost
            EXCEPT
            SELECT
                TARGET.ClassName,
                TARGET.Capacity,
                TARGET.BaseCost
        ) THEN
            UPDATE SET
                TARGET.ClassName                    = NULLIF(LTRIM(RTRIM(SOURCE.ClassName)), ''),
                TARGET.Capacity                     = SOURCE.Capacity,
                TARGET.BaseCost                     = SOURCE.BaseCost,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                TravelClassID,
                ClassName,
                Capacity,
                BaseCost,
                StagingLoadTimestampUTC,
                SourceSystem
            )
            VALUES (
                SOURCE.TravelClassID,
                NULLIF(LTRIM(RTRIM(SOURCE.ClassName)), ''),
                SOURCE.Capacity,
                SOURCE.BaseCost,
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
