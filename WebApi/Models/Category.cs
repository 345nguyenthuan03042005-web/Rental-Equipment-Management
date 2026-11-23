using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WebApi.Models;
[Table ("Category")]
public class Category
{
    [Column ("CategoryId")]
    public short Id {get; set;}
    [Column ("CategoryName")]
    [Required, StringLength(64)]
    public string  Name {get; set;} = null!;
    [Required, StringLength(128)]
    public string Title {get; set;} = null!;
    [Required, StringLength(1024)]
    public string Description {get; set;} = null!;
    [StringLength(16)]
    public string Icon {get; set;} = "";
}

