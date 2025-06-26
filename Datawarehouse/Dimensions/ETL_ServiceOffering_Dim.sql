CREATE OR ALTER PROCEDURE [DW].[ETL_ServiceOffering_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @LastRunTime  DATETIME2(3),
    @RowsUpdated  INT = 0,
    @RowsInserted INT = 0,
    @LogID        BIGINT;

  -- 1) Log start (assume fatal)
  INSERT INTO [DW].[ETL_Log] (
    ProcedureName,
    TargetTable,
    ChangeDescription,
    ActionTime,
    Status
  ) VALUES (
    'ETL_ServiceOffering_Dim',
    'DimServiceOffering',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Find last successful run time
    SELECT
      @LastRunTime = COALESCE(MAX(ActionTime), '1900-01-01')
    FROM [DW].[ETL_Log]
    WHERE ProcedureName = 'ETL_ServiceOffering_Dim'
      AND Status = 'Success';

    -- 3) Truncate staging table
    TRUNCATE TABLE [DW].[Temp_ServiceOffering_table];

    -- 4) Load changed/new ServiceOfferings into staging (with de-normalized fields)
    INSERT INTO [DW].[Temp_ServiceOffering_table] (
      ServiceOfferingID,
      OfferingName,
      Description,
      TravelClassName,
      TotalCost,
      ItemsSummary
    )
    SELECT
      so.ServiceOfferingID,
      so.OfferingName,
      so.Description,
      tc.ClassName,
      so.TotalCost,
      ISNULL(
        STUFF((
          SELECT ', ' + i.ItemName
          FROM [SA].[ServiceOfferingItem] soi
          JOIN [SA].[Item] i ON soi.ItemID = i.ItemID
          WHERE soi.ServiceOfferingID = so.ServiceOfferingID
          FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, ''), '')
      AS ItemsSummary
    FROM [SA].[ServiceOffering] so
    LEFT JOIN [SA].[TravelClass] tc ON so.TravelClassID = tc.TravelClassID
    WHERE so.StagingLastUpdateTimestampUTC > @LastRunTime
       OR EXISTS (
           SELECT 1 FROM [SA].[ServiceOfferingItem] soi
           WHERE soi.ServiceOfferingID = so.ServiceOfferingID
             AND soi.StagingLastUpdateTimestampUTC > @LastRunTime
         )
       OR EXISTS (
           SELECT 1 FROM [SA].[Item] i
           JOIN [SA].[ServiceOfferingItem] soi ON soi.ItemID = i.ItemID
           WHERE soi.ServiceOfferingID = so.ServiceOfferingID
             AND i.StagingLastUpdateTimestampUTC > @LastRunTime
         );

    -- 5) Update changed rows (SCD Type 1 overwrite)
    UPDATE d
    SET
      d.OfferingName  = t.OfferingName,
      d.Description   = t.Description,
      d.TravelClassName = t.TravelClassName,
      d.TotalCost     = t.TotalCost,
      d.ItemsSummary  = t.ItemsSummary
    FROM [DW].[DimServiceOffering] d
    JOIN [DW].[Temp_ServiceOffering_table] t
      ON d.ServiceOfferingID = t.ServiceOfferingID
    WHERE EXISTS (
      SELECT t.OfferingName, t.Description, t.TravelClassName, t.TotalCost, t.ItemsSummary
      EXCEPT
      SELECT d.OfferingName, d.Description, d.TravelClassName, d.TotalCost, d.ItemsSummary
    );
    SET @RowsUpdated = @@ROWCOUNT;

    -- 6) Insert new rows
    INSERT INTO [DW].[DimServiceOffering] (
      ServiceOfferingID,
      OfferingName,
      Description,
      TravelClassName,
      TotalCost,
      ItemsSummary
    )
    SELECT
      t.ServiceOfferingID,
      t.OfferingName,
      t.Description,
      t.TravelClassName,
      t.TotalCost,
      t.ItemsSummary
    FROM [DW].[Temp_ServiceOffering_table] t
    WHERE NOT EXISTS (
      SELECT 1 FROM [DW].[DimServiceOffering] d
      WHERE d.ServiceOfferingID = t.ServiceOfferingID
    );
    SET @RowsInserted = @@ROWCOUNT;

    -- 7) Log success
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
