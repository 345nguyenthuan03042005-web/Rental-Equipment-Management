namespace WebApi.Models;

public abstract class BaseRepository
{
    protected RentalEquipmentManagementContext context;

    public BaseRepository(RentalEquipmentManagementContext context)
    {
        this.context = context;
    }
}