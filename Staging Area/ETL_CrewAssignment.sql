CREATE OR ALTER PROCEDURE [SA].[ETL_CrewAssignment]
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
        'ETL_CrewAssignment',
        'Source.CrewAssignment',
        'SA.CrewAssignment',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2) Perform the merge
        MERGE [SA].[CrewAssignment] AS TARGET
        USING [Source].[CrewAssignment] AS SOURCE
          ON TARGET.CrewAssignmentID = SOURCE.CrewAssignmentID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.FlightDetailID,
                SOURCE.CrewMemberID
            EXCEPT
            SELECT
                TARGET.FlightDetailID,
                TARGET.CrewMemberID
        ) THEN
            UPDATE SET
                TARGET.FlightDetailID               = SOURCE.FlightDetailID,
                TARGET.CrewMemberID                 = SOURCE.CrewMemberID,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                CrewAssignmentID,
                FlightDetailID,
                CrewMemberID,
                StagingLoadTimestampUTC,
                SourceSystem
            ) VALUES (
                SOURCE.CrewAssignmentID,
                SOURCE.FlightDetailID,
                SOURCE.CrewMemberID,
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
