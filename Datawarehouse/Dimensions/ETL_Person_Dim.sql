CREATE OR ALTER PROCEDURE [DW].[ETL_Person_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
    @LastRunTime   DATETIME2(3),
    @RowsExpired   INT,
    @RowsInserted  INT,
    @LogID         BIGINT;

  -- 1) Insert initial "Fatal" log entry
  INSERT INTO DW.ETL_Log (
    ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
  ) VALUES (
    'ETL_Person_Dim',
    'DimPerson',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Determine last successful run
    SELECT @LastRunTime = COALESCE(
      MAX(ActionTime),
      '1900-01-01'
    )
    FROM DW.ETL_Log
    WHERE ProcedureName = 'ETL_Person_Dim'
      AND Status = 'Success';

    -- 3) Clean staging
    TRUNCATE TABLE [DW].[Temp_Person_table];

    -- 4) Populate staging with changed/new source rows
    INSERT INTO [DW].[Temp_Person_table] (
      PersonID, NationalCode, PassportNumber, Name,
      Gender, DateOfBirth, City, Country,
      Email, Phone, Address, PostalCode
    )
    SELECT
      p.PersonID,
      p.NatCode,
      pas.PassportNumber,
      p.Name,
      p.Gender,
      p.DateOfBirth,
      p.City,
      p.Country,
      p.Email,
      p.Phone,
      p.Address,
      p.PostalCode
    FROM SA.Person AS p
    LEFT JOIN SA.Passenger AS pas
      ON p.PersonID = pas.PersonID
    WHERE
      p.StagingLastUpdateTimestampUTC > @LastRunTime
      OR pas.StagingLastUpdateTimestampUTC > @LastRunTime;

    -- 5) Expire current dimension rows for those keys
    UPDATE d
    SET
      d.PassportNumberIsCurrent = 0,
      d.EffectiveTo            = @StartTime
    FROM DW.DimPerson AS d
    WHERE
      d.PassportNumberIsCurrent = 1
      AND EXISTS (
        SELECT 1 FROM DW.Temp_Person_table AS t
        WHERE t.PersonID = d.PersonID
      );
    SET @RowsExpired = @@ROWCOUNT;

    -- 6) Insert new SCD2 versions
    INSERT INTO DW.DimPerson (
      PersonID, NationalCode, PassportNumber, Name,
      Gender, DateOfBirth, City, Country,
      Email, Phone, Address, PostalCode,
      EffectiveFrom, EffectiveTo, PassportNumberIsCurrent
    )
    SELECT
      t.PersonID,
      t.NationalCode,
      t.PassportNumber,
      t.Name,
      t.Gender,
      t.DateOfBirth,
      t.City,
      t.Country,
      t.Email,
      t.Phone,
      t.Address,
      t.PostalCode,
      @StartTime,
      NULL,
      1
    FROM DW.Temp_Person_table AS t;
    SET @RowsInserted = @@ROWCOUNT;

    -- 7) Update log to Success
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = CONCAT(
        'Incremental load complete: expired=', @RowsExpired,
        ', inserted=', @RowsInserted
      ),
      RowsAffected      = @RowsExpired + @RowsInserted,
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Success'
    WHERE LogID = @LogID;

  END TRY
  BEGIN CATCH
    DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
    -- 8) Update log to Error
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Incremental SCD2 load failed',
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO