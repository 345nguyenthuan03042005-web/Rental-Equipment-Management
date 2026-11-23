using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace WebApi.Models;

[Table("RentalDetail"), PrimaryKey(nameof(RentalId), nameof(EquipmentId))]
public class RentalDetail
{
    public int RentalId { get; set; }
    public int EquipmentId { get; set; }
    public Equipment? Equipment { get; set; }
    public short Quantity { get; set; }
    [Column(TypeName = "decimal(10, 2)")]
    public decimal Price { get; set; }
    public string? Unit { get; set; }
}
