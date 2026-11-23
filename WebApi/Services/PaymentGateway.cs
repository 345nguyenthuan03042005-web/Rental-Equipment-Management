using System.Globalization;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using WebApi.Models;

namespace WebApi.Services;

public class PaymentGateway
{
    private readonly IConfiguration configuration;
    private readonly HttpClient client;

    public PaymentGateway(IConfiguration configuration, IHttpClientFactory factory)
    {
        this.configuration = configuration;
        client = factory.CreateClient("external");
    }

    private string? Option(string key) => configuration[$"Payment:{key}"];
    public string? Terminal => Option("VnPay:TmnCode");
    private string VnPayUrl => Option("VnPay:Url") ?? "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";

    public bool Enabled(string method) => method switch
    {
        "vnpay" => Set("VnPay:TmnCode") && Set("VnPay:Secret") && Https(VnPayUrl) &&
            (VnPayUrl.StartsWith("https://sandbox.vnpayment.vn/", StringComparison.Ordinal) ||
             VnPayUrl.StartsWith("https://pay.vnpay.vn/", StringComparison.Ordinal)) && Https(Option("VnPay:ReturnUrl")),
        "vietqr" => Set("PayOs:ClientId") && Set("PayOs:ApiKey") && Set("PayOs:ChecksumKey") &&
            Https(Option("PayOs:ReturnUrl")) && Https(Option("PayOs:CancelUrl")),
        _ => false
    };

    private bool Set(string key) => !string.IsNullOrWhiteSpace(Option(key));
    private static bool Https(string? url) => Uri.TryCreate(url, UriKind.Absolute, out var uri) && uri.Scheme == "https";

    public string CreateVnPayUrl(RentalPayment payment, string ip)
    {
        var created = payment.CreatedAt.AddHours(7);
        var fields = new Dictionary<string, string>
        {
            ["vnp_Version"] = "2.1.0", ["vnp_Command"] = "pay",
            ["vnp_TmnCode"] = Terminal!, ["vnp_Amount"] = Num(payment.Amount * 100),
            ["vnp_CurrCode"] = "VND", ["vnp_TxnRef"] = Num(payment.Id),
            ["vnp_OrderInfo"] = $"Thanh toan phieu thue {payment.RentalId}",
            ["vnp_OrderType"] = "other", ["vnp_Locale"] = "vn",
            ["vnp_ReturnUrl"] = Option("VnPay:ReturnUrl")!, ["vnp_IpAddr"] = ip,
            ["vnp_CreateDate"] = created.ToString("yyyyMMddHHmmss", CultureInfo.InvariantCulture),
            ["vnp_ExpireDate"] = created.AddMinutes(15).ToString("yyyyMMddHHmmss", CultureInfo.InvariantCulture)
        };
        string query = Data(fields, true);
        return $"{VnPayUrl}?{query}&vnp_SecureHash={Sign(query, Option("VnPay:Secret")!, true)}";
    }

    public bool ValidVnPaySignature(IEnumerable<KeyValuePair<string, string>> fields, string signature) =>
        Enabled("vnpay") && Matches(signature, Sign(Data(fields, true), Option("VnPay:Secret")!, true));

