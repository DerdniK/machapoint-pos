using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServicioUsers.Data;
using ServicioUsers.Dtos;
using ServicioUsers.Services;

namespace ServicioUsers.Controllers
{
    [ApiController]
    [Route("api/users/[controller]")] //? Segun yo [controller] va a ser el nombre del archivo en este caso "AuthController"
    
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

    // La recibe aquí
        public AuthController(IAuthService authService) //? Inyeccion de dependencias del servicio 
        {
            _authService = authService;
        }

        [HttpPost]
        public async Task<IActionResult> PostLoginUsers(LoginRequestDto credentials)
        {
            try
            {
                var response = await _authService.LoginAsync(credentials);

                if(response.Success == false)
                {
                    return Unauthorized(response);
                }

                return Ok(response);
            }
            catch (Exception ex)
            {
                // Esto te devolverá el mensaje exacto y el error interno de Postgres/EF Core
                return StatusCode(500, new 
                {
                    Error = ex.Message,
                    InnerError = ex.InnerException?.Message,
                    Stack = ex.StackTrace
                });
            }
            
        }

        
    }
}