CREATE VIEW dbo.CurrentOperations AS
    SELECT Id,
        ScriptName,
        StartTime,
        StopTime,
        [Status],
        ThreadId,
        ProcessId,
        SessionId
    FROM dbo.Operations
    WHERE ProcessId = (
            SELECT TOP(1) Id FROM dbo.Processes WHERE [Status] = 'STARTED'
        );