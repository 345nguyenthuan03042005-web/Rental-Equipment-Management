using System.Data;
using Microsoft.EntityFrameworkCore;

namespace WebApi.Models;

public class PaymentRepository : BaseRepository
{
    public PaymentRepository(RentalEquipmentManagementContext context) : base(context) { }

    public RentalPayment? GetPayment(long id)
        => context.RentalPayments.AsNoTracking().FirstOrDefault(p => p.Id == id);

    public RentalPayment? GetLatest(int rentalId)
        => context.RentalPayments.AsNoTracking().Where(p => p.RentalId == rentalId)
            .OrderByDescending(p => p.Id).FirstOrDefault();

    public RentalPayment? Add(int rentalId, string memberId, string method)
    {
        using var transaction = context.Database.BeginTransaction(IsolationLevel.Serializable);
        var rental = context.Rentals.FirstOrDefault(p => p.Id == rentalId && p.MemberId == memberId);
        if (rental == null || rental.StatusId is 1 or 5) return null;

        var payment = context.RentalPayments.FirstOrDefault(p => p.RentalId == rentalId && p.State < RentalPayment.Failed);
        if (payment != null) return payment;

        decimal total = context.RentalDetails.Where(p => p.RentalId == rentalId)
            .Sum(p => (decimal?)p.Price * p.Quantity) ?? 0;
        if (total <= 0 || total > 9999999999 || decimal.Truncate(total) != total) return null;
        payment = new RentalPayment
        {
            RentalId = rentalId, Method = method, Amount = (long)total, CreatedAt = DateTime.UtcNow
        };
        context.RentalPayments.Add(payment);
        context.SaveChanges();
        transaction.Commit();
        return payment;
    }

    public int SaveUrl(long id, string url)
        => context.RentalPayments.Where(p => p.Id == id && p.State == RentalPayment.Pending && p.CheckoutUrl == null)
            .ExecuteUpdate(p => p.SetProperty(x => x.CheckoutUrl, url));

    public int Update(long id, int state)
    {
        var paidAt = state == RentalPayment.Paid ? (DateTime?)DateTime.UtcNow : null;
        return context.RentalPayments.Where(p => p.Id == id && p.State == RentalPayment.Pending)
            .ExecuteUpdate(p => p.SetProperty(x => x.State, state).SetProperty(x => x.PaidAt, paidAt));
    }
}
