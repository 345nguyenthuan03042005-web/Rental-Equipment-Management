using System.ComponentModel.DataAnnotations.Schema;

namespace WebApi.Models;

[Table("Rental")]
public class Rental
{
    [Column("RentalId")]
    public int Id { get; set; }
    public string MemberId { get; set; } = null!;
    public int StatusId { get; set; }
    [Column("RentalDate")]
    public DateTime Dated { get; set; }
    public List<RentalDetail> Details { get; set; } = [];
}
