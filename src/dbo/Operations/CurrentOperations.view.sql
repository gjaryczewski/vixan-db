CREATE VIEW dbo.CurrentOperations AS
    SELECT OperationId,
        ScriptName,
        StartTime,
        CompleteTime,
        [Status],
        ThreadId,
        ProcessId,
        SessionId
    FROM dbo.Operations
    WHERE ProcessId = (
            SELECT TOP(1) ProcessId FROM dbo.Processes WHERE [Status] = 'STARTED'
        );