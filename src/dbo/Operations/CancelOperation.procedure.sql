CREATE PROCEDURE dbo.CancelOperation
    @OperationId int AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.Processes WHERE [Status] = 'STARTED')
        THROW 50001, 'No process is currently started.', 1;

    IF NOT EXISTS (SELECT * FROM dbo.Operations WHERE Id = @OperationId)
        THROW 50002, 'There is no operation with the given Id.', 1;

    IF EXISTS (SELECT * FROM dbo.Operations WHERE Id = @OperationId AND [Status] IN ('STOPPED', 'CANCELED'))
        THROW 50003, 'The operation is already stopped or canceled.', 1;

    UPDATE dbo.Operations
        SET [Status] = 'CANCELING'
        WHERE Id = @OperationId;

    INSERT dbo.OperationLog (OperationId, [Status])
        VALUES (@OperationId, 'CANCELING');

    DECLARE @SessionId int = (SELECT TOP(1) SessionId FROM dbo.Operations WHERE Id = @OperationId);
    IF EXISTS (SELECT * FROM sys.dm_exec_sessions WHERE [session_id] = @SessionId) 
    BEGIN
        DECLARE @KillScript varchar(100) = CONCAT('KILL ', @SessionId);
        EXECUTE (@KillScript);
    END

    WAITFOR DELAY '00:00:01';

    IF EXISTS (SELECT * FROM sys.dm_exec_sessions WHERE [session_id] = @SessionId) 
        THROW 5004, 'The session assigned to the operation cannot be properly canceled.', 1;

    UPDATE dbo.Operations
        SET [Status] = 'CANCELED'
        WHERE Id = @OperationId;

    INSERT dbo.OperationLog (OperationId, [Status])
        VALUES (@OperationId, 'CANCELED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @OperationId = @OperationId;
   RETURN 1;
END CATCH