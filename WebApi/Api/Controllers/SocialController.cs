using System.ComponentModel.DataAnnotations;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Caching.Memory;
using WebApi.Models;
using WebApi.Services;

namespace WebApi.Api.Controllers;

[ApiController, Route("api/[controller]")]
[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public class SocialController : BaseController
{
    private readonly SocialLogin social;
    private readonly IMemoryCache cache;
    private readonly IConfiguration configuration;
    private readonly ILogger<SocialController> logger;

    public SocialController(SocialLogin social, IMemoryCache cache, IConfiguration configuration,
        ILogger<SocialController> logger)
    {
        this.social = social;
        this.cache = cache;
        this.configuration = configuration;
        this.logger = logger;
    }

    [HttpGet]
    public IEnumerable<string> GetProviders() => SocialLogin.Providers.Where(social.IsEnabled);

    [HttpPost("{provider}/start"), EnableRateLimiting("account")]
    public IActionResult Start(string provider)
    {
        if (!social.IsEnabled(provider)) return NotFound();
        string state = Convert.ToHexString(RandomNumberGenerator.GetBytes(24));
        string key = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        string verifier = RandomNumberGenerator.GetString(
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", 43);
        cache.Set(state, new SocialAttempt(provider, key, verifier), TimeSpan.FromMinutes(5));
        return Ok(new { state, key, url = social.GetAuthorizationUrl(provider, state, verifier) });
    }

    [HttpGet("{provider}/callback"), EnableRateLimiting("account")]
    public async Task<IActionResult> Callback(string provider, string? state, string? code)
    {
        if (state == null || !cache.TryGetValue<SocialAttempt>(state, out var attempt) ||
            attempt == null || attempt.Provider != provider || !social.IsEnabled(provider))
            return BadRequest("Yêu cầu đăng nhập đã hết hạn.");

        lock (attempt)
        {
            if (attempt.Started) return BadRequest("Yêu cầu đăng nhập đã được xử lý.");
            attempt.Started = true;
        }

        Member? member = null;
        try
        {
            if (!string.IsNullOrEmpty(code))
            {
                var profile = await social.GetProfile(provider, code, attempt.Verifier);
                if (string.IsNullOrWhiteSpace(profile.Id)) return BadRequest();
                string id = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(
                    $"social:{provider}:{profile.Id}")))[..32].ToLowerInvariant();
                member = Provider.Member.GetMember(id);
                if (member == null)
                {
                    string name = profile.Name.Trim();
                    if (string.IsNullOrEmpty(name)) name = provider;
                    if (name.Length > 16) name = name[..16].TrimEnd();
                    member = new Member
                    {
                        Id = id, Email = $"{provider}+{id}@example.invalid", GivenName = name,
                        Password = BCrypt.Net.BCrypt.HashPassword(Convert.ToHexString(RandomNumberGenerator.GetBytes(24))),
                        Role = Role.Member, IsActive = true
                    };
                    if (Provider.Member.Add(member) <= 0) member = Provider.Member.GetMember(id);
                }
            }
        }
        catch (Exception ex) when (ex is HttpRequestException or JsonException or KeyNotFoundException
            or InvalidOperationException or TaskCanceledException or Microsoft.EntityFrameworkCore.DbUpdateException
            or Microsoft.Data.SqlClient.SqlException)
        {
            if (ex is not HttpRequestException { StatusCode: not null })
                logger.LogWarning("Social login {Provider} could not complete the callback ({ErrorType}).",
                    provider, ex.GetType().Name);
            member = null;
        }
        finally
        {
            lock (attempt)
            {
                attempt.MemberId = member is { IsActive: true } ? member.Id : null;
                if (attempt.MemberId != null)
                    attempt.CompletionCode = RandomNumberGenerator.GetInt32(100000000).ToString("D8");
                attempt.Finished = true;
            }
        }
        if (string.IsNullOrEmpty(code))
        {
            logger.LogInformation("Social login {Provider} returned without an authorization code.", provider);
            return Content("Chưa cấp quyền đăng nhập. Hãy quay lại ứng dụng để thử lại.", "text/plain; charset=utf-8");
        }
        return Content(attempt.MemberId == null ? "Đăng nhập chưa thành công. Hãy quay lại ứng dụng." :
            $"Nhập mã {attempt.CompletionCode} vào ứng dụng để hoàn tất đăng nhập.", "text/plain; charset=utf-8");
    }

    [HttpPost("result")]
    public IActionResult Result(SocialResultInput obj)
    {
        if (!cache.TryGetValue<SocialAttempt>(obj.State, out var attempt) || attempt == null ||
            !CryptographicOperations.FixedTimeEquals(Encoding.ASCII.GetBytes(obj.Key), Encoding.ASCII.GetBytes(attempt.Key)))
            return NotFound();

        lock (attempt)
        {
            if (attempt.Used) return NotFound();
            if (!attempt.Finished) return Accepted();
            if (attempt.CompletionCode != null && !CryptographicOperations.FixedTimeEquals(
                Encoding.ASCII.GetBytes(obj.Code ?? ""), Encoding.ASCII.GetBytes(attempt.CompletionCode)))
            {
                attempt.CodeAttempts++;
                if (attempt.CodeAttempts >= 5)
                {
                    attempt.Used = true;
                    cache.Remove(obj.State);
                }
                return BadRequest("Mã xác nhận không đúng.");
            }
            attempt.Used = true;
        }
        cache.Remove(obj.State);
        var member = attempt.MemberId == null ? null : Provider.Member.GetMember(attempt.MemberId);
        if (member is not { IsActive: true })
            return UnprocessableEntity("Nhà cung cấp chưa xác thực được tài khoản.");
        return Ok(new { member.Email, token = Helper.GenerateToken(member, configuration) });
    }
}

public record SocialResultInput([Required, StringLength(48, MinimumLength = 48)] string State,
    [Required, StringLength(64, MinimumLength = 64)] string Key,
    [RegularExpression("[0-9]{8}")] string? Code);

internal class SocialAttempt(string provider, string key, string verifier)
{
    public string Provider { get; } = provider;
    public string Key { get; } = key;
    public string Verifier { get; } = verifier;
    public bool Started { get; set; }
    public bool Finished { get; set; }
    public bool Used { get; set; }
    public string? CompletionCode { get; set; }
    public int CodeAttempts { get; set; }
    public string? MemberId { get; set; }
}
