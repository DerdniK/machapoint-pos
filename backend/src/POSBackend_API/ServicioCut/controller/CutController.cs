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

    [HttpGet("health")]
        public IActionResult Health()
        {
            try
            {
                return Ok(true);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new 
                { 
                    message = "El servicio esta caido :(",
                    detail = ex.Message 
                });
            }
            
        }

    [HttpGet("zcuts")]
    [Authorize]
    public async Task<IActionResult> GetZCuts([FromQuery] GetZCutRequestDto request)
    {
        var response = await _cutService.GetZCutsAsync(request);
        return Ok(response);
    }
}