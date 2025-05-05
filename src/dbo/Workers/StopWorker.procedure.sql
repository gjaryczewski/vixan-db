CREATE PROCEDURE dbo.StopWorker
    @WorkerId int AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.CurrentProcess)
        THROW 50001, 'No process is currently started.', 1;

    IF NOT EXISTS (SELECT * FROM dbo.CurrentWorkers WHERE WorkerId = @WorkerId)
        THROW 50002, 'There is no current worker with the given identifier.', 1;

    IF EXISTS (SELECT * FROM dbo.CurrentWorkers WHERE WorkerId = @WorkerId AND [Status] = 'STOPPED')
        THROW 50003, 'The worker is already stopped.', 1;

    IF EXISTS (SELECT * FROM dbo.CurrentWorkers WHERE WorkerId = @WorkerId AND [Status] = 'TERMINATED')
        THROW 50004, 'The worker is already terminated.', 1;

    IF EXISTS (SELECT * FROM dbo.CurrentOperations WHERE WorkerId = @WorkerId AND [Status] = 'STARTED')
        THROW 50005, 'The worker cannot be stopped because some operations are still running.', 1;

    UPDATE dbo.Workers
        SET [Status] = 'STOPPED',
            StopTime = GETUTCDATE()
        WHERE WorkerId = @WorkerId
            AND [Status] = 'STARTED';

    IF @@ROWCOUNT = 0
        THROW 50006, 'The worker is not ready to stop.', 1;

    INSERT dbo.WorkerLog (WorkerId, [Status]) VALUES (@WorkerId, 'STOPPED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @WorkerId = @WorkerId;
   RETURN 1;
END CATCH