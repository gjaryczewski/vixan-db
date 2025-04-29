CREATE VIEW dbo.CurrentProcess AS
    SELECT TOP(1) Id,
        StartTime,
        StopTime,
        [Status]
    FROM dbo.Processes
    WHERE [Status] = 'STARTED';