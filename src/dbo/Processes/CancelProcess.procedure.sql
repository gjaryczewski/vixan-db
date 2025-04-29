CREATE PROCEDURE dbo.CancelProcess AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.Processes WHERE [Status] = 'STARTED')
        THROW 50001, 'No process is currently started.', 1;

    DECLARE @ProcessId int = (SELECT TOP(1) Id FROM dbo.Processes WHERE [Status] = 'STARTED');

    UPDATE dbo.Processes
        SET [Status] = 'CANCELING'
        WHERE Id = @ProcessId;

    INSERT dbo.ProcessLog (ProcessId, [Status])
        VALUES (@ProcessId, 'CANCELING');

    DECLARE @ThreadId int = 0;
    DECLARE @ThreadCount int = (SELECT COUNT(*) FROM dbo.Threads WHERE ProcessId = @ProcessId);
    DECLARE @I int = 0; 
    WHILE @ThreadId IS NOT NULL AND @I < @ThreadCount
    BEGIN
        SET @ThreadId = (
            SELECT TOP(1) Id
            FROM dbo.Threads
            WHERE ProcessId = @ProcessId
                AND Id > @ThreadId
                AND [Status] IN ('SCHEDULED', 'STARTED')
            ORDER BY Id ASC);

        IF @ThreadId IS NOT NULL
            EXECUTE dbo.CancelThread @ThreadId;

        SET @i += 1;
    END

    DECLARE @ScheduledOperationId int = 0;
    DECLARE @ScheduledOperationCount int = (
        SELECT COUNT(*)
        FROM dbo.Operations
        WHERE ProcessId = @ProcessId
            AND [Status] = 'SCHEDULED');
    SET @I = 0; 
    WHILE @ScheduledOperationId IS NOT NULL AND @I < @ScheduledOperationCount
    BEGIN
        SET @ScheduledOperationId = (
            SELECT TOP(1) Id
            FROM dbo.Operations
            WHERE ProcessId = @ProcessId
                AND [Status] = 'SCHEDULED'
                AND Id > @ScheduledOperationId
            ORDER BY Id ASC);

        IF @ScheduledOperationId IS NOT NULL
            EXECUTE dbo.CancelOperation @ScheduledOperationId;

        SET @i += 1;
    END

WAITING_LOOP:

    IF EXISTS (SELECT * FROM dbo.Threads WHERE ProcessId = @ProcessId AND [Status] = 'CANCELING')
    BEGIN
        INSERT dbo.ProcessLog (ProcessId, [Status])
            VALUES (@ProcessId, 'CANCELING');

        WAITFOR DELAY '00:00:30';

        GOTO WAITING_LOOP;
    END

    IF EXISTS (SELECT * FROM dbo.Operations WHERE ProcessId = @ProcessId AND [Status] = 'CANCELING')
    BEGIN
        INSERT dbo.ProcessLog (ProcessId, [Status])
            VALUES (@ProcessId, 'CANCELING');

        WAITFOR DELAY '00:00:30';

        GOTO WAITING_LOOP;
    END

    UPDATE dbo.Processes
        SET [Status] = 'CANCELED'
        WHERE Id = @ProcessId;

    INSERT dbo.ProcessLog (ProcessId, [Status])
        VALUES (@ProcessId, 'CANCELED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @ProcessId = @ProcessId;
   RETURN 1;
END CATCH