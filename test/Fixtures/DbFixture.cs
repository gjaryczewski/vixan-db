
using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using Vixan.Db.Test.Models;

namespace Vixan.Db.Test.Fixtures;

public static class DbFixture
{
    const string connectionString = "Server=(localdb)\\MSSQLLocalDB;Database=vixantestdb;Integrated Security=true;";

    public static void Reset()
    {
        using var db = new SqlConnection(connectionString);
		
		var sql = """
        TRUNCATE TABLE dbo.ErrorLog;
        TRUNCATE TABLE dbo.OperationLog;
        TRUNCATE TABLE dbo.Operations;
        TRUNCATE TABLE dbo.ProcessLog;
        TRUNCATE TABLE dbo.Processes;
        TRUNCATE TABLE dbo.WorkerLog;
        TRUNCATE TABLE dbo.Workers;

        TRUNCATE TABLE dst.TestTable0;
        TRUNCATE TABLE dst.TestTable1;
        TRUNCATE TABLE dst.TestTable2;
        TRUNCATE TABLE dst.TestTable3;
        TRUNCATE TABLE dst.TestTable4;
        TRUNCATE TABLE dst.TestTable5;
        TRUNCATE TABLE dst.TestTable6;
        TRUNCATE TABLE dst.TestTable7;
        TRUNCATE TABLE dst.TestTable8;
        TRUNCATE TABLE dst.TestTable9;

        DELETE dbo.Scripts;
        DECLARE @T int = 0;
        WHILE @T < 10
        BEGIN
            DECLARE @Script varchar(1000) = CONCAT(
                'DECLARE @Offset int = ISNULL((SELECT MAX(TestValue) FROM dst.TestTable', @T, '), 0);', CHAR(10),
                'WHILE @Offset IS NOT NULL', CHAR(10),
                'BEGIN', CHAR(10),
                '    INSERT dst.TestTable', @T, ' (TestValue)', CHAR(10),
                '        SELECT TOP(1000) TestValue', CHAR(10),
                '        FROM src.TestTable', @T, CHAR(10),
                '        WHERE TestValue > @Offset;', CHAR(10),
                CHAR(10),
                '    WAITFOR DELAY ''00:00:01'';', CHAR(10),
                CHAR(10),
                '    SET @Offset = (SELECT MAX(TestValue) FROM dst.TestTable', @T, ' WHERE TestValue > @Offset);', CHAR(10),
                'END');
            INSERT dbo.Scripts (ScriptName, ScriptCode, SeqNum)
                VALUES (CONCAT('COPY_TEST', @T), @Script, @T + 1);
            SET @T += 1;
        END
        """;

		db.Execute(sql);
    }

    public static void Execute(string sql)
    {
        using var db = new SqlConnection(connectionString);
		
		db.Execute(sql);
    }

    public static DateTime GetTimeUc()
    {
        using var db = new SqlConnection(connectionString);
		
        return db.ExecuteScalar<DateTime>("SELECT GETUTCDATE()");
    }

#region "Errors"

    public static List<ErrorLogEntry>? GetErrorLog(DateTime? since = null)
    {
        using var db = new SqlConnection(connectionString);
		
		var sql = since is null
            ? "SELECT * FROM dbo.ErrorLog"
            : "SELECT * FROM dbo.ErrorLog WHERE LogTime >= @Since";
		return db.Query<ErrorLogEntry>(sql, new { Since = since })?.ToList();
    }

    public static List<ErrorLogEntry>? GetCurrentErrors()
    {
        using var db = new SqlConnection(connectionString);
		
		return db.Query<ErrorLogEntry>("SELECT * FROM dbo.CurrentErrors")?.ToList();
    }

#endregion "Errors"

#region  "Operations"

    public static List<Operation>? GetOperations(DateTime? since = null)
    {
        using var db = new SqlConnection(connectionString);
		
		var sql = since is null
            ? "SELECT * FROM dbo.Operations"
            : "SELECT * FROM dbo.Operations WHERE StartTime >= @Since";
		return db.Query<Operation>(sql, new { Since = since })?.ToList();
    }

    public static List<OperationLogEntry>? GetOperationLog(DateTime? since = null)
    {
        using var db = new SqlConnection(connectionString);
		
		var sql = since is null
            ? "SELECT * FROM dbo.OperationLog"
            : "SELECT * FROM dbo.OperationLog WHERE LogTime >= @Since";
		return db.Query<OperationLogEntry>(sql, new { Since = since })?.ToList();
    }

    public static List<Worker>? GetCurrentOperations()
    {
        using var db = new SqlConnection(connectionString);
		
		return db.Query<Worker>("SELECT * FROM dbo.CurrentOperations")?.ToList();
    }

    public static int NextOperationToRun()
    {
        using var db = new SqlConnection(connectionString);
		
		return db.ExecuteScalar<int>("SELECT dbo.NextOperationToRun()");
    }

    public static void RunOperation(int operationId, int workerId)
    {
        var pars = new DynamicParameters();
        pars.Add("@OperationId", operationId, DbType.Int32);
        pars.Add("@WorkerId", workerId, DbType.Int32);

        using var db = new SqlConnection(connectionString);
		
		db.Execute("dbo.RunOperation", pars, commandType: CommandType.StoredProcedure);
    }

