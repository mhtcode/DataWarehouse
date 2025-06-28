CREATE OR ALTER PROCEDURE [SA].[ETL_MaintenanceLocation]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
        @RowsAffected INT,
        @LogID        BIGINT;

    INSERT INTO [SA].[ETL_Log] (
        ProcedureName,
        SourceTable,
        TargetTable,
        ChangeDescription,
        ActionTime,
        Status
    ) VALUES (
        'ETL_MaintenanceLocation',
        'Source.MaintenanceLocation',
        'SA.MaintenanceLocation',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        MERGE [SA].[MaintenanceLocation] AS TARGET
        USING [Source].[MaintenanceLocation] AS SOURCE
          ON TARGET.LocationID = SOURCE.LocationID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.Name, SOURCE.City, SOURCE.Country, SOURCE.InhouseFlag
            EXCEPT
            SELECT
                TARGET.Name, TARGET.City, TARGET.Country, TARGET.InhouseFlag
        ) THEN
            UPDATE SET
                TARGET.Name                         = SOURCE.Name,
                TARGET.City                         = SOURCE.City,
                TARGET.Country                      = SOURCE.Country,
                TARGET.InhouseFlag                  = SOURCE.InhouseFlag,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                LocationID,
                Name,
                City,
                Country,
                InhouseFlag,
                StagingLoadTimestampUTC,
                SourceSystem
            ) VALUES (
                SOURCE.LocationID,
                SOURCE.Name,
                SOURCE.City,
                SOURCE.Country,
                SOURCE.InhouseFlag,
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
