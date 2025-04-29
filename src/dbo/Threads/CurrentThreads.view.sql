CREATE VIEW dbo.CurrentThreads AS
    SELECT Id,
        StartTime,
        StopTime,
        [Status]
    FROM dbo.Threads
    WHERE ProcessId = (
            SELECT TOP(1) Id FROM dbo.Processes WHERE [Status] = 'STARTED'
        );