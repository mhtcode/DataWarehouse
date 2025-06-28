CREATE OR ALTER PROCEDURE [DW].[Initial_AirlineAndAirport_Factless]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @LogID BIGINT;
	DECLARE @StartTime DATETIME2(3) = SYSUTCDATETIME();
	DECLARE @RowCount INT;

	INSERT INTO DW.ETL_Log (ProcedureName, TargetTable, ChangeDescription, ActionTime, Status) 
	VALUES ('Initial_AirlineAndAirport_Factless', 'AirlineAndAirport_Factless', 'Procedure started for initial full load', @StartTime, 'Running');
		
	SET @LogID = SCOPE_IDENTITY();

	BEGIN TRY
		-- Use a CTE to gather all unique airline-airport relationships from flight details.
		WITH AirlineAirportRelations AS (
			-- Select all departure relationships
			SELECT
				ac.AirlineID,
				fd.DepartureAirportID AS AirportID
			FROM
				[SA].[FlightDetail] fd
			INNER JOIN
				[SA].[Aircraft] ac ON fd.AircraftID = ac.AircraftID
			
			UNION -- UNION automatically handles duplicates between the two sets

			-- Select all arrival relationships
			SELECT
				ac.AirlineID,
				fd.DestinationAirportID AS AirportID
			FROM
				[SA].[FlightDetail] fd
			INNER JOIN
				[SA].[Aircraft] ac ON fd.AircraftID = ac.AircraftID
		)
		-- Perform a simple insert for the initial load.
		INSERT INTO [DW].[AirlineAndAirport_Factless] (
			AirlineID,
			AirportID
		)
		SELECT DISTINCT
			AirlineID,
			AirportID
		FROM 
			AirlineAirportRelations;


		SET @RowCount = @@ROWCOUNT;

		UPDATE DW.ETL_Log SET ChangeDescription = 'Initial full load complete', RowsAffected = @RowCount, DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Success' WHERE LogID = @LogID;

	END TRY
	BEGIN CATCH
		DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
		UPDATE DW.ETL_Log SET ChangeDescription = 'Initial full load failed', DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Error', Message = @ErrMsg WHERE LogID = @LogID;
		THROW;
	END CATCH

	RAISERROR('Initial AirlineAndAirport_Factless loading process has completed.', 0, 1) WITH NOWAIT;
	SET NOCOUNT OFF;
END
GO
