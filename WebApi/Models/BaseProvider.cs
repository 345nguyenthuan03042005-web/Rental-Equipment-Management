namespace WebApi.Models;

public abstract class BaseProvider
{
    //fields
    RentalEquipmentManagementContext? context;
    IHttpContextAccessor accessor;

    public BaseProvider(IHttpContextAccessor accessor)
    {
        this.accessor = accessor;
    }

    //Properties
    protected RentalEquipmentManagementContext Context => context ??= accessor.HttpContext!.RequestServices.GetRequiredService<RentalEquipmentManagementContext>();
}