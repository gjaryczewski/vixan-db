CREATE FUNCTION dbo.NextOperationToRun()
RETURNS int AS
BEGIN
    RETURN (
        SELECT TOP(1) Id FROM dbo.Operations WHERE [Status] = 'SCHEDULED'
    );
END;
GO