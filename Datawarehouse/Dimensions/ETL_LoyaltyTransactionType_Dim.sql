CREATE OR ALTER PROCEDURE [DW].[ETL_LoyaltyTransactionType_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
    @LastRunTime   DATETIME2(3),
    @RowsInserted  INT,
    @LogID         BIGINT;

  -- 1) Assume fatal: insert initial log
  INSERT INTO DW.ETL_Log (
    ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
  ) VALUES (
    'ETL_LoyaltyTransactionType_Dim',
    'DimLoyaltyTransactionType',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Determine last successful run time
    SELECT
      @LastRunTime = COALESCE(
        MAX(ActionTime),
        '1900-01-01'
      )
    FROM DW.ETL_Log
    WHERE ProcedureName = 'ETL_LoyaltyTransactionType_Dim'
      AND Status = 'Success';

    -- 3) Truncate staging
    TRUNCATE TABLE [DW].[Temp_LoyaltyTransactionType_table];

    -- 4) Populate staging with new types
    INSERT INTO [DW].[Temp_LoyaltyTransactionType_table] (
      TransactionTypeName
    )
    SELECT DISTINCT pt.TransactionType
    FROM SA.PointsTransaction AS pt
    WHERE pt.StagingLastUpdateTimestampUTC > @LastRunTime;

    -- 5) Insert any new types into dimension with surrogate keys
    INSERT INTO DW.DimLoyaltyTransactionType (
      TransactionTypeKey,
      TransactionTypeName
    )
    SELECT
      ISNULL(MAX(d.TransactionTypeKey), 0)
        + ROW_NUMBER() OVER (ORDER BY t.TransactionTypeName),
      t.TransactionTypeName
    FROM DW.Temp_LoyaltyTransactionType_table AS t
    LEFT JOIN DW.DimLoyaltyTransactionType AS d
      ON d.TransactionTypeName = t.TransactionTypeName
    WHERE d.TransactionTypeName IS NULL
    GROUP BY t.TransactionTypeName;
    SET @RowsInserted = @@ROWCOUNT;

    -- 6) Update log entry to Success
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = CONCAT(
        'Incremental load complete: inserted=', @RowsInserted
      ),
      RowsAffected      = @RowsInserted,
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Success'
    WHERE LogID = @LogID;

  END TRY
  BEGIN CATCH
    DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
    -- 7) Update log entry to Error
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Incremental load failed',
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO