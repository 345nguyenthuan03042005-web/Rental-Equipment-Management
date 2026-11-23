namespace WebApi.Models;
public class StatusRepository : BaseRepository
{
    public StatusRepository(RentalEquipmentManagementContext context) : base(context)
    {
        
    }
    public IEnumerable<Status> GetStatuses() => context.Statuses.ToList();
}