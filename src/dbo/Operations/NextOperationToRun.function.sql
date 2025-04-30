CREATE FUNCTION dbo.NextOperationToRun()
RETURNS int AS
BEGIN
    RETURN (
        SELECT TOP(1) OperationId FROM dbo.Operations WHERE [Status] = 'SCHEDULED'
    );
END;
GO