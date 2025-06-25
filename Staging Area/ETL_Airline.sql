CREATE OR ALTER PROCEDURE [SA].[ETL_Airline]
AS
BEGIN
    MERGE [SA].[Airline] AS TARGET
    USING [Source].[Airline] AS SOURCE
      ON TARGET.AirlineID = SOURCE.AirlineID

    -- 1) UPDATE existing rows when *any* source column changed (now including IATA columns)
    WHEN MATCHED AND EXISTS (
      SELECT 
        SOURCE.Name, SOURCE.Country, SOURCE.FoundedDate, 
        SOURCE.HeadquartersNumber, SOURCE.FleetSize, SOURCE.Website,
        SOURCE.Current_IATA_Code, SOURCE.Previous_IATA_Code, SOURCE.IATA_Code_Changed_Date
      EXCEPT
      SELECT 
        TARGET.Name, TARGET.Country, TARGET.FoundedDate, 
        TARGET.HeadquartersNumber, TARGET.FleetSize, TARGET.Website,
        TARGET.Current_IATA_Code, TARGET.Previous_IATA_Code, TARGET.IATA_Code_Changed_Date
    )
    THEN
      UPDATE SET
        TARGET.Name                     = NULLIF(TRIM(SOURCE.Name), ''),
        TARGET.Country                  = NULLIF(TRIM(SOURCE.Country), ''),
        TARGET.FoundedDate              = SOURCE.FoundedDate,
        TARGET.HeadquartersNumber       = NULLIF(TRIM(SOURCE.HeadquartersNumber), ''),
        TARGET.FleetSize                = SOURCE.FleetSize,
        TARGET.Website                  = NULLIF(TRIM(SOURCE.Website), ''),
        TARGET.Current_IATA_Code        = SOURCE.Current_IATA_Code,
        TARGET.Previous_IATA_Code       = SOURCE.Previous_IATA_Code,
        TARGET.IATA_Code_Changed_Date   = SOURCE.IATA_Code_Changed_Date,
        TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- 2) INSERT brand-new airlines, including IATA columns
    WHEN NOT MATCHED BY TARGET
    THEN
      INSERT (
        AirlineID, Name, Country, FoundedDate,
        HeadquartersNumber, FleetSize, Website,
        Current_IATA_Code, Previous_IATA_Code, IATA_Code_Changed_Date,
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
        SOURCE.Previous_IATA_Code,
        SOURCE.IATA_Code_Changed_Date,
        GETUTCDATE(),
        'OperationalDB'
      );

END;
GO
