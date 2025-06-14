CREATE OR ALTER PROCEDURE [DW].[Initial_Airline_Dim]
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted INT,
    @LogID        BIGINT;

  INSERT INTO DW.ETL_Log (...)
  VALUES ('Initial_Airline_Dim','DimAirline', ...,'Fatal');
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    INSERT INTO DW.DimAirline (
      AirlineKey, Name, Country, FoundedYear,
      FleetSize, Website,
      Current_IATA_Code, Previous_IATA_Code, IATA_Code_Changed_Date,
      EffectiveFrom, EffectiveTo, FleetSizeIsCurrent
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
      a.IATA_Code_Changed_Date,
      @StartTime,
      NULL,
      1
    FROM SA.Airline AS a
    WHERE NOT EXISTS (
      SELECT 1
      FROM DW.DimAirline AS d
      WHERE d.AirlineKey = a.AirlineID
    );
    SET @RowsInserted = @@ROWCOUNT;

    UPDATE DW.ETL_Log
    SET ChangeDescription = 'Initial full load complete',
        RowsAffected      = @RowsInserted,
        DurationSec       = DATEDIFF(SECOND,@StartTime,SYSUTCDATETIME()),
        Status            = 'Success'
    WHERE LogID = @LogID;

  END TRY
  BEGIN CATCH
    UPDATE DW.ETL_Log ... SET Status='Error', Message=ERROR_MESSAGE() WHERE LogID=@LogID;
    THROW;
  END CATCH
END;
GO
