CREATE OR ALTER PROCEDURE [DW].[Initial_LoyaltyTier_Dim]
AS
BEGIN
  SET NOCOUNT ON;
  
  DECLARE
    @StartTime      DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted   INT,
    @LogID          BIGINT;

  -- 1) Assume fatal: insert initial log entry
  INSERT INTO DW.ETL_Log (
    ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
  ) VALUES (
    'Initial_LoyaltyTier_Dim',
    'DimLoyaltyTier',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Insert all loyalty tiers into dimension
    INSERT INTO DW.DimLoyaltyTier (
      LoyaltyTierKey, Name, MinPoints, Benefits,
      EffectiveFrom, EffectiveTo, NameIsCurrent
    )
    SELECT
      lt.LoyaltyTierID,
      lt.Name,
      lt.MinPoints,
      lt.Benefits,
      @StartTime,
      NULL,
      1
    FROM SA.LoyaltyTier AS lt
    WHERE NOT EXISTS (
      SELECT 1 FROM DW.DimLoyaltyTier AS d
      WHERE d.LoyaltyTierKey = lt.LoyaltyTierID
    );
    SET @RowsInserted = @@ROWCOUNT;

    -- 3) Update log entry to Success
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
    -- 4) Update log entry to Error
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Initial full load failed',
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO