
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
        TRUNCATE TABLE dbo.ThreadLog;
        TRUNCATE TABLE dbo.Threads;

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
            : "SELECT * FROM dbo.ErrorLog WHERE LogTime >= @StartTime";
		return db.Query<ErrorLogEntry>(sql, new { StartTime = since })?.ToList();
    }

#endregion "Errors"

#region  "Operations"

    public static List<OperationLogEntry>? GetOperationLog(DateTime? since = null)
    {
        using var db = new SqlConnection(connectionString);
		
		var sql = since is null
            ? "SELECT * FROM dbo.OperationLog"
            : "SELECT * FROM dbo.OperationLog WHERE LogTime >= @StartTime";
		return db.Query<OperationLogEntry>(sql, new { StartTime = since })?.ToList();
    }

    public static int NextOperationToRun()
    {
        using var db = new SqlConnection(connectionString);
		
		return db.ExecuteScalar<int>("SELECT dbo.NextOperationToRun()");
    }

    public static void RunOperation(int operationId, int threadId)
    {
        var pars = new DynamicParameters();
        pars.Add("@OperationId", operationId, DbType.Int32);
        pars.Add("@ThreadId", threadId, DbType.Int32);

        using var db = new SqlConnection(connectionString);
		
		db.Execute("dbo.RunOperation", pars, commandType: CommandType.StoredProcedure);
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

    public static List<ProcessLogEntry>? GetProcessLog(DateTime? since = null)
    {
        using var db = new SqlConnection(connectionString);
		
		var sql = since is null
            ? "SELECT * FROM dbo.ProcessLog"
            : "SELECT * FROM dbo.ProcessLog WHERE LogTime >= @StartTime";
		return db.Query<ProcessLogEntry>(sql, new { StartTime = since })?.ToList();
    }

    public static int StartProcess()
    {
        var pars = new DynamicParameters();
        pars.Add("@ProcessId", null, DbType.Int32, ParameterDirection.Output);

        using var db = new SqlConnection(connectionString);
		
		db.Execute("dbo.StartProcess", pars, commandType: CommandType.StoredProcedure);

        return pars.Get<int>("@ProcessId");
    }

#endregion "Processes"

#region  "Threads"

    public static List<ThreadLogEntry>? GetThreadLog(DateTime? since = null)
    {
        using var db = new SqlConnection(connectionString);
		
		var sql = since is null
            ? "SELECT * FROM dbo.ThreadLog"
            : "SELECT * FROM dbo.ThreadLog WHERE LogTime >= @StartTime";
		return db.Query<ThreadLogEntry>(sql, new { StartTime = since })?.ToList();
    }

    public static int StartThread()
    {
        var pars = new DynamicParameters();
        pars.Add("@ThreadId", null, DbType.Int32, ParameterDirection.Output);

        using var db = new SqlConnection(connectionString);
		
		db.Execute("dbo.StartThread", pars, commandType: CommandType.StoredProcedure);

        return pars.Get<int?>("@ThreadId")
            ?? throw new ArgumentException("Thread ID is unavailable as the output value.");
    }

#endregion "Threads"
}