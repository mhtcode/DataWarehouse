CREATE OR ALTER PROCEDURE [DW].[ETL_Crew_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
    @LastRunTime   DATETIME2(3),
    @RowsUpdated   INT,
    @RowsInserted  INT,
    @LogID         BIGINT;

  -- 1) Assume fatal: insert initial log entry
  INSERT INTO DW.ETL_Log (
    ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
  ) VALUES (
    'ETL_Crew_Dim',
    'DimCrew',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Determine last successful run time
    SELECT @LastRunTime = COALESCE(
      MAX(ActionTime),
      '1900-01-01'
    )
    FROM DW.ETL_Log
    WHERE ProcedureName = 'ETL_Crew_Dim'
      AND Status = 'Success';

    -- 3) Truncate staging
    TRUNCATE TABLE [DW].[Temp_Crew_table];

    -- 4) Populate staging with changed/new crew members
    INSERT INTO DW.Temp_Crew_table (
      Crew_ID, NAT_CODE, Name, Phone, Email,
      Address, City, Country, Date_Of_Birth,
      Gender, Postal_Code, Role
    )
    SELECT
      cm.CrewMemberID        AS Crew_ID,
      p.NatCode              AS NAT_CODE,
      p.Name,
      p.Phone,
      p.Email,
      p.Address,
      p.City,
      p.Country,
      p.DateOfBirth          AS Date_Of_Birth,
      p.Gender,
      p.PostalCode           AS Postal_Code,
      cm.Role
    FROM SA.CrewMember AS cm
    JOIN SA.Person     AS p
      ON cm.PersonID = p.PersonID
    WHERE cm.StagingLastUpdateTimestampUTC > @LastRunTime
       OR p.StagingLastUpdateTimestampUTC  > @LastRunTime;

    -- 5) Update existing crew records in dimension
    UPDATE d
    SET
      d.NAT_CODE      = t.NAT_CODE,
      d.Name          = t.Name,
      d.Phone         = t.Phone,
      d.Email         = t.Email,
      d.Address       = t.Address,
      d.City          = t.City,
      d.Country       = t.Country,
      d.Date_Of_Birth = t.Date_Of_Birth,
      d.Gender        = t.Gender,
      d.Postal_Code   = t.Postal_Code,
      d.Role          = t.Role
    FROM DW.DimCrew AS d
    JOIN DW.Temp_Crew_table AS t
      ON d.Crew_ID = t.Crew_ID;
    SET @RowsUpdated = @@ROWCOUNT;

    -- 6) Insert new crew members into dimension
    INSERT INTO DW.DimCrew (
      Crew_ID, NAT_CODE, Name, Phone, Email,
      Address, City, Country, Date_Of_Birth,
      Gender, Postal_Code, Role
    )
    SELECT
      t.Crew_ID,
      t.NAT_CODE,
      t.Name,
      t.Phone,
      t.Email,
      t.Address,
      t.City,
      t.Country,
      t.Date_Of_Birth,
      t.Gender,
      t.Postal_Code,
      t.Role
    FROM DW.Temp_Crew_table AS t
    WHERE NOT EXISTS (
      SELECT 1 FROM DW.DimCrew AS d WHERE d.Crew_ID = t.Crew_ID
    );
    SET @RowsInserted = @@ROWCOUNT;

    -- 7) Update log to Success
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = CONCAT(
        'Incremental load complete: updated=', @RowsUpdated,
        ', inserted=', @RowsInserted
      ),
      RowsAffected      = @RowsUpdated + @RowsInserted,
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Success'
    WHERE LogID = @LogID;

  END TRY
  BEGIN CATCH
    DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
    -- 8) Update log to Error
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