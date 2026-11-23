using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Api.Controllers;

[ApiController, Route("api/[controller]")]
public class AuthController : BaseController
{
    [HttpGet, Authorize]
    public IActionResult GetMember()
    {
        var member = Provider.Member.GetMember(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        return member == null ? NotFound() :
            Ok(new { member.Id, member.Surname, member.GivenName, member.Email, member.Role, member.IsActive, member.EmailVerified });
    }

    [HttpPost("register")]
    public int Add(Member obj)
    {
        if (Encoding.UTF8.GetByteCount(obj.Password) > 72 ||
            obj.Email.Trim().EndsWith("@example.invalid", StringComparison.OrdinalIgnoreCase))
            return -2;

        obj.Id = Guid.NewGuid().ToString("N");
        obj.Password = BCrypt.Net.BCrypt.HashPassword(obj.Password);
        obj.Role = Role.Member;
        obj.IsActive = true;
        obj.EmailVerified = false;
        obj.SecurityVersion = 0;
        return Provider.Member.Add(obj);
    }

    [Authorize, HttpPut("password")]
    public ActionResult<int> ChangePassword(PasswordInput obj)
    {
        var id = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var result = Provider.Member.ChangePassword(id, obj.CurrentPassword, obj.NewPassword);
        return result > 0 ? Ok(result) : BadRequest("Mật khẩu hiện tại không đúng hoặc mật khẩu mới quá dài.");
    }

    [HttpPost("login")]
    public LoginResponse Login(LoginModel obj, [FromServices] IConfiguration configuration)
        => Provider.Member.Login(obj, configuration);
}

public record PasswordInput(
    [Required, StringLength(72)] string CurrentPassword,
    [Required, StringLength(72, MinimumLength = 6)] string NewPassword);
