CREATE PROCEDURE dbo.StopThread
    @ThreadId int AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.Processes WHERE [Status] = 'STARTED')
        THROW 50001, 'No process is currently started.', 1;

    IF NOT EXISTS (SELECT * FROM dbo.Threads WHERE Id = @ThreadId)
        THROW 50002, 'There is no thread with the given Id.', 1;

    IF EXISTS (SELECT * FROM dbo.Threads WHERE Id = @ThreadId AND [Status] IN ('STOPPED', 'CANCELED'))
        THROW 50003, 'The thread is already stopped or canceled.', 1;

    IF EXISTS (SELECT * FROM dbo.Operations WHERE ThreadId = @ThreadId AND [Status] IN ('SCHEDULED', 'STARTED'))
        THROW 50004, 'The thread cannot be stopped because some operations are scheduled or have already started.', 1;

    UPDATE dbo.Threads
        SET [Status] = 'STOPPED',
            StopTime = GETUTCDATE()
        WHERE Id = @ThreadId
            AND [Status] = 'STARTED';

    IF @@ROWCOUNT = 0
        THROW 50005, 'The process is not available to stop.', 1;

    INSERT dbo.ThreadLog (ThreadId, [Status])
        VALUES (@ThreadId, 'STOPPED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @ThreadId = @ThreadId;
   RETURN 1;
END CATCH