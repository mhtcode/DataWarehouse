CREATE TABLE [DW].[PassengerTicket_TransactionalFact] (
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
  [TravelClassKey] [int] ,
  [TicketRealPrice] decimal(18,2), -- Price before discounts and taxes (from Payment.RealPrice)
  [TaxAmount] decimal(18,2),  -- Tax applied (it % is writen in Payment.Tax)
  [DiscountAmount] decimal(18,2),   -- Total discount given (from Payment.Discount)
  [TicketPrice] decimal(18,2),  -- Final paid amount (from Payment.TicketPrice)
  [FlightCost] decimal(18,2),  -- Allocated flight cost for this ticket (TotalCost ÷ Capacity) should be fetch from FlightDetail
  [FlightClassPrice] decimal(18,2), -- attributed to class type of the ticket (can match TravelClass.Cost)
  [FlightRevenue] decimal(18,2),  -- Total revenue from this ticket (class + ticket - cost)
  [kilometersFlown] decimal(18,2)  -- Distance flown (from FlightDetail.DistanceKM)
)
GO


CREATE NONCLUSTERED INDEX IX_PassengerTicket_TransactionalFact_PaymentDateKey
ON [DW].[PassengerTicket_TransactionalFact] (PaymentDateKey);
GO

CREATE NONCLUSTERED INDEX IX_PassengerTicket_TransactionalFact_FlightDateKey
ON [DW].[PassengerTicket_TransactionalFact] (FlightDateKey);
GO

CREATE NONCLUSTERED INDEX IX_PassengerTicket_TransactionalFact_BuyerPersonKey
ON [DW].[PassengerTicket_TransactionalFact] (BuyerPersonKey);
GO

CREATE NONCLUSTERED INDEX IX_PassengerTicket_TransactionalFact_FlightKey
ON [DW].[PassengerTicket_TransactionalFact] (FlightKey);
GO

CREATE NONCLUSTERED INDEX IX_PassengerTicket_TransactionalFact_PaymentKey
ON [DW].[PassengerTicket_TransactionalFact] (PaymentKey);
GO

CREATE NONCLUSTERED INDEX IX_PassengerTicket_TransactionalFact_TicketHolderPersonKey
ON [DW].[PassengerTicket_TransactionalFact] (TicketHolderPersonKey);
GO

CREATE NONCLUSTERED INDEX IX_PassengerTicket_TransactionalFact_AirlineKey
ON [DW].[PassengerTicket_TransactionalFact] (AirlineKey);
GO

CREATE NONCLUSTERED INDEX IX_PassengerTicket_TransactionalFact_DestinationAirportKey
ON [DW].[PassengerTicket_TransactionalFact] (DestinationAirportKey);
GO

CREATE NONCLUSTERED INDEX IX_PassengerTicket_TransactionalFact_TravelClassKey
ON [DW].[PassengerTicket_TransactionalFact] (TravelClassKey);
GO

CREATE NONCLUSTERED INDEX IX_PassengerTicket_TransactionalFact_AircraftKey
ON [DW].[PassengerTicket_TransactionalFact] (AircraftKey);
GO

CREATE NONCLUSTERED INDEX IX_PassengerTicket_TransactionalFact_SourceAirportKey
ON [DW].[PassengerTicket_TransactionalFact] (SourceAirportKey);
GO
