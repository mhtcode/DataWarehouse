CREATE OR ALTER PROCEDURE [SA].[ETL_Technician]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
        @RowsAffected INT,
        @LogID        BIGINT;

    -- 1) Insert initial log entry (assume fatal until completion)
    INSERT INTO [SA].[ETL_Log] (
        ProcedureName,
        SourceTable,
        TargetTable,
        ChangeDescription,
        ActionTime,
        Status
    ) VALUES (
        'ETL_Technician',
        'Source.Technician',
        'SA.Technician',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2) MERGE operation: insert/update [SA].[Technician] from [Source].[Technician]
        MERGE [SA].[Technician] AS TARGET
        USING [Source].[Technician] AS SOURCE
          ON TARGET.TechnicianID = SOURCE.TechnicianID

        -- UPDATE if any mapped column is different
        WHEN MATCHED AND EXISTS (
            SELECT 
                SOURCE.PersonID,
                SOURCE.Specialty
            EXCEPT
            SELECT 
                TARGET.PersonID,
                TARGET.Specialty
        ) THEN
            UPDATE SET
                TARGET.PersonID = SOURCE.PersonID,
                TARGET.Specialty = NULLIF(TRIM(SOURCE.Specialty), ''),
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE(),
                TARGET.SourceSystem = 'OperationalDB'

        -- INSERT new records
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                TechnicianID,
                PersonID,
                Specialty,
                StagingLoadTimestampUTC,
                SourceSystem
            ) VALUES (
                SOURCE.TechnicianID,
                SOURCE.PersonID,
                NULLIF(TRIM(SOURCE.Specialty), ''),
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
