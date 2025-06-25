CREATE OR ALTER PROCEDURE [DW].[InitialFactPassengerTicket]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate date;
    DECLARE @EndDate date;

    SELECT 
        @StartDate = MIN(CAST(PaymentDateTime AS DATE)),
        @EndDate = MAX(CAST(PaymentDateTime AS DATE))
    FROM 
        [SA].[Payment]

    DECLARE @CurrentDate date = @StartDate;

    DECLARE
    @StartTime    DATETIME2(3),
    @RowCount INT,
    @LogID        BIGINT;

    SET @LogID = SCOPE_IDENTITY();

    WHILE @CurrentDate <= @EndDate
    BEGIN
    BEGIN TRY

        SET @StartTime = SYSUTCDATETIME();

        INSERT INTO DW.ETL_Log (
        ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
        ) VALUES (
        'InitialFactPassengerTicket',
        'FactPassengerTicket_Transactional',
        'Procedure started - awaiting for completion of ' + CONVERT(date, @CurrentDate, 101),
        @StartTime,
        'Fatal'
        );
        
        ------------------------------------------------------------------------------------
        -- STEP A: Load Core Transactions into the permanent staging table
        ------------------------------------------------------------------------------------
        INSERT INTO [DW].[Temp_DailyPayments] (
            PaymentID, ReservationID, BuyerID, Amount, RealPrice, Discount, 
            PaymentDateTime, TicketHolderPassengerID, FlightDetailID, SeatDetailID
        )
        SELECT
            p.PaymentID, r.ReservationID, p.BuyerID, p.Amount, p.RealPrice, p.Discount,
            p.PaymentDateTime, r.PassengerID, r.FlightDetailID, r.SeatDetailID
        FROM
            [SA].[Payment] p
        INNER JOIN
            [SA].[Reservation] r ON p.ReservationID = r.ReservationID
        WHERE
            CAST(p.PaymentDateTime AS DATE) = @CurrentDate

        IF @@ROWCOUNT = 0 
        BEGIN
            UPDATE DW.ETL_Log
            SET
                ChangeDescription = 'load complete DATE: ' + CONVERT(date, @CurrentDate, 101),
                RowsAffected      = @RowCount,
                DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
                Status            = 'Success'
            WHERE LogID = @LogID;
            CONTINUE;
        END

        ------------------------------------------------------------------------------------
        -- STEP B: Load Flight-Enriched Data into its permanent staging table
        ------------------------------------------------------------------------------------
        INSERT INTO [DW].[Temp_EnrichedFlightData] (
            PaymentID, FlightDateKey, FlightKey, AircraftKey, AirlineKey, 
            SourceAirportKey, DestinationAirportKey, FlightClassPrice, FlightCost, KilometersFlown
        )
        SELECT
            dp.PaymentID, fd.DepartureDateTime, fd.FlightDetailID, ac.AircraftID, ac.AirlineID,
            fd.DepartureAirportID, fd.DestinationAirportID, tc.Cost,
            CASE WHEN ISNULL(fd.FlightCapacity, 0) > 0 THEN ISNULL(fd.TotalCost, 0) / fd.FlightCapacity ELSE 0 END,
            fd.DistanceKM
        FROM [DW].[Temp_DailyPayments] dp
        INNER JOIN [SA].[FlightDetail] fd ON dp.FlightDetailID = fd.FlightDetailID
        INNER JOIN [SA].[Aircraft] ac ON fd.AircraftID = ac.AircraftID
        INNER JOIN [SA].[SeatDetail] sd ON dp.SeatDetailID = sd.SeatDetailID
        INNER JOIN [SA].[TravelClass] tc ON sd.TravelClassID = tc.TravelClassID
        INNER JOIN [SA].[Airport] SourceAirport ON fd.DepartureAirportID = SourceAirport.AirportID
        INNER JOIN [SA].[Airport] DestAirport ON fd.DestinationAirportID = DestAirport.AirportID;
        
        ------------------------------------------------------------------------------------
        -- STEP C: Load Person-Enriched Data into its permanent staging table
        ------------------------------------------------------------------------------------
        INSERT INTO [DW].[Temp_EnrichedPersonData] (PaymentID, BuyerPersonKey, TicketHolderPersonKey)
        SELECT
            dp.PaymentID,
            BuyerPerson.PersonID,
            TicketHolderPerson.PersonID
        FROM [DW].[Temp_DailyPayments] dp
        INNER JOIN [SA].[Passenger] BuyerPassenger ON dp.BuyerID = BuyerPassenger.PassengerID
        INNER JOIN [SA].[Person] BuyerPerson ON BuyerPassenger.PersonID = BuyerPerson.PersonID
        INNER JOIN [SA].[Passenger] TicketHolderPassenger ON dp.TicketHolderPassengerID = TicketHolderPassenger.PassengerID
        INNER JOIN [SA].[Person] TicketHolderPerson ON TicketHolderPassenger.PersonID = TicketHolderPerson.PersonID;

        ------------------------------------------------------------------------------------
        -- STEP D: Final Assembly and Insert into Fact Table from staging tables
        ------------------------------------------------------------------------------------
        INSERT INTO [DW].[FactPassengerTicket_Transactional] (
            [PaymentDateKey], [FlightDateKey], [BuyerPersonKey], [TicketHolderPersonKey],
            [PaymentKey], [FlightKey], [AircraftKey], [AirlineKey], [SourceAirportKey],
            [DestinationAirportKey], [ServiceOfferingKey], [TicketRealPrice], [TaxAmount],
            [DiscountAmount], [TicketPrice], [FlightCost], [FlightClassPrice], [FlightRevenue], [KilometersFlown]
        )
        SELECT
            dp.PaymentDateTime, fd.FlightDateKey, pd.BuyerPersonKey, pd.TicketHolderPersonKey,
            dp.PaymentID, fd.FlightKey, fd.AircraftKey, fd.AirlineKey, fd.SourceAirportKey,
            fd.DestinationAirportKey, NULL,
            ISNULL(dp.RealPrice, 0), ISNULL(dp.Amount - (dp.RealPrice - dp.Discount), 0), ISNULL(dp.Discount, 0),
            ISNULL(dp.Amount, 0), ISNULL(fd.FlightCost, 0), ISNULL(fd.FlightClassPrice, 0),
            ISNULL(dp.Amount, 0) - ISNULL(fd.FlightCost, 0), ISNULL(fd.KilometersFlown, 0)
        FROM 
            [DW].[Temp_DailyPayments] dp
        INNER JOIN 
            [DW].[Temp_EnrichedFlightData] fd ON dp.PaymentID = fd.PaymentID
        INNER JOIN 
            [DW].[Temp_EnrichedPersonData] pd ON dp.PaymentID = pd.PaymentID;
        
        SET @RowCount = @@ROWCOUNT;        
        SET @CurrentDate = DATEADD(day, 1, @CurrentDate);

        -- We use TRUNCATE TABLE, which is a fast, minimally logged operation
        -- to clear the staging tables for the current day's data.
        TRUNCATE TABLE [DW].[Temp_DailyPayments];
        TRUNCATE TABLE [DW].[Temp_EnrichedFlightData];
        TRUNCATE TABLE [DW].[Temp_EnrichedPersonData];

        UPDATE DW.ETL_Log
        SET
            ChangeDescription = 'load complete DATE: ' + CONVERT(date, @CurrentDate, 101),
            RowsAffected      = @RowCount,
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Success'
        WHERE LogID = @LogID;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
        -- 4) Update log entry to Error
        UPDATE DW.ETL_Log
        SET
            ChangeDescription = 'load failed DATE: ' + CONVERT(date, @CurrentDate, 101)
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Error',
            Message           = @ErrMsg
        WHERE LogID = @LogID;
        THROW;
    END CATCH
    END;

    SET NOCOUNT OFF;
END
GO