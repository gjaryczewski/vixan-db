using Vixan.Db.Test.Fixtures;

namespace Vixan.Db.Test.ProcedureTests;

[Collection("Sequential")]
public class RunOperationTest : BaseProcedureTest
{
    [Fact]
    public void RunOperation_Breaks_When_No_Process_Started()
    {
        // Arrange
        DbFixture.Reset();
        AssertNoCurrentProcess();
        var startTime = DbFixture.GetTimeUc();
    
        // Act
        DbFixture.RunOperation(1, 1);

        // Assert
        AssertSingleErrorSince(startTime, "dbo.RunOperation", "No process is currently started.");
        AssertNoCurrentOperation();
    }

    [Fact]
    public void RunOperation_Breaks_When_Worker_Not_Registered()
    {
        // Arrange
        DbFixture.Reset();
        AssertProcessStarted();
        var operationId = DbFixture.NextOperationToRun();
        var startTime = DbFixture.GetTimeUc();
    
        // Act
        DbFixture.RunOperation(operationId, 1);

        // Assert
        AssertSingleErrorSince(startTime, "dbo.RunOperation", "There is no current worker with the given identifier.");
        AssertNoStartedOperation();
    }

    [Fact]
    public void RunOperation_Breaks_When_Worker_Not_Started()
    {
        // Arrange
        DbFixture.Reset();
        AssertProcessStarted();
        AssertWorkerRegisteredThenStopped();
        var workerId = DbFixture.GetFirstCurrentWorker().WorkerId;
        var operationId = DbFixture.NextOperationToRun();
        var startTime = DbFixture.GetTimeUc();
    
        // Act
        DbFixture.RunOperation(operationId, (int)workerId);

        // Assert
        AssertSingleErrorSince(startTime, "dbo.RunOperation", "The worker with the given identifier is not started.");
        AssertNoStartedOperation();
    }

    [Fact]
    public void RunOperation_Breaks_When_Operation_Not_Planned()
    {
        // Arrange
        DbFixture.Reset();
        AssertProcessStarted();
        AssertWorkerRegistered();
        var workerId = DbFixture.GetFirstCurrentWorker().WorkerId;
        var operationId = DbFixture.NextOperationToRun();
        DbFixture.TerminateOperation(operationId);
        var startTime = DbFixture.GetTimeUc();
    
        // Act
        DbFixture.RunOperation(operationId, (int)workerId);

        // Assert
        AssertSingleErrorSince(startTime, "dbo.RunOperation", "The operation is not planned to start.");
        AssertNoStartedOperation();
    }

    [Fact]
    public void RunOperation_Runs_Planned_Operation_With_Registered_Worker()
    {
        // Arrange
        DbFixture.Reset();
        AssertProcessStarted();
        AssertWorkerRegistered();
        var workerId = DbFixture.GetFirstCurrentWorker().WorkerId;
        var operationId = DbFixture.NextOperationToRun();
        var startTime = DbFixture.GetTimeUc();
    
        // Act
        DbFixture.RunOperation(operationId, (int)workerId);

        // Assert
        AssertNoErrorSince(startTime);
        AssertStartedOperation(operationId);
    }
}