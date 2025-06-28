CREATE OR ALTER PROCEDURE [DW].[Initial_PassengerActivity_YearlyFact]
AS
BEGIN
	SET NOCOUNT ON;

	-- === Add date variables for iterative load ===
	DECLARE @StartDate date;
	DECLARE @EndDate date;

	-- Determine the date range from the transactional fact table
	SELECT 
		@StartDate = MIN(FlightDateKey),
		@EndDate = MAX(FlightDateKey)
	FROM 
		[DW].[PassengerTicket_TransactionalFact];
	
	IF @StartDate IS NULL
	BEGIN
		RAISERROR('No data found in PassengerTicket_TransactionalFact to process.', 0, 1) WITH NOWAIT;
		RETURN;
	END

	DECLARE @CurrentYear INT = YEAR(@StartDate);
	DECLARE @EndYear INT = YEAR(@EndDate);
	
	-- === Implement WHILE loop for yearly processing ===
	WHILE @CurrentYear <= @EndYear
	BEGIN
		DECLARE @LogID BIGINT;
		DECLARE @StartTime DATETIME2(3) = SYSUTCDATETIME();
		DECLARE @RowCount INT;

		INSERT INTO DW.ETL_Log (ProcedureName, TargetTable, ChangeDescription, ActionTime, Status) 
		VALUES ('Initial_PassengerActivity_YearlyFact', 'PassengerActivity_YearlyFact', 'Procedure started for year: ' + CAST(@CurrentYear AS VARCHAR), @StartTime, 'Running');
			
		SET @LogID = SCOPE_IDENTITY();

		BEGIN TRY
			-- A Common Table Expression (CTE) to aggregate data for the current year in the loop.
			WITH YearlyAggregates AS (
				SELECT
					fptt.TicketHolderPersonKey, -- Group by the historical surrogate key first
					SUM(fptt.TicketPrice) AS TotalAmountPaid,
					SUM(fptt.kilometersFlown) AS TotalKilometersFlown,
					SUM(fptt.DiscountAmount) AS TotalDiscountAmount,
					AVG(fptt.TicketPrice) AS AverageTicketPrice,
					COUNT(DISTINCT fptt.AirlineKey) AS DistinctAirlinesUsed,
					COUNT(DISTINCT CONCAT(fptt.SourceAirportKey, '-', fptt.DestinationAirportKey)) AS DistinctRoutesFlown,
					COUNT(DISTINCT fptt.FlightKey) AS TotalFlights,
					MAX(fptt.kilometersFlown) AS MaxFlightDistanceKM,
					MIN(fptt.kilometersFlown) AS MinFlightDistanceKM
				FROM
					[DW].[PassengerTicket_TransactionalFact] fptt
				-- MODIFICATION: Join to DimPayment to filter out non-completed payments.
				INNER JOIN
					[DW].[DimPayment] dp ON fptt.PaymentKey = dp.PaymentKey
				WHERE
					YEAR(fptt.FlightDateKey) = @CurrentYear -- Process only one year at a time
					AND dp.PaymentStatus = 'Completed' -- Exclude records from non-completed payments.
				GROUP BY
					fptt.TicketHolderPersonKey
			)
			-- Final insert into the snapshot table
			INSERT INTO [DW].[PassengerActivity_YearlyFact] (
				YearID,
				PersonKey,
				YearlyTicketValue,
				YearlyMilesFlown,
				YearlyDiscountAmount,
				YearlyAverageTicketPrice,
				YearlyDistinctAirlinesUsed,
				YearlyDistinctRoutesFlown,
				YearlyFlights,
				YearlyMaxFlightDistance,
				YearlyMinFlightDistance
			)
			SELECT
				DATEFROMPARTS(@CurrentYear, 1, 1), -- YearID is the first day of the current year in the loop
				current_person.PersonKey, -- IMPORTANT: We store the SURROGATE KEY of the CURRENT person version
				agg.TotalAmountPaid,
				agg.TotalKilometersFlown,
				agg.TotalDiscountAmount,
				agg.AverageTicketPrice,
				agg.DistinctAirlinesUsed,
				agg.DistinctRoutesFlown,
				agg.TotalFlights,
				agg.MaxFlightDistanceKM,
				agg.MinFlightDistanceKM
			FROM 
				YearlyAggregates agg
			-- JOIN 1: Connect the historical key from the transaction to its dimension record to get the BUSINESS key.
			INNER JOIN [DW].[DimPerson] historical_person ON agg.TicketHolderPersonKey = historical_person.PersonKey
			-- JOIN 2: Use the business key to find the SINGLE CURRENT version of that person.
			INNER JOIN [DW].[DimPerson] current_person ON historical_person.PersonID = current_person.PersonID AND current_person.PassportNumberIsCurrent = 1;

			SET @RowCount = @@ROWCOUNT;

			UPDATE DW.ETL_Log SET ChangeDescription = 'Load complete for year: ' + CAST(@CurrentYear AS VARCHAR), RowsAffected = @RowCount, DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Success' WHERE LogID = @LogID;

		END TRY
		BEGIN CATCH
			DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
			UPDATE DW.ETL_Log SET ChangeDescription = 'Load failed for year: ' + CAST(@CurrentYear AS VARCHAR), DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Error', Message = @ErrMsg WHERE LogID = @LogID;
			THROW;
		END CATCH

		-- Increment the year to process the next one
		SET @CurrentYear = @CurrentYear + 1;

	END; -- End of WHILE loop

	RAISERROR('PassengerActivity_YearlyFact loading process has completed.', 0, 1) WITH NOWAIT;
	SET NOCOUNT OFF;
END
GO
