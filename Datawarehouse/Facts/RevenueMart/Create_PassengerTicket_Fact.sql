CREATE TABLE [FactPassengerTicket_Transactional] (
  [PaymentDateKey] datetime,
  [FlightDateKey] datetime,
  [BuyerPersonKey] int,
  [TicketHolderPersonKey] int,
  [PaymentKey] int,
  [FlightKey] int,
  [AircraftKey] int,
  [AirlineKey] int,
  [SourceAirportKey] int,
  [DestinationAirportKey] int,
  [ServiceOfferingKey] int,
  [TicketRealPrice] decimal(18,2), -- Price before discounts and taxes (from Payment.RealPrice)
  [TaxAmount] decimal(18,2),  -- Tax applied (it % is writen in Payment.Tax)
  [DiscountAmount] decimal(18,2),   -- Total discount given (from Payment.Discount)
  [TicketPrice] decimal(18,2),  -- Final paid amount (from Payment.TicketPrice)
  [FlightCost] decimal(18,2),  -- Allocated flight cost for this ticket (TotalCost ÷ Capacity) should be fetch from FlightDetail
  [FlightClassPrice] decimal(18,2), -- attributed to class type of the ticket (can match TravelClass.Cost)
  [FlightRevenue] decimal(18,2),  -- Total revenue from this ticket (class + ticket - cost)
  [MilesFlown] decimal(18,2)  -- Distance flown (calculated from airport coordinates)
)
GO

               