CREATE PROCEDURE dbo.StopWorker
    @WorkerId int AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.CurrentProcess)
        THROW 50001, 'No process is currently started.', 1;

    IF NOT EXISTS (SELECT * FROM dbo.CurrentWorkers WHERE WorkerId = @WorkerId)
        THROW 50002, 'There is no current worker with the given identifier.', 1;

    IF EXISTS (SELECT * FROM dbo.CurrentWorkers WHERE WorkerId = @WorkerId AND [Status] IN ('STOPPED', 'TERMINATED'))
        THROW 50003, 'The worker is already stopped or terminated.', 1;

    IF EXISTS (SELECT * FROM dbo.Operations WHERE WorkerId = @WorkerId AND [Status] IN ('PLANNED', 'STARTED'))
        THROW 50004, 'The worker cannot be completed because some operations are planned or have already started.', 1;

    UPDATE dbo.Workers
        SET [Status] = 'STOPPED',
            StopTime = GETUTCDATE()
        WHERE WorkerId = @WorkerId
            AND [Status] = 'STARTED';

    IF @@ROWCOUNT = 0
        THROW 50005, 'The worker is not ready to stop.', 1;

    INSERT dbo.WorkerLog (WorkerId, [Status]) VALUES (@WorkerId, 'STOPPED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @WorkerId = @WorkerId;
   RETURN 1;
END CATCH