CREATE VIEW dbo.CurrentWorkers AS
    SELECT WorkerId,
        StartTime,
        StopTime,
        [Status]
    FROM dbo.Workers
    WHERE ProcessId = (
            SELECT TOP(1) ProcessId FROM dbo.Processes WHERE [Status] = 'STARTED'
        );