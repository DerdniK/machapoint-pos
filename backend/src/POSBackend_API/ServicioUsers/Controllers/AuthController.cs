using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServicioUsers.Data;
using ServicioUsers.Dtos.Auth.Register;
using ServicioUsers.Dtos.Auth.Login;
using ServicioUsers.Services;
using ServicioUsers.Dtos.Auth.Delete;
using ServicioUsers.Dtos.Auth.Update;
using Microsoft.AspNetCore.Authorization;

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

        [HttpPost("login")]
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

        [Authorize(Roles = "Admin")]
        [HttpPost("register")]
        public async Task<IActionResult> PostRegisterUsers(RegisterRequestDto request)
        {
            try
            {
                var response = await _authService.RegisterAsync(request);

                if (!response.Success)
                {
                    return BadRequest(response);
                }
                return Ok(response);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    Error = ex.Message,
                    InnerError = ex.InnerException?.Message,
                    Stack = ex.StackTrace
                });
            }
        }

        [Authorize(Roles = "Admin")]
        [HttpDelete("delete")]
        public async Task<IActionResult> DeleteUsersById(DeleteUserRequestDto request)
        {
            try
            {
                var response = await _authService.DeleteByIdAsync(request);

                if (!response.Success)
                {
                    return BadRequest(response);
                }
                return Ok(response);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    Error = ex.Message,
                    InnerError = ex.InnerException?.Message,
                    Stack = ex.StackTrace
                });
            }
        }

        [Authorize(Roles = "Admin")]
        [HttpPatch("update")] //? Patch actualizacion parcial del recurso
        public async Task<IActionResult> UpdateUserById(UpdateUserRequestDto request)
        {
            try
            {
                var response = await _authService.UpdateUserByIdAsync(request);

                if (!response.Success)
                {
                    return BadRequest(response);
                }
                return Ok(response);
            }
            catch (Exception ex)
            {
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