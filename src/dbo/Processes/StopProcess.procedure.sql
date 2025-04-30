CREATE PROCEDURE dbo.StopProcess AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.Processes WHERE [Status] = 'STARTED')
        THROW 50001, 'No process is currently started.', 1;

    IF EXISTS (SELECT * FROM dbo.Processes WHERE [Status] IN ('STOPPED', 'CANCELED'))
        THROW 50002, 'The process is already stopped or canceled.', 1;

    DECLARE @ProcessId int = (
        SELECT TOP(1) ProcessId FROM dbo.Processes WHERE [Status] = 'STARTED');

    IF EXISTS (SELECT * FROM dbo.Threads WHERE ProcessId = @ProcessId AND [Status] IN ('SCHEDULED', 'STARTED'))
        THROW 50003, 'The process cannot be stopped because some threads are scheduled or have already started.', 1;

    UPDATE dbo.Processes
        SET [Status] = 'STOPPED',
            StopTime = GETUTCDATE()
        WHERE ProcessId = @ProcessId
            AND [Status] = 'STARTED';

    IF @@ROWCOUNT = 0
        THROW 50005, 'The process is not available to stop.', 1;

    INSERT dbo.ProcessLog (ProcessId, [Status]) VALUES (@ProcessId, 'STOPPED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @ProcessId = @ProcessId;
   RETURN 1;
END CATCH