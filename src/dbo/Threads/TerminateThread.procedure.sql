CREATE PROCEDURE dbo.TerminateThread
    @ThreadId int AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.Processes WHERE [Status] = 'STARTED')
        THROW 50001, 'No process is currently started.', 1;

    IF NOT EXISTS (SELECT * FROM dbo.Threads WHERE ThreadId = @ThreadId)
        THROW 50002, 'There is no thread with the given identifier.', 1;

    IF EXISTS (SELECT * FROM dbo.Threads WHERE ThreadId = @ThreadId AND [Status] IN ('COMPLETED', 'TERMINATED'))
        THROW 50003, 'The thread is already completed or terminated.', 1;

    UPDATE dbo.Threads
        SET [Status] = 'TERMINATING'
        WHERE ThreadId = @ThreadId;

    INSERT dbo.ThreadLog (ThreadId, [Status])
        VALUES (@ThreadId, 'TERMINATING');

    DECLARE @StartedOperationId int = 0;
    DECLARE @StartedOperationCount int = (
        SELECT COUNT(*)
        FROM dbo.Operations
        WHERE ThreadId = @ThreadId
            AND [Status] = 'STARTED');
    DECLARE @I int = 0; 
    WHILE @StartedOperationId IS NOT NULL AND @I < @StartedOperationCount
    BEGIN
        SET @StartedOperationId = (
            SELECT TOP(1) OperationId
            FROM dbo.Operations
            WHERE ThreadId = @ThreadId
                AND [Status] = 'STARTED'
                AND OperationId > @StartedOperationId
            ORDER BY OperationId ASC);

        IF @StartedOperationId IS NOT NULL
            EXECUTE dbo.TerminateOperation @StartedOperationId;

        SET @i += 1;
    END

WAITING_LOOP:

    IF EXISTS (SELECT * FROM dbo.Operations WHERE ThreadId = @ThreadId AND [Status] = 'TERMINATING')
    BEGIN
        INSERT dbo.ThreadLog (ThreadId, [Status]) VALUES (@ThreadId, 'TERMINATING');

        WAITFOR DELAY '00:00:03';

        GOTO WAITING_LOOP;
    END

    UPDATE dbo.Threads SET [Status] = 'TERMINATED' WHERE ThreadId = @ThreadId;

    INSERT dbo.ThreadLog (ThreadId, [Status]) VALUES (@ThreadId, 'TERMINATED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @ThreadId = @ThreadId;
   RETURN 1;
END CATCH