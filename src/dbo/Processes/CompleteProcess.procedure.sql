CREATE PROCEDURE dbo.CompleteProcess AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.Processes WHERE [Status] = 'STARTED')
        THROW 50001, 'No process is currently started.', 1;

    IF EXISTS (SELECT * FROM dbo.Processes WHERE [Status] IN ('COMPLETED', 'TERMINATED'))
        THROW 50002, 'The process is already completed or terminated.', 1;

    DECLARE @ProcessId int = (
        SELECT TOP(1) ProcessId FROM dbo.Processes WHERE [Status] = 'STARTED');

    IF EXISTS (SELECT * FROM dbo.Workers WHERE ProcessId = @ProcessId AND [Status] IN ('PLANNED', 'STARTED'))
        THROW 50003, 'The process cannot be completed because some workers are scheduled or have already started.', 1;

    UPDATE dbo.Processes
        SET [Status] = 'COMPLETED',
            CompleteTime = GETUTCDATE()
        WHERE ProcessId = @ProcessId
            AND [Status] = 'STARTED';

    IF @@ROWCOUNT = 0
        THROW 50005, 'The process is not ready to complete.', 1;

    INSERT dbo.ProcessLog (ProcessId, [Status]) VALUES (@ProcessId, 'COMPLETED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @ProcessId = @ProcessId;
   RETURN 1;
END CATCH