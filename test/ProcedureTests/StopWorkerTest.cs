using Vixan.Db.Test.Fixtures;

namespace Vixan.Db.Test.ProcedureTests;

[Collection("Sequential")]
public class StopWorkerTest : BaseProcedureTest
{
    [Fact]
    public void StopWorker_Breaks_When_No_Process_Started()
    {
        // Arrange
        DbFixture.Reset();
        AssertNoCurrentProcess();
        var startTime = DbFixture.GetTimeUc();

        // Act
        DbFixture.StopWorker(1);

        // Assert
        AssertSingleErrorSince(startTime, "dbo.StopWorker", "No process is currently started.");
        AssertNoCurrentWorkers();
    }

    [Fact]
    public void StopWorker_Stops_Worker_When_Started_And_No_Operation_Started()
    {
        // Arrange
        DbFixture.Reset();
        _ = AssertProcessStarted();
        AssertNoOperationStarted();
        AssertWorkerStarted();
        var workerId = DbFixture.GetFirstCurrentWorker().WorkerId;
        var startTime = DbFixture.GetTimeUc();

        // Act
        DbFixture.StopWorker(workerId);

        // Assert
        AssertNoErrorSince(startTime);
        AssertWorkerStopped((int)workerId);
    }
}