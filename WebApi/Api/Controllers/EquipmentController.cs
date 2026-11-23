using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.ComponentModel.DataAnnotations;
using WebApi.Models;
using WebApi.Services;

namespace WebApi.Api.Controllers;

[ApiController, Route("api/[controller]")]
public class EquipmentController : BaseController
{
    private readonly IWebHostEnvironment environment;
    private readonly ILogger<EquipmentController> logger;

    public EquipmentController(IWebHostEnvironment environment, ILogger<EquipmentController> logger)
    {
        this.environment = environment;
        this.logger = logger;
    }

    [HttpGet("details/{id:int}")]
    public ActionResult<Equipment> GetEquipment(int id)
    {
        var equipment = Provider.Equipment.GetEquipment(id);
        return equipment == null ? NotFound() : equipment;
    }

    [HttpGet]
    public IEnumerable<Equipment> GetEquipment(string? unit)
    {
        return Provider.Equipment.GetEquipment(unit);
    }
    
    [HttpGet("page")]
    public object GetPage([Range(1, 100000)] int page = 1, [Range(1, 60)] int pageSize = 12,
        short? categoryId = null, [FromQuery] short[]? subCategoryIds = null, string? unit = null, string? search = null)
    {
        return Provider.Equipment.GetPage(page, pageSize, categoryId, subCategoryIds ?? [], unit, search);
    }

    [HttpGet ("relation")]
    public IEnumerable<Equipment> GetEquipmentRelation(int id, short subCategoriesId)
    {
        return Provider.Equipment.GetEquipmentRelation(id, subCategoriesId);
    }

    [HttpGet("category/{id}")]
    public IEnumerable<Equipment> GetEquipmentByCategory(short id, string? unit)
    {
        return Provider.Equipment.GetEquipmentByCategory(id, unit);
    }

    [HttpPost("subcategories")]
    public IEnumerable<Equipment> GetEquipmentBySubCategories(short[] ids, string? unit)
    {
        return Provider.Equipment.GetEquipmentBySubCategories(ids, unit);
    }

    [HttpGet("relation/page")]
    public object GetRelatedPage(int id, short subCategoryId, [Range(1, 100000)] int page = 1)
        => Provider.Equipment.GetRelatedPage(id, subCategoryId, page);

    [HttpGet("units")]
    public IEnumerable<string> GetUnits() => Provider.Equipment.GetUnits();

    [Authorize(Roles = nameof(Role.Admin)), HttpPut("{id:int}"), Consumes("application/json")]
    public ActionResult<int> Update(int id, EquipmentUpdate obj)
    {
        if (string.IsNullOrWhiteSpace(obj.Unit) || obj.Status is not (Equipment.Available or Equipment.Maintenance))
            return BadRequest();

        int result = Provider.Equipment.Update(id, obj.Unit.Trim(), obj.Status);
        return result > 0 ? Ok(result) : Conflict();
    }

    [Authorize(Roles = nameof(Role.Admin)), HttpPost, Consumes("multipart/form-data")]
    [RequestSizeLimit(6 * 1024 * 1024)]
    public async Task<ActionResult<int>> Add([FromForm] EquipmentInput obj)
    {
        if (!IsValid(obj) || obj.Image == null) return BadRequest("Kiểm tra thông tin và chọn ảnh thiết bị.");
        return await Save(obj, null);
    }

    [Authorize(Roles = nameof(Role.Admin)), HttpPut("{id:int}"), Consumes("multipart/form-data")]
    [RequestSizeLimit(6 * 1024 * 1024)]
    public async Task<ActionResult<int>> Put(int id, [FromForm] EquipmentInput obj)
    {
        var current = Provider.Equipment.GetEquipment(id);
        if (current == null) return NotFound();
        if (current.Status == Equipment.Rented) return Conflict("Thiết bị đang cho thuê.");
        if (!IsValid(obj)) return BadRequest("Thông tin thiết bị không hợp lệ.");
        return await Save(obj, current);
    }

    [Authorize(Roles = nameof(Role.Admin)), HttpDelete("{id:int}")]
    public ActionResult<int> Delete(int id)
    {
        var current = Provider.Equipment.GetEquipment(id);
        if (current == null) return NotFound();
        int result = Provider.Equipment.Delete(id, current.ImageUrl);
        if (result <= 0) return Conflict("Thiết bị đang cho thuê hoặc có trong giỏ hay phiếu thuê.");
        DeleteUnusedImage(current.ImageUrl);
        return Ok(result);
    }

    private bool IsValid(EquipmentInput obj)
        => (obj.Status is Equipment.Available or Equipment.Maintenance) && Provider.Equipment.HasSubCategory(obj.SubCategoryId);

    private async Task<ActionResult<int>> Save(EquipmentInput obj, Equipment? current)
    {
        string? newImage = null;
        string webRoot = environment.WebRootPath;
        if (obj.Image != null)
        {
            try
            {
                newImage = await Helper.UploadEquipmentImage(obj.Image, webRoot);
            }
            catch (InvalidDataException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        var equipment = new Equipment
        {
            SubCategoryId = obj.SubCategoryId, Name = obj.Name.Trim(), Price = obj.Price,
            Brand = obj.Brand?.Trim(), Model = obj.Model?.Trim(), Specifications = obj.Specifications?.Trim(),
            Unit = obj.Unit.Trim(), Status = obj.Status, ImageUrl = newImage ?? current!.ImageUrl
        };
        int result = 0;
        try
        {
            result = current == null
                ? Provider.Equipment.Add(equipment)
                : Provider.Equipment.Update(current.Id, equipment, current.ImageUrl);
        }
        finally
        {
            if (result <= 0 && newImage != null) DeleteUnusedImage(newImage);
        }

        if (result <= 0) return Conflict("Thiết bị đã thay đổi. Hãy tải lại danh sách.");
        if (current != null && newImage != null) DeleteUnusedImage(current.ImageUrl);
        return Ok(result);
    }

    private void DeleteUnusedImage(string name)
    {
        try
        {
            if (!Provider.Equipment.UsesImage(name)) Helper.DeleteEquipmentImage(environment.WebRootPath, name);
        }
        catch (IOException ex)
        {
            logger.LogWarning(ex, "Could not remove equipment image {ImageName}", name);
        }
        catch (UnauthorizedAccessException ex)
        {
            logger.LogWarning(ex, "Could not remove equipment image {ImageName}", name);
        }
    }
}

public record EquipmentUpdate([Required, StringLength(128)] string Unit, [Required] string Status);

public class EquipmentInput
{
    public short SubCategoryId { get; set; }
    [Required, StringLength(128)]
    public string Name { get; set; } = null!;
    [Range(typeof(decimal), "0", "99999999.99")]
    public decimal Price { get; set; }
    [StringLength(64)]
    public string? Brand { get; set; }
    [StringLength(128)]
    public string? Model { get; set; }
    [StringLength(256)]
    public string? Specifications { get; set; }
    [Required, StringLength(128)]
    public string Unit { get; set; } = null!;
    [Required, StringLength(64)]
    public string Status { get; set; } = null!;
    public IFormFile? Image { get; set; }
}
