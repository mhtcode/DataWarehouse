CREATE TABLE [DW].[FactPassengerActivity_Yearly] (
  [YearID] date, --first day of year
  [PersonKey] int, -- The ticket holder
  [TotalTicketValue] decimal(18,2),  -- Sum of TotalAmountPaid
  [TotalMilesFlown] decimal(18,2), -- Sum of MilesFlown
  [TotalDiscountAmount] decimal(18,2), -- Sum of DiscountAmount
  [AverageTicketPrice] decimal(18,2),  -- Avg of TicketPrice
  [DistinctAirlinesUsed] int,  -- COUNT(DISTINCT AirlineKey)
  [DistinctRoutesFlown] int,  -- COUNT(DISTINCT SourceAirportKey + DestinationAirportKey)
  [TotalFlights] decimal(18,2),  -- COUNT(DISTINCT FlightKey)
  [MaxFlightDistance] decimal(18,2), -- MAX(MilesFlown)
  [MinFlightDistance] decimal(18,2)  -- MIN(MilesFlown)
)
GO