CREATE OR ALTER PROCEDURE [DW].[ETL_Person_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
    @LastRunTime   DATETIME2(3),
    @RowsExpired   INT,
    @RowsInserted  INT;

  BEGIN TRY
    -- determine last successful run
    SELECT @LastRunTime = COALESCE(
      MAX(ActionTime),
      '1900-01-01'
    )
    FROM DW.ETL_Log
    WHERE ProcedureName = 'ETL_Person_Dim'
      AND Status = 'Success';

    -- clean staging
    TRUNCATE TABLE [DW].[Temp_Person_table];

    -- populate staging with changed/new source rows
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

    -- expire current dimension rows for those keys
    UPDATE d
    SET
      d.IsCurrent   = 0,
      d.EffectiveTo = @StartTime
    FROM DW.DimPerson AS d
    WHERE
      d.IsCurrent = 1
      AND EXISTS (
        SELECT 1 FROM DW.Temp_Person_table AS t WHERE t.PersonID = d.PersonKey
      );
    SET @RowsExpired = @@ROWCOUNT;

    -- insert new SCD2 versions from staging
    INSERT INTO DW.DimPerson (
      PersonKey, NationalCode, PassportNumber, Name,
      Gender, DateOfBirth, City, Country,
      Email, Phone, Address, PostalCode,
      EffectiveFrom, EffectiveTo, IsCurrent
    )
    SELECT
      t.PersonID, t.NationalCode, t.PassportNumber, t.Name,
      t.Gender, t.DateOfBirth, t.City, t.Country,
      t.Email, t.Phone, t.Address, t.PostalCode,
      @StartTime, NULL, 1
    FROM DW.Temp_Person_table AS t;
    SET @RowsInserted = @@ROWCOUNT;

    -- log success
    INSERT INTO DW.ETL_Log (
      ProcedureName, TargetTable, ChangeDescription,
      RowsAffected, ActionTime, DurationSec, Status
    )
    VALUES (
      'ETL_Person_Dim',
      'DimPerson',
      CONCAT('Incremental load: expired=', @RowsExpired, ', inserted=', @RowsInserted),
      @RowsExpired + @RowsInserted,
      @StartTime,
      DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      'Success'
    );
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
    -- log error
    INSERT INTO DW.ETL_Log (
      ProcedureName, TargetTable, ChangeDescription,
      RowsAffected, ActionTime, DurationSec, Status, Message
    )
    VALUES (
      'ETL_Person_Dim',
      'DimPerson',
      'Incremental SCD2 load failed',
      NULL,
      @StartTime,
      DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      'Error',
      @ErrorMessage
    );
    THROW;
  END CATCH
END
GO
