CREATE PROCEDURE dbo.TerminateProcess AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.Processes WHERE [Status] = 'STARTED')
        THROW 50001, 'No process is currently started.', 1;

    DECLARE @ProcessId int = (
        SELECT TOP(1) ProcessId FROM dbo.Processes WHERE [Status] = 'STARTED');

    UPDATE dbo.Processes SET [Status] = 'TERMINATING' WHERE ProcessId = @ProcessId;

    INSERT dbo.ProcessLog (ProcessId, [Status]) VALUES (@ProcessId, 'TERMINATING');

    DECLARE @ThreadId int = 0;
    DECLARE @ThreadCount int = (SELECT COUNT(*) FROM dbo.Threads WHERE ProcessId = @ProcessId);
    DECLARE @I int = 0; 
    WHILE @ThreadId IS NOT NULL AND @I < @ThreadCount
    BEGIN
        SET @ThreadId = (
            SELECT TOP(1) ThreadId
            FROM dbo.Threads
            WHERE ProcessId = @ProcessId
                AND ThreadId > @ThreadId
                AND [Status] IN ('PLANNED', 'STARTED')
            ORDER BY ThreadId ASC);

        IF @ThreadId IS NOT NULL
            EXECUTE dbo.TerminateThread @ThreadId;

        SET @i += 1;
    END

    DECLARE @PlannedOperationId int = 0;
    DECLARE @PlannedOperationCount int = (
        SELECT COUNT(*)
        FROM dbo.Operations
        WHERE ProcessId = @ProcessId
            AND [Status] = 'PLANNED');
    SET @I = 0; 
    WHILE @PlannedOperationId IS NOT NULL AND @I < @PlannedOperationCount
    BEGIN
        SET @PlannedOperationId = (
            SELECT TOP(1) OperationId
            FROM dbo.Operations
            WHERE ProcessId = @ProcessId
                AND [Status] = 'PLANNED'
                AND OperationId > @PlannedOperationId
            ORDER BY OperationId ASC);

        IF @PlannedOperationId IS NOT NULL
            EXECUTE dbo.TerminateOperation @PlannedOperationId;

        SET @i += 1;
    END

WAITING_LOOP:

    IF EXISTS (SELECT * FROM dbo.Threads WHERE ProcessId = @ProcessId AND [Status] = 'TERMINATING')
    BEGIN
        INSERT dbo.ProcessLog (ProcessId, [Status]) VALUES (@ProcessId, 'TERMINATING');

        WAITFOR DELAY '00:00:30';

        GOTO WAITING_LOOP;
    END

    IF EXISTS (SELECT * FROM dbo.Operations WHERE ProcessId = @ProcessId AND [Status] = 'TERMINATING')
    BEGIN
        INSERT dbo.ProcessLog (ProcessId, [Status]) VALUES (@ProcessId, 'TERMINATING');

        WAITFOR DELAY '00:00:30';

        GOTO WAITING_LOOP;
    END

    UPDATE dbo.Processes SET [Status] = 'TERMINATED' WHERE ProcessId = @ProcessId;

    INSERT dbo.ProcessLog (ProcessId, [Status]) VALUES (@ProcessId, 'TERMINATED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @ProcessId = @ProcessId;
   RETURN 1;
END CATCH