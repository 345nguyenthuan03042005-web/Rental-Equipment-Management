using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Api.Controllers;

[Authorize, ApiController, Route("api/[controller]")]
public class CartController : BaseController
{
    private string MemberId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

    [HttpDelete("{id:int}")]
    public int Delete(int id) => Provider.Cart.Delete(id, MemberId);

    [HttpGet]
    public IEnumerable<object> GetCarts()
    {
        return Provider.Cart.GetCarts(MemberId).Select(p => new
        {
            p.Id,
            p.EquipmentId,
            p.Quantity,
            p.MemberId,
            p.Equipment!.Price,
            p.Equipment!.ImageUrl,
            p.Equipment!.Name,
            p.Equipment!.Unit,
            p.Equipment!.Status
        });
    }

    [HttpPut("{id:int}")]
    public int Update(int id, [FromBody, Range(1, 365)] short quantity)
    {
        return Provider.Cart.Update(id, MemberId, quantity);
    }

    [HttpPost]
    public int Add(Cart obj)
    {
        obj.MemberId = MemberId;
        return Provider.Cart.Add(obj);
    }
}
