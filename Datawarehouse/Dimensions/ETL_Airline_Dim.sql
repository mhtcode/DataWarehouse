CREATE OR ALTER PROCEDURE [DW].[ETL_Airline_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @LastRunTime  DATETIME2(3),
    @RowsUpdated  INT,
    @RowsInserted INT,
    @LogID        BIGINT;

  -- 1) Assume fatal: insert initial log entry
  INSERT INTO [DW].[ETL_Log] (
    ProcedureName,
    TargetTable,
    ChangeDescription,
    ActionTime,
    Status
  ) VALUES (
    'ETL_Airline_Dim',
    'DimAirline',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Determine last successful run time
    SELECT
      @LastRunTime = COALESCE(MAX(ActionTime), '1900-01-01')
    FROM [DW].[ETL_Log]
    WHERE ProcedureName = 'ETL_Airline_Dim'
      AND Status = 'Success';

    -- 3) Truncate staging
    TRUNCATE TABLE [DW].[Temp_Airline_table];

    -- 4) Populate staging with changed/new airlines
    INSERT INTO [DW].[Temp_Airline_table] (
      AirlineID,
      Name,
      Country,
      FoundedYear,
      FleetSize,
      Website,
      Current_IATA_Code,
      Previous_IATA_Code,
      IATA_Code_Changed_Date
    )
    SELECT
      a.AirlineID,
      a.Name,
      a.Country,
      YEAR(a.FoundedDate),
      a.FleetSize,
      a.Website,
      a.Current_IATA_Code,
      a.Previous_IATA_Code,
      a.IATA_Code_Changed_Date
    FROM [SA].[Airline] AS a
    WHERE a.StagingLastUpdateTimestampUTC > @LastRunTime;
    SET @RowsInserted = @@ROWCOUNT;

    -- 5) Update existing rows when any source column changed
    UPDATE d
    SET
      d.Name                   = t.Name,
      d.Country                = t.Country,
      d.FoundedYear            = t.FoundedYear,
      d.FleetSize              = t.FleetSize,
      d.Website                = t.Website,
      d.Current_IATA_Code      = t.Current_IATA_Code,
      d.Previous_IATA_Code     = t.Previous_IATA_Code,
      d.IATA_Code_Changed_Date = t.IATA_Code_Changed_Date
    FROM [DW].[DimAirline] AS d
    JOIN [DW].[Temp_Airline_table] AS t
      ON d.AirlineKey = t.AirlineID
    WHERE EXISTS (
      SELECT
        t.Name, t.Country, t.FoundedYear, t.FleetSize, t.Website,
        t.Current_IATA_Code, t.Previous_IATA_Code, t.IATA_Code_Changed_Date
      EXCEPT
      SELECT
        d.Name, d.Country, d.FoundedYear, d.FleetSize, d.Website,
        d.Current_IATA_Code, d.Previous_IATA_Code, d.IATA_Code_Changed_Date
    );
    SET @RowsUpdated = @@ROWCOUNT;

    -- 6) Insert new airlines
    INSERT INTO [DW].[DimAirline] (
      AirlineKey,
      Name,
      Country,
      FoundedYear,
      FleetSize,
      Website,
      Current_IATA_Code,
      Previous_IATA_Code,
      IATA_Code_Changed_Date
    )
    SELECT
      t.AirlineID,
      t.Name,
      t.Country,
      t.FoundedYear,
      t.FleetSize,
      t.Website,
      t.Current_IATA_Code,
      t.Previous_IATA_Code,
      t.IATA_Code_Changed_Date
    FROM [DW].[Temp_Airline_table] AS t
    WHERE NOT EXISTS (
      SELECT 1
      FROM [DW].[DimAirline] AS d
      WHERE d.AirlineKey = t.AirlineID
    );
    SET @RowsInserted = @@ROWCOUNT;

    -- 7) Update log to Success
    UPDATE [DW].[ETL_Log]
    SET
      ChangeDescription = CONCAT(
        'Incremental load complete: updated=', @RowsUpdated,
        ', inserted=', @RowsInserted
      ),
      RowsAffected = @RowsUpdated + @RowsInserted,
      DurationSec  = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status       = 'Success'
    WHERE LogID = @LogID;

  END TRY
  BEGIN CATCH
    -- 8) Update log to Error
    UPDATE [DW].[ETL_Log]
    SET
      ChangeDescription = 'Incremental load failed',
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = ERROR_MESSAGE()
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO
