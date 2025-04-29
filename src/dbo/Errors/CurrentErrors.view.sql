CREATE VIEW dbo.CurrentErrors AS
    SELECT Id,
        LogTime,
        ProcessId,
        OperationId,
        ThreadId,
        ProcedureName,
        LineNum,
        ErrorNum,
        ErrorMessage,
        UserLogin,
        UserHost
    FROM dbo.ErrorLog
    WHERE ProcessId = (
            SELECT TOP(1) Id FROM dbo.Processes WHERE [Status] = 'STARTED'
        );