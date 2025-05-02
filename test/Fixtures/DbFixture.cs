
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
		
		var sql = "SELECT GETUTCDATE()";
        return db.ExecuteScalar<DateTime>(sql);
    }

    public static List<ErrorLogEntry>? GetErrorLogSince(DateTime startTime)
    {
        using var db = new SqlConnection(connectionString);
		
		var sql = "SELECT * FROM dbo.ErrorLog WHERE LogTime >= @StartTime";
		return db.Query<ErrorLogEntry>(sql, new { StartTime = startTime })?.ToList();
    }
}