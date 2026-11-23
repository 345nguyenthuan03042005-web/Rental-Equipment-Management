using System.ComponentModel.DataAnnotations;
using System.Net.Mail;
using System.Security.Cryptography;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using WebApi.Models;
using WebApi.Services;

namespace WebApi.Api.Controllers;

[ApiController, Route("api/[controller]"), EnableRateLimiting("account")]
public class EmailController : BaseController
{
    private readonly IConfiguration configuration;
    private readonly ILogger<EmailController> logger;

    public EmailController(IConfiguration configuration, ILogger<EmailController> logger)
    {
        this.configuration = configuration;
        this.logger = logger;
    }

    [HttpGet]
    public object GetOptions() => new { enabled = EmailSender.IsConfigured(configuration) };

    [HttpPost("send")]
    public async Task<IActionResult> Send(EmailCodeRequest obj)
    {
        if (!EmailSender.IsConfigured(configuration)) return StatusCode(503);
        if (obj.Purpose is not ("verify" or "reset")) return BadRequest();
        var member = Provider.Member.GetMemberByEmail(obj.Email.Trim());
        if (member is { IsActive: true } && !member.Email.EndsWith("@example.invalid", StringComparison.Ordinal) &&
            (obj.Purpose == "reset" || !member.EmailVerified))
        {
            string code = RandomNumberGenerator.GetInt32(100000000).ToString("D8");
            string hash = MemberRepository.HashEmailCode(member.Id!, obj.Purpose, code, configuration["Jwt:SecretKey"]!);
            if (Provider.Member.SaveEmailCode(member.Id!, obj.Purpose, hash) > 0)
            {
                try
                {
                    await EmailSender.SendCode(configuration, member.Email, code, obj.Purpose == "reset");
                }
                catch (SmtpException ex)
                {
                    logger.LogWarning(ex, "Could not send account email");
                }
            }
        }
        return Accepted();
    }

    [HttpPost("verify")]
    public IActionResult Verify(VerifyEmailInput obj) =>
        Provider.Member.UseEmailCode(obj.Email.Trim(), "verify", obj.Code, configuration["Jwt:SecretKey"]!, null)
            ? Ok() : BadRequest("Mã xác thực sai hoặc đã hết hạn.");

    [HttpPost("reset")]
    public IActionResult Reset(ResetEmailInput obj) =>
        Provider.Member.UseEmailCode(obj.Email.Trim(), "reset", obj.Code, configuration["Jwt:SecretKey"]!, obj.Password)
            ? Ok() : BadRequest("Mã sai, đã hết hạn hoặc mật khẩu không hợp lệ.");
}

public record EmailCodeRequest([Required, EmailAddress, StringLength(64)] string Email, [Required] string Purpose);
public record VerifyEmailInput([Required, EmailAddress, StringLength(64)] string Email, [Required, RegularExpression("[0-9]{8}")] string Code);
public record ResetEmailInput([Required, EmailAddress, StringLength(64)] string Email, [Required, RegularExpression("[0-9]{8}")] string Code,
    [Required, StringLength(72, MinimumLength = 6)] string Password);
