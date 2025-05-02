using Vixan.Db.Test.Fixtures;

namespace Vixan.Db.Test.ProcedureTests;

[Collection("Sequential")]
public class LogErrorTest
{
    [Fact]
    public void LogError_Captures_Error_Attributtes()
    {
        // Arrange
        DbFixture.Reset();
        var startTime = DbFixture.GetTimeUc();
        var errorNum = 50001;
        var errorMessage = "A test error message.";
        var testScript = $"""
        BEGIN TRY
            THROW 50001, '{errorMessage}', 1;
        END TRY
        BEGIN CATCH
            EXECUTE dbo.LogError;
        END CATCH
        """;

        // Act
        DbFixture.Execute(testScript);

        // Assert
        var logEntries = DbFixture.GetErrorLogSince(startTime);
        Assert.NotNull(logEntries);
        Assert.Single(logEntries);
        var entry = logEntries.First();
        Assert.Equivalent(
            new { ErrorNum = errorNum, ErrorMessage = errorMessage },
            new { entry.ErrorNum, entry.ErrorMessage });
    }
}