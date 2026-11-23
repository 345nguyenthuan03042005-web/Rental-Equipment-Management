using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace WebApi.Models;

public class CartRepository : BaseRepository
{
    public CartRepository(RentalEquipmentManagementContext context) : base(context) { }

    public int Delete(int id, string memberId)
    {
        return context.Carts.Where(p => p.Id == id && p.MemberId == memberId).ExecuteDelete();
    }

    public IEnumerable<Cart> GetCarts(string memberId)
    {
        return context.Carts.Where(p => p.MemberId == memberId).Include(p => p.Equipment).ToList();
    }

    public int Update(int id, string memberId, short quantity)
    {
        return context.Carts.Where(p => p.Id == id && p.MemberId == memberId)
            .ExecuteUpdate(p => p.SetProperty(x => x.Quantity, quantity));
    }

    public int Add(Cart obj)
    {
        return context.Database.ExecuteSqlRaw("EXEC AddCart @MemberId, @EquipmentId, @Quantity",
            new SqlParameter("@MemberId", obj.MemberId),
            new SqlParameter("@EquipmentId", obj.EquipmentId),
            new SqlParameter("@Quantity", obj.Quantity));
    }
}
