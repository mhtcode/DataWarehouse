CREATE OR ALTER PROCEDURE [DW].[Load_FactFlightPerformance_TransactionalFact]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @StartDate date;
	DECLARE @EndDate date;

	-- Determine the date range from the actual departure dates in the flight operations table.

    SELECT 
        @StartDate = MAX(CAST(ActualDepartureId AS DATE))
    FROM 
        [DW].[FlightPerformance_TransactionalFact];

	SELECT 
		@EndDate = MAX(CAST(ActualDepartureDateTime AS DATE))
	FROM 
		[SA].[FlightOperation];

	-- Exit if there is no operational data to process.
	IF @StartDate IS NULL
	BEGIN
		RAISERROR('No flight operations data found. Exiting procedure.', 0, 1) WITH NOWAIT;
		RETURN;
	END

	IF @StartDate >= @EndDate
	BEGIN
		RAISERROR('The FlightPerformance_TransactionalFact table is up to date!', 0, 1) WITH NOWAIT;
		RETURN;
	END

	DECLARE @CurrentDate date = @StartDate;
	
	WHILE @CurrentDate <= @EndDate
	BEGIN
		-- Declare log variables inside the loop for each daily run
		DECLARE @LogID BIGINT;
		DECLARE @StartTime DATETIME2(3) = SYSUTCDATETIME();
		DECLARE @RowCount INT;

		-- Log the start of the process for the current day
		INSERT INTO DW.ETL_Log (ProcedureName, TargetTable, ChangeDescription, ActionTime, Status) 
		VALUES ('LoadFactFlightPerformance', 'FlightPerformance_TransactionalFact', 'Procedure started for date: ' + CONVERT(varchar, @CurrentDate, 101), @StartTime, 'Running');
		
		SET @LogID = SCOPE_IDENTITY();

		BEGIN TRY			
			-- STEP A: Load Core Flight Operations for the day
			INSERT INTO [DW].[Temp_DailyFlightOperations] (FlightOperationID, FlightDetailID, ActualDepartureDateTime, ActualArrivalDateTime, DelayMinutes, LoadFactor, DelaySeverityScore)
			SELECT FlightOperationID, FlightDetailID, ActualDepartureDateTime, ActualArrivalDateTime, DelayMinutes, LoadFactor, DelaySeverityScore
			FROM [SA].[FlightOperation]
			WHERE CAST(ActualDepartureDateTime AS DATE) = @CurrentDate;

			IF @@ROWCOUNT = 0 
			BEGIN
				UPDATE DW.ETL_Log SET ChangeDescription = 'No flight operations found for date: ' + CONVERT(varchar, @CurrentDate, 101), RowsAffected = 0, DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Success' WHERE LogID = @LogID;
				SET @CurrentDate = DATEADD(day, 1, @CurrentDate);
				CONTINUE;
			END

			-- STEP B: Enrich with Flight Detail and Aircraft data
			INSERT INTO [DW].[Temp_EnrichedFlightPerformanceData] (FlightOperationID, ScheduledDepartureDateTime, ScheduledArrivalDateTime, ActualDepartureDateTime, ActualArrivalDateTime, DepartureAirportID, ArrivalAirportID, AircraftID, AirlineID, DelayMinutes, LoadFactor, DelaySeverityScore)
			SELECT
                fo.FlightOperationID,
                fd.DepartureDateTime,
                fd.ArrivalDateTime,
                fo.ActualDepartureDateTime,
                fo.ActualArrivalDateTime,
                fd.DepartureAirportID,
                fd.DestinationAirportID,
                fd.AircraftID,
                ac.AirlineID,
                fo.DelayMinutes,
                fo.LoadFactor,
                fo.DelaySeverityScore
			FROM [DW].[Temp_DailyFlightOperations] fo
			INNER JOIN [SA].[FlightDetail] fd ON fo.FlightDetailID = fd.FlightDetailID
            INNER JOIN [SA].[Aircraft] ac ON fd.AircraftID = ac.AircraftID;
			
			-- STEP C: Final Assembly and Insert into Fact Table
			-- Here we perform the final calculations (DATEDIFF).
			INSERT INTO [DW].[FlightPerformance_TransactionalFact] (
                ScheduledDepartureId, ScheduledArrivalId, ActualDepartureId, ActualArrivalId,
                DepartureAirportId, ArrivalAirportId, AircraftId, AirlineId,
                DepartureDelayMinutes, ArrivalDelayMinutes, FlightDurationActual, FlightDurationScheduled,
                LoadFactor, DelaySeverityScore
            )
			SELECT
				-- IDs and Keys
				ef.ScheduledDepartureDateTime, ef.ScheduledArrivalDateTime, ef.ActualDepartureDateTime, ef.ActualArrivalDateTime,
                ef.DepartureAirportID, ef.ArrivalAirportID, ef.AircraftID, ef.AirlineID,
                -- Measures
                ef.DelayMinutes, -- Mapping source DelayMinutes to both Departure and Arrival delay
                ef.DelayMinutes,
                DATEDIFF(MINUTE, ef.ActualDepartureDateTime, ef.ActualArrivalDateTime), -- Calculated actual duration
                DATEDIFF(MINUTE, ef.ScheduledDepartureDateTime, ef.ScheduledArrivalDateTime), -- Calculated scheduled duration
                ef.LoadFactor,
                ef.DelaySeverityScore
			FROM [DW].[Temp_EnrichedFlightPerformanceData] ef;
			
			SET @RowCount = @@ROWCOUNT;

			-- Clear staging tables for the current iteration
			TRUNCATE TABLE [DW].[Temp_DailyFlightOperations];
			TRUNCATE TABLE [DW].[Temp_EnrichedFlightPerformanceData];
			
			-- Update the log entry to 'Success' for the current day
			UPDATE DW.ETL_Log SET ChangeDescription = 'Load complete for date: ' + CONVERT(varchar, @CurrentDate, 101), RowsAffected = @RowCount, DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Success' WHERE LogID = @LogID;

		END TRY
		BEGIN CATCH
			DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
			UPDATE DW.ETL_Log SET ChangeDescription = 'Load failed for date: ' + CONVERT(varchar, @CurrentDate, 101), DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Error', Message = @ErrMsg WHERE LogID = @LogID;
			THROW;
		END CATCH

		-- Increment the date to process the next day
		SET @CurrentDate = DATEADD(day, 1, @CurrentDate);
	END;

	RAISERROR('FlightPerformance_TransactionalFact loading process has completed.', 0, 1) WITH NOWAIT;
	SET NOCOUNT OFF;
END
GO
