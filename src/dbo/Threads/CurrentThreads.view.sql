CREATE VIEW dbo.CurrentThreads AS
    SELECT ThreadId,
        StartTime,
        CompleteTime,
        [Status]
    FROM dbo.Threads
    WHERE ProcessId = (
            SELECT TOP(1) ProcessId FROM dbo.Processes WHERE [Status] = 'STARTED'
        );