    public static void TerminateOperation(int operationId)
    {
        var pars = new DynamicParameters();
        pars.Add("@OperationId", operationId, DbType.Int32);

        using var db = new SqlConnection(connectionString);
		
		db.Execute("dbo.TerminateOperation", pars, commandType: CommandType.StoredProcedure);
    }

    public static List<Script>? GetScripts()
    {
        using var db = new SqlConnection(connectionString);
		
		return db.Query<Script>("dbo.Scripts")?.ToList();
    }

    public static string? GetScriptCode(int operationId)
    {
        var pars = new DynamicParameters();
        pars.Add("@OperationId", operationId, DbType.Int32);

        using var db = new SqlConnection(connectionString);
		
		return db.ExecuteScalar<string>("""
            SELECT TOP(1) ScriptCode
            FROM dbo.Scripts
            WHERE ScriptName = (
                SELECT ScriptName
                FROM dbo.Operations
                WHERE OperationId = @OperationId)
            """, pars);
    }

    public static void SetScriptCode(int operationId, string scriptCode)
    {
        var pars = new DynamicParameters();
        pars.Add("@OperationId", operationId, DbType.Int32);
        pars.Add("@ScriptCode", scriptCode, DbType.String);

        using var db = new SqlConnection(connectionString);
		
		db.Execute("""
            UPDATE dbo.Scripts
            SET ScriptCode = @ScriptCode
            WHERE ScriptName = (
                SELECT ScriptName
                FROM dbo.Operations
                WHERE OperationId = @OperationId)
            """, pars);
    }

#endregion "Operations"

#region  "Processes"

    public static List<Process>? GetProcesses(DateTime? since = null)
    {
        using var db = new SqlConnection(connectionString);
		
		var sql = since is null
            ? "SELECT * FROM dbo.Processes"
            : "SELECT * FROM dbo.Processes WHERE StartTime >= @Since";
		return db.Query<Process>(sql, new { Since = since })?.ToList();
    }

    public static List<ProcessLogEntry>? GetProcessLog(DateTime? since = null)
    {
        using var db = new SqlConnection(connectionString);
		
		var sql = since is null
            ? "SELECT * FROM dbo.ProcessLog"
            : "SELECT * FROM dbo.ProcessLog WHERE LogTime >= @Since";
		return db.Query<ProcessLogEntry>(sql, new { Since = since })?.ToList();
    }

    public static Process? GetCurrentProcess()
    {
        using var db = new SqlConnection(connectionString);
		
		return db.QuerySingleOrDefault<Process>("SELECT * FROM dbo.CurrentProcess");
    }

    public static int? StartProcess()
    {
        var pars = new DynamicParameters();
        pars.Add("@ProcessId", null, DbType.Int32, ParameterDirection.Output);

        using var db = new SqlConnection(connectionString);
		
		db.Execute("dbo.StartProcess", pars, commandType: CommandType.StoredProcedure);

        return pars.Get<int?>("@ProcessId");
    }

    public static void CompleteProcess()
    {
        using var db = new SqlConnection(connectionString);
		
		db.Execute("dbo.CompleteProcess", commandType: CommandType.StoredProcedure);
    }

    public static void TerminateProcess()
    {
        using var db = new SqlConnection(connectionString);
		
		db.Execute("dbo.TerminateProcess", commandType: CommandType.StoredProcedure);
    }

#endregion "Processes"

#region  "Workers"

    public static List<Worker>? GetWorkers(DateTime? since = null)
    {
        using var db = new SqlConnection(connectionString);
		
		var sql = since is null
            ? "SELECT * FROM dbo.Workers"
            : "SELECT * FROM dbo.Workers WHERE StartTime >= @Since";
		return db.Query<Worker>(sql, new { Since = since })?.ToList();
    }

    public static List<WorkerLogEntry>? GetWorkerLog(DateTime? since = null)
    {
        using var db = new SqlConnection(connectionString);
		
		var sql = since is null
            ? "SELECT * FROM dbo.WorkerLog"
            : "SELECT * FROM dbo.WorkerLog WHERE LogTime >= @Since";
		return db.Query<WorkerLogEntry>(sql, new { Since = since })?.ToList();
    }

    public static List<Worker>? GetCurrentWorkers()
    {
        using var db = new SqlConnection(connectionString);
		
		return db.Query<Worker>("SELECT * FROM dbo.CurrentWorkers")?.ToList();
    }

    public static int? StartWorker()
    {
        var pars = new DynamicParameters();
        pars.Add("@WorkerId", null, DbType.Int32, ParameterDirection.Output);

        using var db = new SqlConnection(connectionString);
		
		db.Execute("dbo.StartWorker", pars, commandType: CommandType.StoredProcedure);

        return pars.Get<int?>("@WorkerId");
    }

    public static void StopWorker(int workerId)
    {
        var pars = new DynamicParameters();
        pars.Add("@WorkerId", workerId, DbType.Int32);

        using var db = new SqlConnection(connectionString);
		
		db.Execute("dbo.StopWorker", pars, commandType: CommandType.StoredProcedure);
    }

    public static void TerminateWorker(int workerId)
    {
        var pars = new DynamicParameters();
        pars.Add("@WorkerId", workerId, DbType.Int32);

        using var db = new SqlConnection(connectionString);
		
		db.Execute("dbo.TerminateWorker", pars, commandType: CommandType.StoredProcedure);
    }

#endregion "Workers"
}