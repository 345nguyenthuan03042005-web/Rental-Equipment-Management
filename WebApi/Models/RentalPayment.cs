using System.ComponentModel.DataAnnotations.Schema;

namespace WebApi.Models;

[Table("RentalPayment")]
public class RentalPayment
{
    public const int Pending = 0;
    public const int Paid = 1;
    public const int Failed = 2;

    [Column("PaymentId")]
    public long Id { get; set; }
    public int RentalId { get; set; }
    public string Method { get; set; } = null!;
    public long Amount { get; set; }
    public int State { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? CheckoutUrl { get; set; }
    public DateTime? PaidAt { get; set; }
}
