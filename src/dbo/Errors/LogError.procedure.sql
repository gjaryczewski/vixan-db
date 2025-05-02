CREATE PROCEDURE dbo.LogError
    @ProcessId int = NULL,
    @WorkerId int = NULL,
    @OperationId int = NULL,
    @ErrorLogId int = NULL OUTPUT AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    DECLARE @ProcedureName nvarchar(128) = ERROR_PROCEDURE();
    DECLARE @LineNum int = ERROR_LINE();
    DECLARE @ErrorNum int = ERROR_NUMBER();
    DECLARE @ErrorMessage nvarchar(4000) = ERROR_MESSAGE();

    IF @OperationId IS NOT NULL AND @WorkerId IS NULL
        SET @WorkerId = (SELECT TOP(1) WorkerId FROM dbo.Operations WHERE OperationId = @OperationId);
    IF @WorkerId IS NOT NULL AND @ProcessId IS NULL
        SET @ProcessId = (SELECT TOP(1) ProcessId FROM dbo.Workers WHERE WorkerId = @WorkerId);

    INSERT dbo.ErrorLog (
        ProcessId,
        WorkerId,
        OperationId,
        ProcedureName,
        LineNum,
        ErrorNum,
        ErrorMessage
    ) VALUES (
        @ProcessId,
        @WorkerId,
        @OperationId,
        @ProcedureName,
        @LineNum,
        @ErrorNum,
        @ErrorMessage
    );

    SET @ErrorLogId = SCOPE_IDENTITY();
END TRY
BEGIN CATCH
    IF XACT_STATE() = -1 ROLLBACK TRANSACTION;
    THROW;
END CATCH