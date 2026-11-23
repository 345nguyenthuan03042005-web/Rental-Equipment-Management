using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using WebApi.Models;

[Table("Cart")]
public class Cart
{
    [Column("CartId")]
    public int Id { get; set; }
    public string? MemberId { get; set; }
    [Range(1, int.MaxValue)]
    public int EquipmentId { get; set; }
    public Equipment? Equipment { get; set; }
    [Range(1, 365)]
    public short Quantity { get; set; }
}
