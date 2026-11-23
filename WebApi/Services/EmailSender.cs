using System.Net;
using System.Net.Mail;

namespace WebApi.Services;

public static class EmailSender
{
    public static bool IsConfigured(IConfiguration configuration) =>
        !string.IsNullOrWhiteSpace(configuration["Email:Host"]) &&
        !string.IsNullOrWhiteSpace(configuration["Email:From"]);

    public static async Task SendCode(IConfiguration configuration, string email, string code, bool reset)
    {
        using var client = new SmtpClient(configuration["Email:Host"]!,
            configuration.GetValue("Email:Port", 587))
        {
            EnableSsl = configuration.GetValue("Email:EnableSsl", true)
        };
        string? user = configuration["Email:User"];
        if (!string.IsNullOrEmpty(user))
            client.Credentials = new NetworkCredential(user, configuration["Email:Password"]);

        using var message = new MailMessage(configuration["Email:From"]!, email,
            reset ? "Đặt lại mật khẩu" : "Xác thực email",
            $"Mã của bạn là {code}. Mã có hiệu lực trong 10 phút.");
        await client.SendMailAsync(message);
    }
}
