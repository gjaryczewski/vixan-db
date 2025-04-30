CREATE VIEW dbo.CurrentErrors AS
    SELECT ErrorLogId,
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
            SELECT TOP(1) ProcessId FROM dbo.Processes WHERE [Status] = 'STARTED'
        );