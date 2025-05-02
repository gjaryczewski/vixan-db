namespace Vixan.Db.Test.Models;

public class OperationLogEntry
{
    public int OperationLogId { get; set; }
    
    public DateTime LogTime { get; set; }

    public int OperationId { get; set; }

    public required string Status { get; set; }

    public required string UserLogin { get; set; }

    public required string UserHost { get; set; }
}