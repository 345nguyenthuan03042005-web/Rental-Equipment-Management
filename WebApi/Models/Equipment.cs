using System.ComponentModel.DataAnnotations.Schema;

namespace WebApi.Models;

[Table("Equipment")]
public class Equipment
{
    public const string Available = "Sẵn sàng";
    public const string Rented = "Đang cho thuê";
    public const string Maintenance = "Đang bảo trì";

    [Column("EquipmentId")]
    public int Id { get; set; }
    public short SubCategoryId { get; set; }
    public SubCategory? SubCategory { get; set; }
    [Column("EquipmentName")]
    public string Name { get; set; } = null!;
    public string ImageUrl { get; set; } = null!;
    [Column(TypeName = "decimal(10, 2)")]
    public decimal Price { get; set; }
    public string? Brand { get; set; }
    public string? Model { get; set; }
    public string? Specifications { get; set; }
    public string? Unit { get; set; }
    public string? Status { get; set; }
}
