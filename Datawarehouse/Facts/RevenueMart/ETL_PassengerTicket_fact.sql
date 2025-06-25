CREATE OR ALTER PROCEDURE [DW].[LoadFactPassengerTicket]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @StartDate date;
	DECLARE @EndDate date;

	-- Correctly filter by status to get the date range of relevant data
    SELECT 
        @EndDate = MAX(CAST(PaymentDateTime AS DATE))
    FROM 
        [SA].[Payment]

    SELECT 
        @StartDate = MAX(CAST(PaymentDateKey AS DATE))
    FROM 
        [DW].[FactPassengerTicket_Transactional];

	-- Exit if there is no data to process
	IF @StartDate IS NULL
	BEGIN
		RAISERROR('No completed payments found. Exiting procedure.', 0, 1) WITH NOWAIT;
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
		VALUES ('LoadFactPassengerTicket', 'FactPassengerTicket_Transactional', 'Procedure started for date: ' + CONVERT(varchar, @CurrentDate, 101), @StartTime, 'Running');
		
		-- Capture the LogID for this specific run
		SET @LogID = SCOPE_IDENTITY();

		BEGIN TRY
			-- Clear staging tables for the current iteration
			TRUNCATE TABLE [DW].[Temp_DailyPayments];
			TRUNCATE TABLE [DW].[Temp_EnrichedFlightData];
			TRUNCATE TABLE [DW].[Temp_EnrichedPersonData];
			
			-- STEP A: Load Core Transactions
			INSERT INTO [DW].[Temp_DailyPayments] (PaymentID, ReservationID, BuyerID, RealPrice, TicketPrice, Discount, Tax, PaymentDateTime, TicketHolderPassengerID, FlightDetailID, SeatDetailID)
			SELECT p.PaymentID, r.ReservationID, p.BuyerID, p.RealPrice, p.TicketPrice, p.Discount, p.Tax, p.PaymentDateTime, r.PassengerID, r.FlightDetailID, r.SeatDetailID
			FROM [SA].[Payment] p
			INNER JOIN [SA].[Reservation] r ON p.ReservationID = r.ReservationID
			WHERE CAST(p.PaymentDateTime AS DATE) = @CurrentDate;

			IF @@ROWCOUNT = 0 
			BEGIN
				UPDATE DW.ETL_Log SET ChangeDescription = 'No payment data found for date: ' + CONVERT(varchar, @CurrentDate, 101), RowsAffected = 0, DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Success';
				-- CRITICAL FIX: Increment date before continuing to avoid infinite loop
				SET @CurrentDate = DATEADD(day, 1, @CurrentDate);
				CONTINUE;
			END

			-- STEP B: Load Flight-Enriched Data
			INSERT INTO [DW].[Temp_EnrichedFlightData] (PaymentID, FlightDateKey, FlightKey, AircraftKey, AirlineKey, SourceAirportKey, DestinationAirportKey, FlightClassPrice, FlightCost, KilometersFlown)
			SELECT dp.PaymentID, fd.DepartureDateTime, fd.FlightDetailID, ac.AircraftID, ac.AirlineID, fd.DepartureAirportID, fd.DestinationAirportID, tc.Cost,
				   CASE WHEN ISNULL(fd.FlightCapacity, 0) > 0 THEN ISNULL(fd.TotalCost, 0) / fd.FlightCapacity ELSE 0 END,
				   fd.DistanceKM
			FROM [DW].[Temp_DailyPayments] dp
			INNER JOIN [SA].[FlightDetail] fd ON dp.FlightDetailID = fd.FlightDetailID
			INNER JOIN [SA].[Aircraft] ac ON fd.AircraftID = ac.AircraftID
			INNER JOIN [SA].[SeatDetail] sd ON dp.SeatDetailID = sd.SeatDetailID
			INNER JOIN [SA].[TravelClass] tc ON sd.TravelClassID = tc.TravelClassID;
			
			-- STEP C: Load Person-Enriched Data
			INSERT INTO [DW].[Temp_EnrichedPersonData] (PaymentID, BuyerPersonKey, TicketHolderPersonKey)
			SELECT dp.PaymentID, BuyerPerson.PersonID, TicketHolderPerson.PersonID
			FROM [DW].[Temp_DailyPayments] dp
			INNER JOIN [SA].[Passenger] BuyerPassenger ON dp.BuyerID = BuyerPassenger.PassengerID
			INNER JOIN [SA].[Person] BuyerPerson ON BuyerPassenger.PersonID = BuyerPerson.PersonID
			INNER JOIN [SA].[Passenger] TicketHolderPassenger ON dp.TicketHolderPassengerID = TicketHolderPassenger.PassengerID
			INNER JOIN [SA].[Person] TicketHolderPerson ON TicketHolderPassenger.PersonID = TicketHolderPerson.PersonID;

			-- STEP D: Final Assembly and Insert into Fact Table
			INSERT INTO [DW].[FactPassengerTicket_Transactional] ([PaymentDateKey], [FlightDateKey], [BuyerPersonKey], [TicketHolderPersonKey], [PaymentKey], [FlightKey], [AircraftKey], [AirlineKey], [SourceAirportKey], [DestinationAirportKey], [ServiceOfferingKey], [TicketRealPrice], [TaxAmount], [DiscountAmount], [TicketPrice], [FlightCost], [FlightClassPrice], [FlightRevenue], [KilometersFlown])
			SELECT
				dp.PaymentDateTime, fd.FlightDateKey, pd.BuyerPersonKey, pd.TicketHolderPersonKey,
				dp.PaymentID, fd.FlightKey, fd.AircraftKey, fd.AirlineKey, fd.SourceAirportKey,
				fd.DestinationAirportKey, NULL,
				ISNULL(dp.RealPrice, 0),
				ISNULL(dp.TicketPrice, 0) * (ISNULL(dp.Tax, 0) / 100.0),
				ISNULL(dp.Discount, 0),
				ISNULL(dp.TicketPrice, 0),
				ISNULL(fd.FlightCost, 0),
				ISNULL(fd.FlightClassPrice, 0),
				ISNULL(dp.TicketPrice, 0) - ISNULL(fd.FlightCost, 0),
				ISNULL(fd.KilometersFlown, 0)
			FROM 
				[DW].[Temp_DailyPayments] dp
			INNER JOIN 
				[DW].[Temp_EnrichedFlightData] fd ON dp.PaymentID = fd.PaymentID
			INNER JOIN 
				[DW].[Temp_EnrichedPersonData] pd ON dp.PaymentID = pd.PaymentID;
			
			SET @RowCount = @@ROWCOUNT;

			-- Update the log entry to 'Success' for the current day
			UPDATE DW.ETL_Log SET ChangeDescription = 'Load complete for date: ' + CONVERT(varchar, @CurrentDate, 101), RowsAffected = @RowCount, DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Success' WHERE LogID = @LogID;

		END TRY
		BEGIN CATCH
			DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
			-- Update log entry to 'Error'
			UPDATE DW.ETL_Log SET ChangeDescription = 'Load failed for date: ' + CONVERT(varchar, @CurrentDate, 101), DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Error', Message = @ErrMsg WHERE LogID = @LogID;
			-- Re-throw the error to halt execution or be caught by a higher-level process
			THROW;
		END CATCH

		-- Increment the date to process the next day in the loop
		SET @CurrentDate = DATEADD(day, 1, @CurrentDate);
	END;

	RAISERROR('Fact table loading process has completed.', 0, 1) WITH NOWAIT;
	SET NOCOUNT OFF;
END
GO
exec [DW].[InitialFactPassengerTicket]

select * from [DW].[FactPassengerTicket_Transactional]

drop table [DW].[FactPassengerTicket_Transactional]