    public async Task<string> CreateVietQrUrl(RentalPayment payment)
    {
        string description = $"THUE{(payment.Id % 100000).ToString("D5", CultureInfo.InvariantCulture)}";
        string returnUrl = Option("PayOs:ReturnUrl")!;
        string cancelUrl = Option("PayOs:CancelUrl")!;
        var fields = new Dictionary<string, string>
        {
            ["amount"] = Num(payment.Amount), ["cancelUrl"] = cancelUrl,
            ["description"] = description, ["orderCode"] = Num(payment.Id), ["returnUrl"] = returnUrl
        };
        string signature = Sign(Data(fields, false), Option("PayOs:ChecksumKey")!, false);
        using var request = PayOsRequest(HttpMethod.Post);
        request.Content = JsonContent.Create(new
        {
            orderCode = payment.Id, amount = payment.Amount, description, cancelUrl, returnUrl,
            expiredAt = new DateTimeOffset(DateTime.SpecifyKind(payment.CreatedAt, DateTimeKind.Utc)).AddMinutes(15).ToUnixTimeSeconds(),
            signature
        });
        using var response = await client.SendAsync(request);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        if (response.IsSuccessStatusCode && json.RootElement.GetProperty("code").GetString() == "00")
        {
            string url = json.RootElement.GetProperty("data").GetProperty("checkoutUrl").GetString()!;
            if (Uri.TryCreate(url, UriKind.Absolute, out var uri) && uri.Scheme == "https" && uri.Host == "pay.payos.vn")
                return url;
        }
        // A previous request can have succeeded before the local response was saved.
        var status = await GetVietQrStatus(payment.Id, payment.Amount);
        if (status.Id.Length == 32 && status.Id.All(Uri.IsHexDigit))
            return $"https://pay.payos.vn/web/{status.Id}";
        throw new HttpRequestException("Could not create VietQR payment link.");
    }

    public async Task<(string Id, int State)> GetVietQrStatus(long id, long amount)
    {
        using var request = PayOsRequest(HttpMethod.Get, "/" + Num(id));
        using var response = await client.SendAsync(request);
        response.EnsureSuccessStatusCode();
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var root = json.RootElement;
        if (root.GetProperty("code").GetString() != "00") throw new HttpRequestException("Could not read VietQR payment.");
        var data = root.GetProperty("data");
        if (data.GetProperty("orderCode").GetInt64() != id || data.GetProperty("amount").GetInt64() != amount)
            throw new HttpRequestException("Unexpected VietQR payment.");
        string providerId = data.GetProperty("id").GetString()!;
        int state = data.GetProperty("status").GetString() switch
        {
            "PAID" when data.GetProperty("amountPaid").GetInt64() == amount => RentalPayment.Paid,
            "CANCELLED" or "EXPIRED" when data.GetProperty("amountPaid").GetInt64() == 0 => RentalPayment.Failed,
            _ => RentalPayment.Pending
        };
        return (providerId, state);
    }

    public bool ValidPayOsWebhook(JsonElement data, string signature)
    {
        if (!Enabled("vietqr") || data.ValueKind != JsonValueKind.Object) return false;
        if (data.EnumerateObject().Any(p => p.Value.ValueKind is JsonValueKind.Array or JsonValueKind.Object))
            return false;
        var fields = data.EnumerateObject().Select(p =>
        {
            string value = p.Value.ToString();
            return KeyValuePair.Create(p.Name, value is "null" or "undefined" ? "" : value);
        });
        return Matches(signature, Sign(Data(fields, false), Option("PayOs:ChecksumKey")!, false));
    }

    private HttpRequestMessage PayOsRequest(HttpMethod method, string path = "")
    {
        var request = new HttpRequestMessage(method, "https://api-merchant.payos.vn/v2/payment-requests" + path);
        request.Headers.Add("x-client-id", Option("PayOs:ClientId"));
        request.Headers.Add("x-api-key", Option("PayOs:ApiKey"));
        return request;
    }

    private static string Num(long value) => value.ToString(CultureInfo.InvariantCulture);

    private static string Data(IEnumerable<KeyValuePair<string, string>> fields, bool encode) =>
        string.Join("&", fields.OrderBy(p => p.Key, StringComparer.Ordinal)
            .Select(p => encode ? $"{WebUtility.UrlEncode(p.Key)}={WebUtility.UrlEncode(p.Value)}" : $"{p.Key}={p.Value}"));

    private static string Sign(string data, string secret, bool vnPay)
    {
        var key = Encoding.UTF8.GetBytes(secret);
        var text = Encoding.UTF8.GetBytes(data);
        return Convert.ToHexString(vnPay ? HMACSHA512.HashData(key, text) : HMACSHA256.HashData(key, text)).ToLowerInvariant();
    }

    private static bool Matches(string actual, string expected) =>
        CryptographicOperations.FixedTimeEquals(Encoding.ASCII.GetBytes(actual.ToLowerInvariant()), Encoding.ASCII.GetBytes(expected));
}
