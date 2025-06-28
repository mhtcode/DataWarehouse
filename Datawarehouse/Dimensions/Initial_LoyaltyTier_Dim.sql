CREATE OR ALTER PROCEDURE [DW].[Initial_LoyaltyTier_Dim]
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted INT,
    @LogID        BIGINT;

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
    INSERT INTO DW.DimLoyaltyTier (
      LoyaltyTierID,
      Name,
      MinPoints,
      Benefits,
      EffectiveFrom,
      EffectiveTo,
      MinPointsIsCurrent
    )
    SELECT
      lt.LoyaltyTierID,
      lt.Name,
      lt.MinPoints,
      lt.Benefits,
      '1950-01-01 00:00:00',
      NULL,
      1
    FROM SA.LoyaltyTier AS lt
    WHERE NOT EXISTS (
      SELECT 1 FROM DW.DimLoyaltyTier AS d
      WHERE d.LoyaltyTierID = lt.LoyaltyTierID
    );
    SET @RowsInserted = @@ROWCOUNT;

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
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Initial full load failed',
      RowsAffected      = NULL,
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO