CREATE OR ALTER PROCEDURE [SA].[ETL_CrewAssignment]
AS
BEGIN
    MERGE [SA].[CrewAssignment] AS TARGET
    USING [Source].[CrewAssignment] AS SOURCE
    ON (TARGET.CrewAssignmentID = SOURCE.CrewAssignmentID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.FlightDetailID, SOURCE.CrewMemberID
        EXCEPT
        SELECT TARGET.FlightDetailID, TARGET.CrewMemberID
    ) THEN
        UPDATE SET
            TARGET.FlightDetailID = SOURCE.FlightDetailID,
            TARGET.CrewMemberID = SOURCE.CrewMemberID,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            CrewAssignmentID,
            FlightDetailID,
            CrewMemberID,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.CrewAssignmentID,
            SOURCE.FlightDetailID,
            SOURCE.CrewMemberID,
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon

END