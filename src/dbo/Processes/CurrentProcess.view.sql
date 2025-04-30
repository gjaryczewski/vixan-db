CREATE VIEW dbo.CurrentProcess AS
    SELECT TOP(1) ProcessId, StartTime, StopTime, [Status]
    FROM dbo.Processes
    WHERE [Status] = 'STARTED';