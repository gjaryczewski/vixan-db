CREATE PROCEDURE dbo.TerminateWorker
    @WorkerId int AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.CurrentProcess)
        THROW 50001, 'No process is currently started.', 1;

    IF NOT EXISTS (SELECT * FROM dbo.CurrentWorkers WHERE WorkerId = @WorkerId)
        THROW 50002, 'There is no current worker with the given identifier.', 1;

    IF EXISTS (SELECT * FROM dbo.CurrentWorkers WHERE WorkerId = @WorkerId AND [Status] IN ('COMPLETED', 'TERMINATED'))
        THROW 50003, 'The worker is already completed or terminated.', 1;

    UPDATE dbo.Workers
        SET [Status] = 'TERMINATING'
        WHERE WorkerId = @WorkerId;

    INSERT dbo.WorkerLog (WorkerId, [Status])
        VALUES (@WorkerId, 'TERMINATING');

    DECLARE @StartedOperationId int = 0;
    DECLARE @StartedOperationCount int = (
        SELECT COUNT(*)
        FROM dbo.Operations
        WHERE WorkerId = @WorkerId
            AND [Status] = 'STARTED');
    DECLARE @I int = 0;
    WHILE @StartedOperationId IS NOT NULL AND @I < @StartedOperationCount
    BEGIN
        SET @StartedOperationId = (
            SELECT TOP(1) OperationId
            FROM dbo.Operations
            WHERE WorkerId = @WorkerId
                AND [Status] = 'STARTED'
                AND OperationId > @StartedOperationId
            ORDER BY OperationId ASC);

        IF @StartedOperationId IS NOT NULL
            EXECUTE dbo.TerminateOperation @StartedOperationId;

        SET @i += 1;
    END

WAITING_LOOP:

    IF EXISTS (SELECT * FROM dbo.Operations WHERE WorkerId = @WorkerId AND [Status] = 'TERMINATING')
    BEGIN
        INSERT dbo.WorkerLog (WorkerId, [Status]) VALUES (@WorkerId, 'TERMINATING');

        WAITFOR DELAY '00:00:03';

        GOTO WAITING_LOOP;
    END

    UPDATE dbo.Workers SET [Status] = 'TERMINATED' WHERE WorkerId = @WorkerId;

    INSERT dbo.WorkerLog (WorkerId, [Status]) VALUES (@WorkerId, 'TERMINATED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @WorkerId = @WorkerId;
   RETURN 1;
END CATCH