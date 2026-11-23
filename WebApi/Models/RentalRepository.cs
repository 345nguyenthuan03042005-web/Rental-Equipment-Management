using System.Data;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace WebApi.Models;

public class RentalRepository : BaseRepository
{
    public RentalRepository(RentalEquipmentManagementContext context) : base(context) { }

    public int Update(int id, int statusId, string memberId, bool isAdmin)
    {
        var changed = new SqlParameter("@Changed", SqlDbType.Int) { Direction = ParameterDirection.Output };
        context.Database.ExecuteSqlRaw("EXEC UpdateRentalStatus @RentalId, @StatusId, @MemberId, @IsAdmin, @Changed OUTPUT",
            new SqlParameter("@RentalId", id),
            new SqlParameter("@StatusId", statusId),
            new SqlParameter("@MemberId", memberId),
            new SqlParameter("@IsAdmin", isAdmin),
            changed);
        return (int)changed.Value;
    }

    public int Add(string memberId)
    {
        var id = new SqlParameter("@RentalId", SqlDbType.Int) { Direction = ParameterDirection.Output };
        context.Database.ExecuteSqlRaw("EXEC AddRental @MemberId, @RentalId OUTPUT",
            new SqlParameter("@MemberId", memberId), id);
        return (int)id.Value;
    }

    public IEnumerable<Rental> GetRentals(string memberId, bool isAdmin, int? number, DateOnly? from, DateOnly? to)
    {
        var query = context.Rentals.Where(p => isAdmin || p.MemberId == memberId);
        if (number.HasValue) query = query.Where(p => p.Id == number);
        if (from.HasValue)
        {
            DateTime start = from.Value.ToDateTime(TimeOnly.MinValue);
            query = query.Where(p => p.Dated >= start);
        }
        if (to.HasValue)
        {
            DateTime end = to.Value.ToDateTime(TimeOnly.MaxValue);
            query = query.Where(p => p.Dated <= end);
        }
        return query.OrderByDescending(p => p.Id).ToList();
    }

    public Rental? GetRental(int id, string memberId, bool isAdmin)
    {
        return context.Rentals.Include(p => p.Details).ThenInclude(p => p.Equipment)
            .FirstOrDefault(p => p.Id == id && (isAdmin || p.MemberId == memberId));
    }
}
