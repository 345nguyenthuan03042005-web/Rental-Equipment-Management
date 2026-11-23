using System.Data;
using Microsoft.EntityFrameworkCore;

namespace WebApi.Models;
public class EquipmentRepository : BaseRepository
{
    public EquipmentRepository(RentalEquipmentManagementContext context) : base(context)
    {
        
    }
    public Equipment? GetEquipment(int id)
    {
        return context.Equipment.Find(id);
    }
    public IEnumerable<Equipment> GetEquipment(string? unit)
    {
        return context.Equipment.Where(p => unit == null || p.Unit == unit).ToList();
    }
    public IEnumerable<Equipment> GetEquipmentByCategory(short id, string? unit)
    {
        return context.Equipment.Where(p => p.SubCategory!.CategoryId == id && (unit == null || p.Unit == unit)).ToList();
    }
    public IEnumerable<Equipment> GetEquipmentBySubCategories(short[] ids, string? unit)
    {
        return context.Equipment.Where(p => ids.Contains(p.SubCategoryId) && (unit == null || p.Unit == unit)).ToList();
    }
    public IEnumerable<Equipment> GetEquipmentRelation (int id, short subcategoryId)
    {
        return context.Equipment.Where(p => p.SubCategoryId == subcategoryId && p.Id != id).ToList();
    }

    public object GetRelatedPage(int id, short subCategoryId, int page)
    {
        const int pageSize = 2;
        var query = context.Equipment.AsNoTracking()
            .Where(p => p.Id != id && p.SubCategoryId == subCategoryId);
        var items = query.OrderByDescending(p => p.Id).Skip((page - 1) * pageSize).Take(pageSize).ToList();
        return new { items, total = query.Count() };
    }

    public IEnumerable<string> GetUnits()
    {
        return context.Equipment.Where(p => p.Unit != null && p.Unit != "")
            .Select(p => p.Unit!).Distinct().OrderBy(p => p).ToList();
    }

    public int Update(int id, string unit, string status)
    {
        return context.Equipment.Where(p => p.Id == id && p.Status != Equipment.Rented)
            .ExecuteUpdate(p => p.SetProperty(x => x.Unit, unit).SetProperty(x => x.Status, status));
    }

    public object GetPage(int page, int pageSize, short? categoryId, short[] subCategoryIds, string? unit, string? search)
    {
        var query = context.Equipment.AsNoTracking().AsQueryable();
        if (categoryId.HasValue)
            query = query.Where(p => p.SubCategory!.CategoryId == categoryId);
        if (subCategoryIds.Length > 0)
            query = query.Where(p => subCategoryIds.Contains(p.SubCategoryId));
        if (!string.IsNullOrWhiteSpace(unit))
            query = query.Where(p => p.Unit == unit);
        if (!string.IsNullOrWhiteSpace(search))
        {
            search = search.Trim();
            query = query.Where(p => p.Name.Contains(search) ||
                (p.Brand != null && p.Brand.Contains(search)) ||
                (p.Model != null && p.Model.Contains(search)));
        }

        var total = query.Count();
        var items = query.OrderByDescending(p => p.Id).Skip((page - 1) * pageSize).Take(pageSize).ToList();
        return new { items, total };
    }

    public bool HasSubCategory(short id) => context.SubCategories.Any(p => p.Id == id);

    public int Add(Equipment obj)
    {
        context.Equipment.Add(obj);
        context.SaveChanges();
        return obj.Id;
    }

    public int Update(int id, Equipment obj, string previousImage)
    {
        return context.Equipment.Where(p => p.Id == id && p.Status != Equipment.Rented && p.ImageUrl == previousImage)
            .ExecuteUpdate(p => p.SetProperty(x => x.SubCategoryId, obj.SubCategoryId)
                .SetProperty(x => x.Name, obj.Name)
                .SetProperty(x => x.Price, obj.Price)
                .SetProperty(x => x.Brand, obj.Brand)
                .SetProperty(x => x.Model, obj.Model)
                .SetProperty(x => x.Specifications, obj.Specifications)
                .SetProperty(x => x.Unit, obj.Unit)
                .SetProperty(x => x.Status, obj.Status)
                .SetProperty(x => x.ImageUrl, obj.ImageUrl));
    }

    public int Delete(int id, string image)
    {
        using var transaction = context.Database.BeginTransaction(IsolationLevel.Serializable);
        if (context.RentalDetails.Any(p => p.EquipmentId == id) || context.Carts.Any(p => p.EquipmentId == id))
            return -1;
        int count = context.Equipment.Where(p => p.Id == id && p.Status != Equipment.Rented && p.ImageUrl == image)
            .ExecuteDelete();
        transaction.Commit();
        return count;
    }

    public bool UsesImage(string name) => context.Equipment.Any(p => p.ImageUrl == name);
}
