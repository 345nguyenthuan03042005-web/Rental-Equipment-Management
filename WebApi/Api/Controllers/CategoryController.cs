using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;
using WebApi.Services;

namespace WebApi.Api.Controllers;

[ApiController, Route("api/[controller]")]
public class CategoryController : BaseController
{
    private readonly IWebHostEnvironment environment;
    private readonly ILogger<CategoryController> logger;

    public CategoryController(IWebHostEnvironment environment, ILogger<CategoryController> logger)
    {
        this.environment = environment;
        this.logger = logger;
    }

    [HttpGet]
    public IEnumerable<Category> GetCategories() => Provider.Category.GetCategories();

    [Authorize(Roles = nameof(Role.Admin)), HttpPost, Consumes("application/json")]
    public ActionResult<int> Post(Category obj)
    {
        if (!ValidIcon(obj.Icon)) return BadRequest("Tên ảnh danh mục không hợp lệ.");
        return Provider.Category.Add(obj);
    }

    [Authorize(Roles = nameof(Role.Admin)), HttpPut("{id}"), Consumes("application/json")]
    public ActionResult<int> Put(short id, Category obj)
    {
        if (!ValidIcon(obj.Icon)) return BadRequest("Tên ảnh danh mục không hợp lệ.");
        var current = Provider.Category.GetCategory(id);
        if (current == null) return NotFound();
        int result = Provider.Category.Update(id, obj, current.Icon);
        if (result <= 0) return Conflict();
        if (current.Icon != obj.Icon) DeleteUnusedImage(current.Icon);
        return Ok(result);
    }

    [Authorize(Roles = nameof(Role.Admin)), HttpPost, Consumes("multipart/form-data")]
    [RequestSizeLimit(6 * 1024 * 1024)]
    public Task<ActionResult<int>> PostImage([FromForm] CategoryInput obj) => Save(obj, null);

    [Authorize(Roles = nameof(Role.Admin)), HttpPut("{id}"), Consumes("multipart/form-data")]
    [RequestSizeLimit(6 * 1024 * 1024)]
    public async Task<ActionResult<int>> PutImage(short id, [FromForm] CategoryInput obj)
    {
        var current = Provider.Category.GetCategory(id);
        if (current == null) return NotFound();
        return await Save(obj, current);
    }

    private async Task<ActionResult<int>> Save(CategoryInput obj, Category? current)
    {
        string? image = null;
        if (obj.Image != null)
        {
            try
            {
                image = await Helper.UploadImage(obj.Image, environment.WebRootPath, "categories", 12);
            }
            catch (InvalidDataException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        var category = new Category
        {
            Name = obj.Name.Trim(), Title = obj.Title.Trim(), Description = obj.Description.Trim(),
            Icon = image ?? current?.Icon ?? ""
        };
        int result = 0;
        try
        {
            result = current == null ? Provider.Category.Add(category) :
                Provider.Category.Update(current.Id, category, current.Icon);
        }
        finally
        {
            if (result <= 0 && image != null) DeleteUnusedImage(image);
        }
        if (result <= 0) return Conflict();
        if (current != null && image != null) DeleteUnusedImage(current.Icon);
        return Ok(result);
    }

    [Authorize(Roles = nameof(Role.Admin)), HttpDelete("{id}")]
    public ActionResult<int> Delete(short id)
    {
        var category = Provider.Category.GetCategory(id);
        if (category == null) return NotFound();
        int result = Provider.Category.Delete(id, category.Icon);
        if (result == -1) return Conflict("Danh mục vẫn còn thiết bị.");
        if (result <= 0) return Conflict("Danh mục đã thay đổi.");
        DeleteUnusedImage(category.Icon);
        return Ok(result);
    }

    private void DeleteUnusedImage(string name)
    {
        try
        {
            if (!Provider.Category.UsesImage(name)) Helper.DeleteImage(environment.WebRootPath, "categories", name);
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            logger.LogWarning(ex, "Could not remove category image {ImageName}", name);
        }
    }

    private static bool ValidIcon(string icon)
        => icon.All(c => char.IsAsciiLetterOrDigit(c) || c is '-' or '_' or '.');
}

public class CategoryInput
{
    [Required, StringLength(64)]
    public string Name { get; set; } = null!;
    [Required, StringLength(128)]
    public string Title { get; set; } = null!;
    [Required, StringLength(1024)]
    public string Description { get; set; } = null!;
    public IFormFile? Image { get; set; }
}
