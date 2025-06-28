CREATE OR ALTER PROCEDURE [SA].[ETL_PartReplacement]
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
        'ETL_PartReplacement',
        'Source.PartReplacement',
        'SA.PartReplacement',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        MERGE [SA].[PartReplacement] AS TARGET
        USING [Source].[PartReplacement] AS SOURCE
          ON TARGET.PartReplacementID = SOURCE.PartReplacementID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.AircraftID, SOURCE.PartID, SOURCE.LocationID, SOURCE.ReplacementDate,
                SOURCE.Quantity, SOURCE.PartCost, SOURCE.TotalPartCost
            EXCEPT
            SELECT
                TARGET.AircraftID, TARGET.PartID, TARGET.LocationID, TARGET.ReplacementDate,
                TARGET.Quantity, TARGET.PartCost, TARGET.TotalPartCost
        ) THEN
            UPDATE SET
                TARGET.AircraftID = SOURCE.AircraftID,
                TARGET.PartID = SOURCE.PartID,
                TARGET.LocationID = SOURCE.LocationID,
                TARGET.ReplacementDate = SOURCE.ReplacementDate,
                TARGET.Quantity = SOURCE.Quantity,
                TARGET.PartCost = SOURCE.PartCost,
                TARGET.TotalPartCost = SOURCE.TotalPartCost,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                PartReplacementID, AircraftID, PartID, LocationID, ReplacementDate,
                Quantity, PartCost, TotalPartCost, StagingLoadTimestampUTC, SourceSystem
            ) VALUES (
                SOURCE.PartReplacementID, SOURCE.AircraftID, SOURCE.PartID, SOURCE.LocationID, SOURCE.ReplacementDate,
                SOURCE.Quantity, SOURCE.PartCost, SOURCE.TotalPartCost, GETUTCDATE(), 'OperationalDB'
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
