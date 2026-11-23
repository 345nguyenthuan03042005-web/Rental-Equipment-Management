using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Api.Controllers;

[Authorize(Roles = nameof(Role.Admin)), ApiController, Route("api/[controller]")]
public class MemberController : BaseController
{
    [HttpGet]
    public IEnumerable<object> GetMembers() => Provider.Member.GetMembers().Select(p => new
    {
        p.Id, p.GivenName, p.Surname, p.Email, p.Role, p.IsActive
    });

    [HttpPut("{id}")]
    public ActionResult<int> Update(string id, MemberInput obj)
    {
        if (!Enum.IsDefined(obj.Role)) return BadRequest("Vai trò không hợp lệ.");
        if (string.Equals(id, User.FindFirstValue(ClaimTypes.NameIdentifier), StringComparison.OrdinalIgnoreCase) &&
            (!obj.IsActive || obj.Role != Role.Admin))
            return BadRequest("Không thể tự khóa hoặc bỏ quyền quản trị của mình.");

        int result = Provider.Member.Update(id, obj.GivenName.Trim(), obj.Surname?.Trim(), obj.Role, obj.IsActive);
        return result > 0 ? Ok(result) : NotFound();
    }
}

public record MemberInput(
    [Required, StringLength(16)] string GivenName,
    [StringLength(16)] string? Surname,
    Role Role,
    bool IsActive);
