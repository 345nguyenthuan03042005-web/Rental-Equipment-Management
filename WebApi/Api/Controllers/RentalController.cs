using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Api.Controllers;

[Authorize, ApiController, Route("api/[controller]")]
public class RentalController : BaseController
{
    private string MemberId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
    private bool IsAdmin => User.IsInRole(nameof(Role.Admin));

    [HttpPut("status")]
    public int UpdateStatus(int id, int statusId) => Provider.Rental.Update(id, statusId, MemberId, IsAdmin);

    [HttpGet]
    public ActionResult<IEnumerable<Rental>> GetRentals(int? number, DateOnly? from, DateOnly? to)
    {
        if (number <= 0 || from > to) return BadRequest("Bộ lọc không hợp lệ.");
        return Ok(Provider.Rental.GetRentals(MemberId, IsAdmin, from: IsAdmin ? from : null,
            to: IsAdmin ? to : null, number: number));
    }

    [HttpPost]
    public int Add() => Provider.Rental.Add(MemberId);

    [HttpGet("details/{id:int}")]
    public ActionResult<Rental> GetRental(int id)
    {
        var rental = Provider.Rental.GetRental(id, MemberId, IsAdmin);
        return rental == null ? NotFound() : rental;
    }
}
