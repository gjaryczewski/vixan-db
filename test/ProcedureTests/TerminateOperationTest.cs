using Microsoft.VisualStudio.TestPlatform.ObjectModel.DataCollection;
using Vixan.Db.Test.Fixtures;

namespace Vixan.Db.Test.ProcedureTests;

[Collection("Sequential")]
public class TerminateOperationTest : BaseProcedureTest
{
    [Fact]
    public void TerminateOperation_Breaks_When_No_Process_Started()
    {
        // Arrange
        DbFixture.Reset();
        AssertNoCurrentProcess();
        var startTime = DbFixture.GetTimeUc();

        // Act
        DbFixture.TerminateOperation(1);

        // Assert
        AssertSingleErrorSince(startTime, "dbo.TerminateOperation", "No process is currently started.");
    }

    [Fact]
    public void TerminateOperation_Breaks_When_Operation_Not_Current()
    {
        // Arrange
        DbFixture.Reset();
        AssertProcessStarted();
        var startTime = DbFixture.GetTimeUc();

        // Act
        DbFixture.TerminateOperation(0);

        // Assert
        AssertSingleErrorSince(startTime, "dbo.TerminateOperation",
            "There is no current operation with the given identifier.");
    }

    [Fact]
    public void TerminateOperation_Breaks_When_Operation_Already_Terminated()
    {
        // Arrange
        DbFixture.Reset();
        AssertProcessStarted();
        var operationId = DbFixture.NextOperationToRun();
        AssertOperationTerminated(operationId);
        var startTime = DbFixture.GetTimeUc();

        // Act
        DbFixture.TerminateOperation(operationId);

        // Assert
        AssertSingleErrorSince(startTime, "dbo.TerminateOperation", "The operation is already terminated.");
    }

    [Fact]
    public void TerminateOperation_Breaks_When_Operation_Already_Completed()
    {
        // Arrange
        DbFixture.Reset();
        AssertProcessStarted();
        var operationId = DbFixture.NextOperationToRun();
        DbFixture.MakeOperationFast(operationId);
        AssertOperationCompleted(operationId);
        var startTime = DbFixture.GetTimeUc();

        // Act
        DbFixture.TerminateOperation(operationId);

        // Assert
        AssertSingleErrorSince(startTime, "dbo.TerminateOperation", "The operation is already completed.");
    }

    [Fact]
    public void TerminateOperation_Terminates_Operation_By_Killing_Session()
    {
        // Arrange
        DbFixture.Reset();
        AssertProcessStarted();
        AssertWorkerStarted();
        var workerId = DbFixture.GetFirstCurrentWorker().WorkerId;
        var operationId = DbFixture.NextOperationToRun();
        DbFixture.MakeOperationSlow(operationId);
        Task.Run(() => DbFixture.RunOperation(operationId, workerId));
        Assert.True(DbFixture.IsSessionActive(operationId));
        var startTime = DbFixture.GetTimeUc();

        // Act
        DbFixture.TerminateOperation(operationId);

        // Assert
        AssertNoErrorSince(startTime);
        AssertOperationTerminated(operationId);
        Assert.False(DbFixture.IsSessionActive(operationId));
    }
}