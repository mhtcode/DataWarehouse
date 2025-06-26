CREATE OR ALTER PROCEDURE [DW].[ETL_Airline_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
    @LastRunTime   DATETIME2(3),
    @RowsUpdated   INT = 0,
    @RowsInserted  INT = 0,
    @LogID         BIGINT;

  -- 1. Insert initial (fatal) log entry
  INSERT INTO DW.ETL_Log (
    ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
  ) VALUES (
    'ETL_Airline_Dim',
    'DimAirline',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2. Determine last successful run time
    SELECT
      @LastRunTime = COALESCE(MAX(ActionTime), '1900-01-01')
    FROM DW.ETL_Log
    WHERE ProcedureName = 'ETL_Airline_Dim'
      AND Status = 'Success';

    -- 3. Type 1 updates (simple attributes except IATA code)
    UPDATE d
    SET
      d.Name         = s.Name,
      d.Country      = s.Country,
      d.FoundedYear  = YEAR(s.FoundedDate),
      d.FleetSize    = s.FleetSize,
      d.Website      = s.Website
    FROM DW.DimAirline d
    JOIN SA.Airline s ON d.AirlineID = s.AirlineID
    WHERE
      (d.Name        <> s.Name OR
       d.Country     <> s.Country OR
       d.FoundedYear <> YEAR(s.FoundedDate) OR
       d.FleetSize   <> s.FleetSize OR
       d.Website     <> s.Website)
      AND s.StagingLastUpdateTimestampUTC > @LastRunTime;

    SET @RowsUpdated = @@ROWCOUNT;

    -- 4. Type 3 SCD logic: IATA code change
    UPDATE d
    SET
      d.Previous_IATA_Code      = d.Current_IATA_Code,
      d.Current_IATA_Code       = s.Current_IATA_Code,
      d.IATA_Code_Changed_Date  = s.StagingLastUpdateTimestampUTC
    FROM DW.DimAirline d
    JOIN SA.Airline s ON d.AirlineID = s.AirlineID
    WHERE
      ISNULL(d.Current_IATA_Code,'') <> ISNULL(s.Current_IATA_Code,'')
      AND s.StagingLastUpdateTimestampUTC > @LastRunTime;

    SET @RowsUpdated = @RowsUpdated + @@ROWCOUNT;

    -- 5. Insert new airlines
    INSERT INTO DW.DimAirline (
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
      s.AirlineID,
      s.Name,
      s.Country,
      YEAR(s.FoundedDate),
      s.FleetSize,
      s.Website,
      s.Current_IATA_Code,
      NULL,
      NULL
    FROM SA.Airline s
    LEFT JOIN DW.DimAirline d ON s.AirlineID = d.AirlineID
    WHERE d.AirlineID IS NULL
      AND s.StagingLastUpdateTimestampUTC > @LastRunTime;

    SET @RowsInserted = @@ROWCOUNT;

    -- 6. Update log entry to Success
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = CONCAT(
        'Incremental load complete: updated=', @RowsUpdated,
        ', inserted=', @RowsInserted
      ),
      RowsAffected      = @RowsUpdated + @RowsInserted,
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Success'
    WHERE LogID = @LogID;

  END TRY
  BEGIN CATCH
    DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
    -- 7. Update log entry to Error
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Incremental load failed',
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END
GO
