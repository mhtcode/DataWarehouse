CREATE OR ALTER PROCEDURE [SA].[ETL_Airline]
AS
BEGIN
    MERGE [SA].[Airline] AS TARGET
    USING [Source].[Airline] AS SOURCE
      ON TARGET.AirlineID = SOURCE.AirlineID

    -- 1) UPDATE existing rows when *any* source column changed (only current IATA code included)
    WHEN MATCHED AND EXISTS (
      SELECT 
        SOURCE.Name, SOURCE.Country, SOURCE.FoundedDate, 
        SOURCE.HeadquartersNumber, SOURCE.FleetSize, SOURCE.Website,
        SOURCE.Current_IATA_Code
      EXCEPT
      SELECT 
        TARGET.Name, TARGET.Country, TARGET.FoundedDate, 
        TARGET.HeadquartersNumber, TARGET.FleetSize, TARGET.Website,
        TARGET.Current_IATA_Code
    )
    THEN
      UPDATE SET
        TARGET.Name                       = NULLIF(TRIM(SOURCE.Name), ''),
        TARGET.Country                    = NULLIF(TRIM(SOURCE.Country), ''),
        TARGET.FoundedDate                = SOURCE.FoundedDate,
        TARGET.HeadquartersNumber         = NULLIF(TRIM(SOURCE.HeadquartersNumber), ''),
        TARGET.FleetSize                  = SOURCE.FleetSize,
        TARGET.Website                    = NULLIF(TRIM(SOURCE.Website), ''),
        TARGET.Current_IATA_Code          = SOURCE.Current_IATA_Code,
        TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- 2) INSERT brand-new airlines, only including current IATA code
    WHEN NOT MATCHED BY TARGET
    THEN
      INSERT (
        AirlineID, Name, Country, FoundedDate,
        HeadquartersNumber, FleetSize, Website,
        Current_IATA_Code,
        StagingLoadTimestampUTC, SourceSystem
      )
      VALUES (
        SOURCE.AirlineID,
        NULLIF(TRIM(SOURCE.Name), ''),
        NULLIF(TRIM(SOURCE.Country), ''),
        SOURCE.FoundedDate,
        NULLIF(TRIM(SOURCE.HeadquartersNumber), ''),
        SOURCE.FleetSize,
        NULLIF(TRIM(SOURCE.Website), ''),
        SOURCE.Current_IATA_Code,
        GETUTCDATE(),
        'OperationalDB'
      );

END;
GO
