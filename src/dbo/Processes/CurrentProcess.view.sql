CREATE VIEW dbo.CurrentProcess AS
    SELECT TOP(1) ProcessId, StartTime, CompleteTime, [Status]
    FROM dbo.Processes
    WHERE [Status] = 'STARTED';