CREATE OR ALTER PROCEDURE [DW].[Initial_Crew_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted  INT,
    @LogID         BIGINT;

  INSERT INTO DW.ETL_Log (
    ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
  ) VALUES (
    'Initial_Crew_Dim',
    'DimCrew',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    INSERT INTO DW.DimCrew (
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
    WHERE NOT EXISTS (
      SELECT 1 FROM DW.DimCrew AS d WHERE d.Crew_ID = cm.CrewMemberID
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
      ChangeDescription = 'Initial load failed',
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO