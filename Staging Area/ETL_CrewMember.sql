CREATE OR ALTER PROCEDURE [SA].[ETL_CrewMember]
AS
BEGIN
    MERGE [SA].[CrewMember] AS TARGET
    USING [Source].[CrewMember] AS SOURCE
    ON (TARGET.CrewMemberID = SOURCE.CrewMemberID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.PersonID, SOURCE.Role
        EXCEPT
        SELECT TARGET.PersonID, TARGET.Role
    ) THEN
        UPDATE SET
            TARGET.PersonID = SOURCE.PersonID,
            TARGET.Role = NULLIF(TRIM(SOURCE.Role), ''),
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            CrewMemberID,
            PersonID,
            Role,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.CrewMemberID,
            SOURCE.PersonID,
            NULLIF(TRIM(SOURCE.Role), ''),
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon

END