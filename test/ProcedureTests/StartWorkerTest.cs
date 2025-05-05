using Vixan.Db.Test.Fixtures;

namespace Vixan.Db.Test.ProcedureTests;

[Collection("Sequential")]
public class StartWorkerTest : BaseProcedureTest
{
    [Fact]
    public void StartWorker_Breaks_When_No_Process_Started()
    {
        // Arrange
        DbFixture.Reset();
        AssertNoCurrentProcess();
        var startTime = DbFixture.GetTimeUc();

        // Act
        var workerId = DbFixture.StartWorker();

        // Assert
        Assert.Null(workerId);
        AssertSingleErrorSince(startTime, "dbo.StartWorker", "No process is currently started.");
        AssertNoCurrentWorkers();
    }

    [Fact]
    public void StartWorker_Starts_Worker_When_Process_Started()
    {
        // Arrange
        DbFixture.Reset();
        AssertProcessStarted();
        AssertNoCurrentWorkers();
        var startTime = DbFixture.GetTimeUc();

        // Act
        var workerId = DbFixture.StartWorker();

        // Assert
        Assert.NotNull(workerId);
        AssertNoErrorSince(startTime);
        AssertWorkerStarted((int)workerId);
    }

    [Fact]
    public void StartWorker_Can_Be_Executed_Multiple_Times()
    {
        // Arrange
        DbFixture.Reset();
        AssertProcessStarted();
        AssertNoCurrentWorkers();
        var workersCount = new Random().Next(3, 6);
        var startTime = DbFixture.GetTimeUc();

        // Act
        for (var i = 0; i < workersCount; i++)
        {
            _ = DbFixture.StartWorker();
        }

        // Assert
        AssertNoErrorSince(startTime);
        Assert.Equal(workersCount, DbFixture.GetCurrentWorkers()?.Count);
    }
}