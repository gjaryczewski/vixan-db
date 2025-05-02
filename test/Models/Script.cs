namespace Vixan.Db.Test.Models;

public class Script
{
    public required string ScriptName { get; set; }

    public required string ScriptCode { get; set; }

    public int SeqNum { get; set; }

    public DateTime SysValidFrom { get; set; }

    public DateTime SysValidTo { get; set; }
}