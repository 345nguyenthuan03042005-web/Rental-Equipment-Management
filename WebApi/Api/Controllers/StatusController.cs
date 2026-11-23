using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Api.Controllers;
[ApiController, Route("api/[Controller]")]
public class StatusController : BaseController
{
    [HttpGet]
    public IEnumerable<Status> GetStatuses() => Provider.Status.GetStatuses();
}