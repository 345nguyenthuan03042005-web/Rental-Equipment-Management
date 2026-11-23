using System.Globalization;
using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using WebApi.Models;
using WebApi.Services;

namespace WebApi.Api.Controllers;

[Authorize, ApiController, Route("api/[controller]")]
public class PaymentController : BaseController
{
    private readonly PaymentGateway gateway;
    private readonly ILogger<PaymentController> logger;

    public PaymentController(PaymentGateway gateway, ILogger<PaymentController> logger)
    {
        this.gateway = gateway;
        this.logger = logger;
    }

    private string MemberId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

    [HttpGet("{rentalId:int}")]
    public async Task<IActionResult> GetPayment(int rentalId)
    {
        var rental = Provider.Rental.GetRental(rentalId, MemberId, User.IsInRole(nameof(Role.Admin)));
        if (rental == null) return NotFound();
        var payment = Provider.Payment.GetLatest(rentalId);
        if (payment is { Method: "vietqr", State: RentalPayment.Pending } &&
            payment.CheckoutUrl != null && gateway.Enabled("vietqr"))
        {
            try
            {
                var status = await gateway.GetVietQrStatus(payment.Id, payment.Amount);
                if (status.State != RentalPayment.Pending)
                {
                    Provider.Payment.Update(payment.Id, status.State);
                    payment = Provider.Payment.GetPayment(payment.Id);
                }
            }
            catch (Exception ex) when (RemoteFailure(ex))
            {
                logger.LogWarning("Could not refresh VietQR payment {Id}", payment?.Id);
            }
        }

        string[] methods = rental.MemberId == MemberId && rental.StatusId is not (1 or 5)
            ? new[] { "vnpay", "vietqr" }.Where(gateway.Enabled).ToArray() : [];
        return Ok(new { methods, payment = View(payment, rental.MemberId == MemberId) });
    }

    [HttpPost("{rentalId:int}/{method}"), EnableRateLimiting("account")]
    public async Task<IActionResult> Add(int rentalId, string method)
    {
        if (!gateway.Enabled(method)) return StatusCode(503);
        var payment = Provider.Payment.Add(rentalId, MemberId, method);
        if (payment == null) return BadRequest("Phiếu không thể thanh toán hoặc số tiền không hợp lệ.");
        if (payment.State == RentalPayment.Paid) return Conflict("Phiếu đã thanh toán.");
        if (payment.Method != method) return Conflict("Phiếu đang có giao dịch bằng phương thức khác.");
        if (payment.CreatedAt < DateTime.UtcNow.AddMinutes(-15))
            return Conflict("Liên kết hết hạn. Hãy kiểm tra lại giao dịch trước khi thanh toán.");

        try
        {
            if (payment.CheckoutUrl == null)
            {
                var ip = HttpContext.Connection.RemoteIpAddress;
                string address = ip?.IsIPv4MappedToIPv6 == true ? ip.MapToIPv4().ToString() : ip?.ToString() ?? "127.0.0.1";
                string url = method == "vnpay" ? gateway.CreateVnPayUrl(payment, address) : await gateway.CreateVietQrUrl(payment);
                Provider.Payment.SaveUrl(payment.Id, url);
                payment = Provider.Payment.GetPayment(payment.Id)!;
            }
            return Ok(View(payment));
        }
        catch (Exception ex) when (RemoteFailure(ex))
        {
            logger.LogWarning("Could not create external payment {Id}", payment.Id);
            return StatusCode(502, "Chưa lấy được liên kết thanh toán. Hãy thử lại.");
        }
    }

    [AllowAnonymous, HttpGet("vnpay/ipn")]
    public IActionResult VnPayIpn()
    {
        var query = Request.Query;
        var fields = query.Where(p => p.Key.StartsWith("vnp_", StringComparison.Ordinal) &&
                p.Key is not ("vnp_SecureHash" or "vnp_SecureHashType"))
            .Select(p => KeyValuePair.Create(p.Key, p.Value.ToString()));
        if (query.Any(p => p.Value.Count != 1) ||
            !gateway.ValidVnPaySignature(fields, query["vnp_SecureHash"].ToString()) ||
            query["vnp_TmnCode"].ToString() != gateway.Terminal)
            return Reply("97", "Invalid signature");
        if (!long.TryParse(query["vnp_TxnRef"], NumberStyles.None, CultureInfo.InvariantCulture, out long id))
            return Reply("01", "Order not found");
        var payment = Provider.Payment.GetPayment(id);
        if (payment == null || payment.Method != "vnpay") return Reply("01", "Order not found");
        if (!long.TryParse(query["vnp_Amount"], NumberStyles.None, CultureInfo.InvariantCulture, out long amount) ||
            payment.Amount * 100 != amount)
            return Reply("04", "Invalid amount");
        if (payment.State != RentalPayment.Pending) return Reply("02", "Order already confirmed");

        string response = query["vnp_ResponseCode"].ToString();
        string transaction = query["vnp_TransactionStatus"].ToString();
        if (response == "00" && transaction == "00")
            return Provider.Payment.Update(id, RentalPayment.Paid) > 0 ? Reply("00", "Confirm success") : Reply("02", "Order already confirmed");
        if (transaction == "02" && response != "00")
            return Provider.Payment.Update(id, RentalPayment.Failed) > 0 ? Reply("00", "Payment failed") : Reply("02", "Order already confirmed");
        return Reply("99", "Payment status not final");
    }

    [AllowAnonymous, HttpPost("vietqr/webhook")]
    public async Task<IActionResult> VietQrWebhook(JsonElement obj)
    {
        if (obj.ValueKind != JsonValueKind.Object || !obj.TryGetProperty("data", out var data) ||
            !obj.TryGetProperty("signature", out var signature) || signature.ValueKind != JsonValueKind.String ||
            !gateway.ValidPayOsWebhook(data, signature.GetString()!)) return BadRequest();
        if (!data.TryGetProperty("orderCode", out var order) || order.ValueKind != JsonValueKind.Number ||
            !order.TryGetInt64(out long id)) return BadRequest();
        var payment = Provider.Payment.GetPayment(id);
        // payOS sends a sample notification when the webhook URL is registered.
        if (payment is not { Method: "vietqr", State: RentalPayment.Pending }) return Ok();
        try
        {
            var status = await gateway.GetVietQrStatus(id, payment.Amount);
            if (status.State != RentalPayment.Pending) Provider.Payment.Update(id, status.State);
            return Ok();
        }
        catch (Exception ex) when (RemoteFailure(ex))
        {
            logger.LogWarning("Could not confirm VietQR payment {Id}", id);
            return StatusCode(502);
        }
    }

    [AllowAnonymous, HttpGet("return")]
    public IActionResult Return() => Content(
        "Quay lại ứng dụng và chọn Kiểm tra thanh toán để xem kết quả.",
        "text/plain; charset=utf-8");

    private IActionResult Reply(string code, string message) => new JsonResult(
        new Dictionary<string, string> { ["RspCode"] = code, ["Message"] = message });

    private static object? View(RentalPayment? payment, bool canPay = true) => payment == null ? null : new
    {
        payment.Method, payment.Amount, payment.State, payment.PaidAt,
        checkoutUrl = canPay && payment.State == RentalPayment.Pending &&
            payment.CreatedAt >= DateTime.UtcNow.AddMinutes(-15) ? payment.CheckoutUrl : null
    };

    private static bool RemoteFailure(Exception ex) =>
        ex is HttpRequestException or TaskCanceledException or JsonException or KeyNotFoundException or InvalidOperationException;
}
