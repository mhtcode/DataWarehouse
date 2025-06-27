CREATE OR ALTER PROCEDURE [SA].[ETL_CrewMember]
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
        'ETL_CrewMember',
        'Source.CrewMember',
        'SA.CrewMember',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2) Perform the merge
        MERGE [SA].[CrewMember] AS TARGET
        USING [Source].[CrewMember] AS SOURCE
          ON TARGET.CrewMemberID = SOURCE.CrewMemberID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.PersonID,
                SOURCE.Role
            EXCEPT
            SELECT
                TARGET.PersonID,
                TARGET.Role
        ) THEN
            UPDATE SET
                TARGET.PersonID                     = SOURCE.PersonID,
                TARGET.Role                         = NULLIF(TRIM(SOURCE.Role), ''),
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                CrewMemberID,
                PersonID,
                Role,
                StagingLoadTimestampUTC,
                SourceSystem
            ) VALUES (
                SOURCE.CrewMemberID,
                SOURCE.PersonID,
                NULLIF(TRIM(SOURCE.Role), ''),
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
