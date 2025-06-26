CREATE OR ALTER PROCEDURE [DW].[ETL_LoyaltyTransactionType_Dim]
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
    'ETL_LoyaltyTransactionType_Dim',
    'DimLoyaltyTransactionType',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2. Get last successful run time
    SELECT
      @LastRunTime = COALESCE(MAX(ActionTime), '1900-01-01')
    FROM DW.ETL_Log
    WHERE ProcedureName = 'ETL_LoyaltyTransactionType_Dim'
      AND Status = 'Success';

    -- 3. Update existing types (Type 1: update changed names)
    UPDATE d
    SET d.TypeName = s.TypeName
    FROM DW.DimLoyaltyTransactionType d
    INNER JOIN SA.LoyaltyTransactionType s
      ON d.LoyaltyTransactionTypeID = s.LoyaltyTransactionTypeID
    WHERE s.StagingLastUpdateTimestampUTC > @LastRunTime
      AND ISNULL(d.TypeName, '') <> ISNULL(s.TypeName, '');
    SET @RowsUpdated = @@ROWCOUNT;

    -- 4. Insert new types
    INSERT INTO DW.DimLoyaltyTransactionType (
      LoyaltyTransactionTypeID,
      TypeName
    )
    SELECT
      s.LoyaltyTransactionTypeID,
      s.TypeName
    FROM SA.LoyaltyTransactionType s
    LEFT JOIN DW.DimLoyaltyTransactionType d
      ON d.LoyaltyTransactionTypeID = s.LoyaltyTransactionTypeID
    WHERE d.LoyaltyTransactionTypeID IS NULL
      AND s.StagingLastUpdateTimestampUTC > @LastRunTime;
    SET @RowsInserted = @@ROWCOUNT;

    -- 5. Mark log as success
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = CONCAT(
        'Incremental load complete: updated=', @RowsUpdated,
        ', inserted=', @RowsInserted
      ),
      RowsAffected = @RowsUpdated + @RowsInserted,
      DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status = 'Success'
    WHERE LogID = @LogID;

  END TRY
  BEGIN CATCH
    DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
    -- 6. Mark log as error
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Incremental load failed',
      DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status = 'Error',
      Message = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO
