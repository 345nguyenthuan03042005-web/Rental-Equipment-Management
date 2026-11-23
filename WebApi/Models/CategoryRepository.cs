using System.Data;
using Microsoft.EntityFrameworkCore;

namespace WebApi.Models;
public class CategoryRepository : BaseRepository
{
    public CategoryRepository(RentalEquipmentManagementContext context) : base(context) { }

    public IEnumerable<Category> GetCategories()
    {
        return context.Categories.OrderBy(p => p.Id).ToList();
    }

    public Category? GetCategory(short id) => context.Categories.AsNoTracking().FirstOrDefault(p => p.Id == id);

    public bool UsesImage(string name) => context.Categories.Any(p => p.Icon == name) ||
        context.SubCategories.Any(p => p.ImageUrl == name);

    public int Add(Category obj)
    {
        using var transaction = context.Database.BeginTransaction();
        obj.Id = 0;
        context.Categories.Add(obj);
        context.SaveChanges();
        context.SubCategories.Add(new SubCategory
        {
            CategoryId = obj.Id,
            Name = "Thiết bị chung",
            Title = obj.Title,
            Description = obj.Description,
            ImageUrl = obj.Icon
        });
        context.SaveChanges();
        transaction.Commit();
        return obj.Id;
    }

    public int Update(short id, Category obj, string? expectedIcon = null)
    {
        using var transaction = context.Database.BeginTransaction(IsolationLevel.Serializable);
        var category = context.Categories.Find(id);
        if (category == null) return 0;
        string oldIcon = category.Icon;
        if (expectedIcon != null && oldIcon != expectedIcon) return -1;
        category.Name = obj.Name;
        category.Title = obj.Title;
        category.Description = obj.Description;
        category.Icon = obj.Icon;
        context.SaveChanges();
        context.SubCategories.Where(p => p.CategoryId == id &&
            p.Name == "Thiết bị chung" && p.ImageUrl == oldIcon)
            .ExecuteUpdate(p => p.SetProperty(x => x.ImageUrl, obj.Icon));
        transaction.Commit();
        return 1;
    }

    public int Delete(short id, string icon)
    {
        using var transaction = context.Database.BeginTransaction(IsolationLevel.Serializable);
        if (!context.Categories.Any(p => p.Id == id && p.Icon == icon)) return -2;
        var subCategories = context.SubCategories.Where(p => p.CategoryId == id);
        if (context.Equipment.Any(p => subCategories.Select(s => s.Id).Contains(p.SubCategoryId)))
            return -1;
        subCategories.ExecuteDelete();
        int count = context.Categories.Where(p => p.Id == id).ExecuteDelete();
        transaction.Commit();
        return count;
    }
}
