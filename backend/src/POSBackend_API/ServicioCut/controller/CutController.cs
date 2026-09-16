using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ServicioCut.Dtos;
using ServicioCut.Services;

namespace ServicioCut.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CutController : ControllerBase
{
    private readonly ICutService _cutService;

    public CutController(ICutService cutService)
    {
        _cutService = cutService;
    }

    [HttpGet("zcuts")]
    [Authorize]
    public async Task<IActionResult> GetZCuts([FromQuery] GetZCutRequestDto request)
    {
        var response = await _cutService.GetZCutsAsync(request);
        return Ok(response);
    }
}