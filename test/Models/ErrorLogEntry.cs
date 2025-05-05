namespace Vixan.Db.Test.Models;

public class ErrorLogEntry
{
    public int ErrorLogId { get; set; }

    public DateTime LogTime { get; set; }

    public int? ProcessId { get; set; }

    public int? WorkerId { get; set; }

    public int? OperationId { get; set; }

    public required string ProcedureName { get; set; }

    public int LineNum { get; set; }

    public int ErrorNum { get; set; }

    public required string ErrorMessage { get; set; }

    public required string UserLogin { get; set; }

    public required string UserHost { get; set; }
}