using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using WebApi.Models;

namespace WebApi.Models;
[Table("Member")]
public class Member
{
    [Column("MemberId")]
    public string? Id { get; set; } = null!;

    [Required, StringLength(16)]
    public string GivenName { get; set; } = null!;

    [StringLength(16)]
    public string? Surname { get; set; }

    [Required, EmailAddress, StringLength(64)]
    public string Email { get; set; } = null!;
    [Required, StringLength(72)]
    public string Password { get; set; } = null!;
    public Role Role { get; set; }
    public bool EmailVerified { get; set; }
    public int SecurityVersion { get; set; }
    public bool IsActive { get; set; } = true;
}
