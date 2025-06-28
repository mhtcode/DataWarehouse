CREATE TABLE [DW].[PassengerActivity_YearlyFact] (
  [YearID] date, --first day of year
  [PersonKey] int, -- The ticket holder
  [YearlyTicketValue] decimal(18,2),  -- Sum of TotalAmountPaid
  [YearlyMilesFlown] decimal(18,2), -- Sum of MilesFlown
  [YearlyDiscountAmount] decimal(18,2), -- Sum of DiscountAmount
  [YearlyAverageTicketPrice] decimal(18,2),  -- Avg of TicketPrice
  [YearlyDistinctAirlinesUsed] int,  -- COUNT(DISTINCT AirlineKey)
  [YearlyDistinctRoutesFlown] int,  -- COUNT(DISTINCT SourceAirportKey + DestinationAirportKey)
  [YearlyFlights] decimal(18,2),  -- COUNT(DISTINCT FlightKey)
  [YearlyMaxFlightDistance] decimal(18,2), -- MAX(MilesFlown)
  [YearlyMinFlightDistance] decimal(18,2)  -- MIN(MilesFlown)
)
GO

CREATE NONCLUSTERED INDEX IX_PassengerActivity_ACCFact_PersonKey
ON [DW].[PassengerActivity_ACCFact] (PersonKey);
GO

CREATE NONCLUSTERED INDEX IX_PassengerActivity_ACCFact_YearID
ON [DW].[PassengerActivity_ACCFact] (YearID);
GO