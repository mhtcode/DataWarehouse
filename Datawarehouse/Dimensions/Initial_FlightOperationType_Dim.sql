CREATE OR ALTER PROCEDURE [DW].[Initial_FlightOperationType_Dim]
AS
BEGIN
    INSERT INTO [DW].[DimFlightOperationType] (OperationTypeKey, OperationTypeName, OperationTypeDescription) VALUES
    (1, 'On-Time', 'The flight departed and arrived with no delay and was not canceled.'),
    (2, 'Delayed', 'The flight operated but had a delay of more than 0 minutes.'),
    (3, 'Canceled', 'The flight was canceled and did not operate.');
END
GO