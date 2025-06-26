CREATE OR ALTER PROCEDURE [DW].[Initial_ServiceOffering_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted INT,
    @LogID        BIGINT;

  -- 1. Insert initial log entry
  INSERT INTO DW.ETL_Log (
    ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
  ) VALUES (
    'Initial_ServiceOffering_Dim',
    'DimServiceOffering',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2. Clean dimension table
    TRUNCATE TABLE [DW].[DimServiceOffering];

    -- 3. Insert all rows (de-normalized, star-style)
    INSERT INTO [DW].[DimServiceOffering] (
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
      tc.ClassName,  -- Flattened TravelClass name
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
    LEFT JOIN [SA].[TravelClass] tc
      ON so.TravelClassID = tc.TravelClassID;

    SET @RowsInserted = @@ROWCOUNT;

    -- 4. Mark log entry as success
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Initial full load complete',
      RowsAffected      = @RowsInserted,
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Success'
    WHERE LogID = @LogID;

  END TRY
  BEGIN CATCH
    DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
    -- 5. Mark log entry as error
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Initial full load failed',
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END
GO