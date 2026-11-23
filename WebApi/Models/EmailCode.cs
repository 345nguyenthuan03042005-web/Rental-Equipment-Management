using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace WebApi.Models;

[Table("EmailCode"), PrimaryKey(nameof(MemberId), nameof(Purpose))]
public class EmailCode
{
    public string MemberId { get; set; } = null!;
    public string Purpose { get; set; } = null!;
    public string CodeHash { get; set; } = null!;
    public DateTime SentAt { get; set; }
    public int Attempts { get; set; }
}
