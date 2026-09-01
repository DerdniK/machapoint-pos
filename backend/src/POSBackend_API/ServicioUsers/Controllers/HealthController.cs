using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using ServicioUsers.Data;
using ServicioUsers.Dtos.Health;

namespace ServicioUsers.Controllers
{
    [ApiController]
    [Route("api/users/[controller]")]
    public class HealthController : ControllerBase
    {
        private readonly SupaDBContext _context;

        public HealthController(SupaDBContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetHealth()
        {
            var version = await _context.DatabaseVersion
            .Select(x => x.version)
            .FirstOrDefaultAsync();

            try
            {
                return Ok(new HealthResponseDto
            {
                Status = "Ok",
                Version = version.ToString() ?? "Unknown",
                Timestamp = DateTime.UtcNow
            });
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status503ServiceUnavailable, new HealthResponseDto
                {
                    Status = "ServiceUnavailable",
                    Version = version.ToString() ?? "Unknown",
                    Timestamp = DateTime.UtcNow
                });
            }
        }
    }
}