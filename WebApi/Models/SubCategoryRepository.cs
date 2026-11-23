using WebApi.Models;

public class SubCategoryRepository : BaseRepository
{
    public SubCategoryRepository(RentalEquipmentManagementContext context) : base(context)
    {
    }
    public IEnumerable<SubCategory> GetSubCategories()
    {
        return context.SubCategories.ToList();
    }
    public IEnumerable<SubCategory> GetSubCategories(short id)
    {
        return context.SubCategories.Where(p => p.CategoryId == id).ToList();
    }
}