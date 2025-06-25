CREATE OR ALTER PROCEDURE [SA].[ETL_Person]
AS
BEGIN
	MERGE [SA].[Person] AS TARGET  -- Corrected table name to match previous example
        USING [Source].[Person] AS SOURCE
        ON (TARGET.PersonID = SOURCE.PersonID)

        -- Action for existing records that have changed
        WHEN MATCHED AND EXISTS (
            SELECT SOURCE.NatCode, SOURCE.Name, SOURCE.Phone, SOURCE.Email, SOURCE.Address, SOURCE.City, SOURCE.Country, SOURCE.DateOfBirth, SOURCE.Gender, SOURCE.PostalCode
            EXCEPT
            SELECT TARGET.NatCode, TARGET.Name, TARGET.Phone, TARGET.Email, TARGET.Address, TARGET.City, TARGET.Country, TARGET.DateOfBirth, TARGET.Gender, TARGET.PostalCode
        ) THEN
            UPDATE SET
                TARGET.NatCode = SOURCE.NatCode,
                TARGET.Name = NULLIF(TRIM(SOURCE.Name), ''),
                TARGET.Phone = NULLIF(TRIM(SOURCE.Phone), ''),
                TARGET.Email = NULLIF(TRIM(SOURCE.Email), ''),
                TARGET.Address = NULLIF(TRIM(SOURCE.Address), ''),
                TARGET.City = NULLIF(TRIM(SOURCE.City), ''),
                TARGET.Country = NULLIF(TRIM(SOURCE.Country), ''),
                TARGET.DateOfBirth = SOURCE.DateOfBirth,
                TARGET.Gender = NULLIF(TRIM(SOURCE.Gender), ''),
                TARGET.PostalCode = NULLIF(TRIM(SOURCE.PostalCode), ''),
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT(
                PersonID, NatCode, Name, Phone, Email, Address, City, Country,
                DateOfBirth, Gender, PostalCode,StagingLoadTimestampUTC,
                SourceSystem
            )
            VALUES (
                SOURCE.PersonID,
                SOURCE.NatCode,
                NULLIF(TRIM(SOURCE.Name), ''),
                NULLIF(TRIM(SOURCE.Phone), ''),
                NULLIF(TRIM(SOURCE.Email), ''),
                NULLIF(TRIM(SOURCE.Address), ''),
                NULLIF(TRIM(SOURCE.City), ''),
                NULLIF(TRIM(SOURCE.Country), ''),
                SOURCE.DateOfBirth,
                NULLIF(TRIM(SOURCE.Gender), ''),
                NULLIF(TRIM(SOURCE.PostalCode), ''),
                GETUTCDATE(),
                'OperationalDB'
            );
END
