CREATE OR ALTER PROCEDURE [DW].[ETL_Airline_Dim]
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE
    @StartTime       DATETIME2(3) = SYSUTCDATETIME(),
    @LastRunTime     DATETIME2(3),
    @RowsExpired     INT,
    @RowsInserted    INT,
    @RowsIATAUpdated INT,
    @LogID           BIGINT;

  INSERT INTO DW.ETL_Log (...)
  VALUES ('ETL_Airline_Dim','DimAirline', ...,'Fatal');
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- determine last success
    SELECT @LastRunTime = COALESCE(MAX(ActionTime),'1900-01-01')
    FROM DW.ETL_Log
    WHERE ProcedureName = 'ETL_Airline_Dim' AND Status = 'Success';

    -- refresh staging
    TRUNCATE TABLE DW.Temp_Airline_table;

    -- 1) populate temp with *all* changed/ new rows (now including IATA columns)
    INSERT INTO DW.Temp_Airline_table (
      AirlineID, Name, Country, FoundedYear,
      FleetSize, Website,
      Current_IATA_Code, Previous_IATA_Code, IATA_Code_Changed_Date
    )
    SELECT
      a.AirlineID,
      a.Name,
      a.Country,
      a.FoundedYear,
      a.FleetSize,
      a.Website,
      a.Current_IATA_Code,
      a.Previous_IATA_Code,
      a.IATA_Code_Changed_Date
    FROM SA.Airline AS a
    WHERE a.StagingLastUpdateTimestampUTC > @LastRunTime;

    -- 2) expire old SCD2 (fleet size) rows
    UPDATE d
    SET
      d.FleetSizeIsCurrent = 0,
      d.EffectiveTo        = @StartTime
    FROM DW.DimAirline AS d
    JOIN DW.Temp_Airline_table AS t
      ON d.AirlineKey = t.AirlineID
    WHERE d.FleetSizeIsCurrent = 1
      AND (
        ISNULL(d.Name,'')       <> ISNULL(t.Name,'') OR
        ISNULL(d.Country,'')    <> ISNULL(t.Country,'') OR
        ISNULL(d.FoundedYear,0) <> ISNULL(t.FoundedYear,0) OR
        ISNULL(d.FleetSize,0)   <> ISNULL(t.FleetSize,0) OR
        ISNULL(d.Website,'')    <> ISNULL(t.Website,'')
      );
    SET @RowsExpired = @@ROWCOUNT;

    -- 3) insert new SCD2 versions
    INSERT INTO DW.DimAirline (
      AirlineKey, Name, Country, FoundedYear,
      FleetSize, Website,
      EffectiveFrom, EffectiveTo, FleetSizeIsCurrent
    )
    SELECT
      t.AirlineID,
      t.Name,
      t.Country,
      t.FoundedYear,
      t.FleetSize,
      t.Website,
      @StartTime,
      NULL,
      1
    FROM DW.Temp_Airline_table AS t;
    SET @RowsInserted = @@ROWCOUNT;

    -- 4) in-place update for SCD3 on IATA codes
    UPDATE d
    SET
      d.Current_IATA_Code      = t.Current_IATA_Code,
      d.Previous_IATA_Code     = t.Previous_IATA_Code,
      d.IATA_Code_Changed_Date = t.IATA_Code_Changed_Date
    FROM DW.DimAirline AS d
    JOIN DW.Temp_Airline_table AS t
      ON d.AirlineKey = t.AirlineID
    WHERE d.FleetSizeIsCurrent = 1
      AND (
        ISNULL(d.Current_IATA_Code,'') <> ISNULL(t.Current_IATA_Code,'')
        OR ISNULL(d.Previous_IATA_Code,'') <> ISNULL(t.Previous_IATA_Code,'')
        OR ISNULL(d.IATA_Code_Changed_Date,'1900-01-01') 
             <> ISNULL(t.IATA_Code_Changed_Date,'1900-01-01')
      );
    SET @RowsIATAUpdated = @@ROWCOUNT;

    -- 5) finalize log
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = CONCAT(
        'Inc load complete: expired=', @RowsExpired,
        ', inserted=', @RowsInserted,
        ', IATA-updates=', @RowsIATAUpdated
      ),
      RowsAffected = @RowsExpired + @RowsInserted + @RowsIATAUpdated,
      DurationSec  = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status       = 'Success'
    WHERE LogID = @LogID;

  END TRY
  BEGIN CATCH
    UPDATE DW.ETL_Log
    SET ChangeDescription = 'Inc load failed',
        DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
        Status            = 'Error',
        Message           = ERROR_MESSAGE()
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO
