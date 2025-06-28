CREATE OR ALTER PROCEDURE [DW].[Initial_TravelClass_Dim]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
    @StartTime          DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted      INT,
    @LogID                   BIGINT;

    -- 1. Insert initial (fatal) log entry
    INSERT INTO DW.ETL_Log (
    ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
    ) VALUES (
    'Initial_TravelClass_Dim',
    'DimTravelClass',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
    -- 2. Truncate dimension for full initial load
    TRUNCATE TABLE DW.DimTravelClass;

    -- 3. Insert all travel classes from the source
    INSERT INTO DW.DimTravelClass (
        TravelClassKey,
        ClassName,
        Capacity -- ADDED
    )
    SELECT
        tc.TravelClassID,
        tc.ClassName,
        tc.Capacity -- ADDED
    FROM SA.TravelClass AS tc;

    SET @RowsInserted = @@ROWCOUNT;

    -- 4. Update log entry to Success
    UPDATE DW.ETL_Log
    SET
        ChangeDescription = 'Initial full load complete',
        RowsAffected         = @RowsInserted,
        DurationSec              = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
        Status                           = 'Success'
    WHERE LogID = @LogID;

    END TRY
    BEGIN CATCH
    DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
    -- 5. Update log entry to Error
    UPDATE DW.ETL_Log
    SET
        ChangeDescription = 'Initial load failed',
        DurationSec              = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
        Status                           = 'Error',
        Message                        = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
    END CATCH
END
GO