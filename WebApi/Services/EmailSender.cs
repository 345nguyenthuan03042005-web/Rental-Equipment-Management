using System.Net;
using System.Net.Http.Headers;
using System.Net.Mail;

namespace WebApi.Services;

public class EmailSender(IConfiguration configuration, IHttpClientFactory factory)
{
    private string? ApiKey => configuration["Email:ResendApiKey"]?.Trim();
    private string? From => configuration["Email:From"]?.Trim();

    public bool IsConfigured => !string.IsNullOrWhiteSpace(From) &&
        (!string.IsNullOrEmpty(ApiKey) || !string.IsNullOrWhiteSpace(configuration["Email:Host"]));

    public async Task SendCode(string email, string code, bool reset)
    {
        string subject = reset ? "Đặt lại mật khẩu" : "Xác thực email";
        string messageText = $"Mã của bạn là {code}. Mã có hiệu lực trong 10 phút.";
        if (!string.IsNullOrEmpty(ApiKey))
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.resend.com/emails")
            {
                Content = JsonContent.Create(new { from = From, to = new[] { email }, subject, text = messageText })
            };
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", ApiKey);
            using var response = await factory.CreateClient("external").SendAsync(request);
            response.EnsureSuccessStatusCode();
            return;
        }

        using var client = new SmtpClient(configuration["Email:Host"]!,
            configuration.GetValue("Email:Port", 587))
        {
            EnableSsl = configuration.GetValue("Email:EnableSsl", true)
        };
        string? user = configuration["Email:User"];
        if (!string.IsNullOrEmpty(user))
            client.Credentials = new NetworkCredential(user, configuration["Email:Password"]);

        using var message = new MailMessage(From!, email, subject, messageText);
        await client.SendMailAsync(message);
    }
}
