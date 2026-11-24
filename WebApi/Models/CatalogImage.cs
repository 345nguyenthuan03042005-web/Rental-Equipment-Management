using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace WebApi.Models;

[Table("CatalogImage", Schema = "dbo"), PrimaryKey(nameof(Directory), nameof(Name))]
public class CatalogImage
{
    [Column(TypeName = "varchar(16)")]
    public string Directory { get; set; } = null!;

    [Column(TypeName = "varchar(32)")]
    public string Name { get; set; } = null!;

    [Column(TypeName = "varbinary(max)")]
    public byte[] Content { get; set; } = null!;
}
