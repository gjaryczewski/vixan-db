
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
        var sql = "SELECT GETUTCDATE()";

        using var db = new SqlConnection(connectionString);
		
        return db.ExecuteScalar<DateTime>(sql);
    }

#region "Errors"


    public static List<ErrorLogEntry>? GetErrorLog()
    {
        var sql = "SELECT * FROM dbo.ErrorLog";

        using var db = new SqlConnection(connectionString);
		
		return db.Query<ErrorLogEntry>(sql)?.ToList();
    }

    public static List<ErrorLogEntry>? GetErrorLogSince(DateTime startTime)
    {
		var sql = "SELECT * FROM dbo.ErrorLog WHERE LogTime >= @StartTime";

        var pars = new DynamicParameters();
        pars.Add("@StartTime", startTime, DbType.DateTime);

        using var db = new SqlConnection(connectionString);
		
		return db.Query<ErrorLogEntry>(sql, pars)?.ToList();
    }

    public static List<ErrorLogEntry>? GetCurrentErrors()
    {
        var sql = "SELECT * FROM dbo.CurrentErrors";

        using var db = new SqlConnection(connectionString);
		
		return db.Query<ErrorLogEntry>(sql)?.ToList();
    }

#endregion "Errors"

#region  "Operations"

    public static List<Operation>? GetOperations()
    {
        var sql = "SELECT * FROM dbo.Operations";
    
        using var db = new SqlConnection(connectionString);
		
		return db.Query<Operation>(sql)?.ToList();
    }

    public static List<Operation>? GetOperationsSince(DateTime startTime)
    {
		var sql = "SELECT * FROM dbo.Operations WHERE StartTime >= @StartTime";

        var pars = new DynamicParameters();
        pars.Add("@StartTime", startTime, DbType.DateTime);

        using var db = new SqlConnection(connectionString);
		
		return db.Query<Operation>(sql, pars)?.ToList();
    }

    public static Operation? GetOperation(int operationId)
    {
        var sql = "SELECT * FROM dbo.Operations WHERE OperationId = @OperationId";

        var pars = new DynamicParameters();
        pars.Add("@OperationId", operationId, DbType.Int32);

        using var db = new SqlConnection(connectionString);
		
		return db.QuerySingleOrDefault<Operation>(sql, pars);
    }

    public static List<OperationLogEntry>? GetOperationLog()
    {
        var sql = "SELECT * FROM dbo.OperationLog";

        using var db = new SqlConnection(connectionString);
		
		return db.Query<OperationLogEntry>(sql)?.ToList();
    }

    public static List<OperationLogEntry>? GetOperationLogSince(DateTime startTime)
    {
		var sql = "SELECT * FROM dbo.OperationLog WHERE LogTime >= @StartTime";

        var pars = new DynamicParameters();
        pars.Add("@StartTime", startTime, DbType.DateTime);

        using var db = new SqlConnection(connectionString);
		
		return db.Query<OperationLogEntry>(sql, pars)?.ToList();
    }

    public static List<Worker>? GetCurrentOperations()
    {
        var sql = "SELECT * FROM dbo.CurrentOperations";

        using var db = new SqlConnection(connectionString);
		
		return db.Query<Worker>(sql)?.ToList();
    }

    public static int NextOperationToRun()
    {
        var sql = "SELECT dbo.NextOperationToRun()";

        using var db = new SqlConnection(connectionString);
		
		return db.ExecuteScalar<int>(sql);
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

    public static void SetScriptCode(int operationId, string scriptCode)
    {
        var sql = """
            UPDATE dbo.Scripts
            SET ScriptCode = @ScriptCode
            WHERE ScriptName = (
                SELECT ScriptName
                FROM dbo.Operations
                WHERE OperationId = @OperationId)
            """;

        var pars = new DynamicParameters();
        pars.Add("@OperationId", operationId, DbType.Int32);
        pars.Add("@ScriptCode", scriptCode, DbType.String);

        using var db = new SqlConnection(connectionString);
		
		db.Execute(sql, pars);
    }

#endregion "Operations"

#region  "Processes"

    public static List<Process>? GetProcesses()
    {
        var sql = "SELECT * FROM dbo.Processes";

        using var db = new SqlConnection(connectionString);
		
		return db.Query<Process>(sql)?.ToList();
    }

    public static List<Process>? GetProcessesSince(DateTime startTime)
    {
		var sql = "SELECT * FROM dbo.Processes WHERE StartTime >= @StartTime";

        var pars = new DynamicParameters();
        pars.Add("@StartTime", startTime, DbType.DateTime);

        using var db = new SqlConnection(connectionString);
		
		return db.Query<Process>(sql, pars)?.ToList();
    }

    public static Process? GetProcess(int processId)
    {
        var sql = "SELECT * FROM dbo.Processes WHERE ProcessId = @ProcessId";

        var pars = new DynamicParameters();
        pars.Add("@ProcessId", processId, DbType.Int32);

        using var db = new SqlConnection(connectionString);
		
		return db.QuerySingleOrDefault<Process>(sql, pars);
    }

    public static List<ProcessLogEntry>? GetProcessLog()
    {
        var sql = "SELECT * FROM dbo.ProcessLog";

        using var db = new SqlConnection(connectionString);
		
		return db.Query<ProcessLogEntry>(sql)?.ToList();
    }

    public static List<ProcessLogEntry>? GetProcessLogSince(DateTime startTime)
    {
		var sql = "SELECT * FROM dbo.ProcessLog WHERE LogTime >= @StartTime";

        var pars = new DynamicParameters();
        pars.Add("@StartTime", startTime, DbType.DateTime);

        using var db = new SqlConnection(connectionString);
		
		return db.Query<ProcessLogEntry>(sql, pars)?.ToList();
    }

    public static Process? GetCurrentProcess()
    {
        var sql = "SELECT * FROM dbo.CurrentProcess";

        using var db = new SqlConnection(connectionString);
		
		return db.QuerySingleOrDefault<Process>(sql);
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

    public static List<Worker>? GetWorkers()
    {
        var sql = "SELECT * FROM dbo.Workers";
    
        using var db = new SqlConnection(connectionString);
		
		return db.Query<Worker>(sql)?.ToList();
    }

    public static List<Worker>? GetWorkersSince(DateTime startTime)
    {
		var sql = "SELECT * FROM dbo.Workers WHERE StartTime >= @StartTime";

        var pars = new DynamicParameters();
        pars.Add("@StartTime", startTime, DbType.DateTime);

        using var db = new SqlConnection(connectionString);
		
		return db.Query<Worker>(sql, pars)?.ToList();
    }

    public static Worker? GetWorker(int operationId)
    {
        var sql = "SELECT * FROM dbo.Workers WHERE WorkerId = @WorkerId";

        var pars = new DynamicParameters();
        pars.Add("@WorkerId", operationId, DbType.Int32);

        using var db = new SqlConnection(connectionString);
		
		return db.QuerySingleOrDefault<Worker>(sql, pars);
    }

    public static List<WorkerLogEntry>? GetWorkerLog()
    {
        var sql = "SELECT * FROM dbo.WorkerLog";
    
        using var db = new SqlConnection(connectionString);
		
		return db.Query<WorkerLogEntry>(sql)?.ToList();
    }

    public static List<WorkerLogEntry>? GetWorkerLogSince(DateTime startTime)
    {
		var sql = "SELECT * FROM dbo.WorkerLog WHERE LogTime >= @StartTime";

        var pars = new DynamicParameters();
        pars.Add("@StartTime", startTime, DbType.DateTime);

        using var db = new SqlConnection(connectionString);
		
		return db.Query<WorkerLogEntry>(sql, pars)?.ToList();
    }

    public static List<Worker>? GetCurrentWorkers()
    {
        var sql = "SELECT * FROM dbo.CurrentWorkers";

        using var db = new SqlConnection(connectionString);
		
		return db.Query<Worker>(sql)?.ToList();
    }

    public static Worker GetFirstCurrentWorker()
    {
        var sql = "SELECT * FROM dbo.CurrentWorkers";
    
        using var db = new SqlConnection(connectionString);
		
		return db.QueryFirst<Worker>(sql);
    }

    public static Worker? GetFirstCurrentWorkerOrDefault()
    {
        var sql = "SELECT * FROM dbo.CurrentWorkers";
    
        using var db = new SqlConnection(connectionString);
		
		return db.QueryFirstOrDefault<Worker>(sql);
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