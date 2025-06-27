CREATE OR ALTER PROCEDURE [SA].[ETL_ServiceOffering]
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
        'ETL_ServiceOffering',
        'Source.ServiceOffering',
        'SA.ServiceOffering',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2) Perform the merge
        MERGE [SA].[ServiceOffering] AS TARGET
        USING [Source].[ServiceOffering] AS SOURCE
          ON TARGET.ServiceOfferingID = SOURCE.ServiceOfferingID

        -- Update if any significant column changed
        WHEN MATCHED AND (
                ISNULL(TARGET.TravelClassID, -1)       <> ISNULL(SOURCE.TravelClassID, -1)
             OR ISNULL(TARGET.OfferingName, '')        <> ISNULL(LTRIM(RTRIM(SOURCE.OfferingName)), '')
             OR ISNULL(TARGET.Description, '')         <> ISNULL(LTRIM(RTRIM(SOURCE.Description)), '')
             OR ISNULL(TARGET.TotalCost, -1)           <> ISNULL(SOURCE.TotalCost, -1)
        ) THEN
            UPDATE SET
                TARGET.TravelClassID                 = SOURCE.TravelClassID,
                TARGET.OfferingName                  = NULLIF(LTRIM(RTRIM(SOURCE.OfferingName)), ''),
                TARGET.Description                   = NULLIF(LTRIM(RTRIM(SOURCE.Description)), ''),
                TARGET.TotalCost                     = SOURCE.TotalCost,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE(),
                TARGET.SourceSystem                  = 'OperationalDB'

        -- Insert new records
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                ServiceOfferingID,
                TravelClassID,
                OfferingName,
                Description,
                TotalCost,
                StagingLoadTimestampUTC,
                SourceSystem
            ) VALUES (
                SOURCE.ServiceOfferingID,
                SOURCE.TravelClassID,
                NULLIF(LTRIM(RTRIM(SOURCE.OfferingName)), ''),
                NULLIF(LTRIM(RTRIM(SOURCE.Description)), ''),
                SOURCE.TotalCost,
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
