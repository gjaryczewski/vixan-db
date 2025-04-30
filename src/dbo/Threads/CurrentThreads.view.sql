CREATE VIEW dbo.CurrentThreads AS
    SELECT ThreadId,
        StartTime,
        StopTime,
        [Status]
    FROM dbo.Threads
    WHERE ProcessId = (
            SELECT TOP(1) ProcessId FROM dbo.Processes WHERE [Status] = 'STARTED'
        );