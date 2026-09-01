using ServicioUsers.Dtos;
using ServicioUsers.Dtos.Auth;
using ServicioUsers.Dtos.Health;

namespace ServicioUsers.Services;

public interface IAuthService
{
    //? LO QUE VA A REGRESAR                    LO QUE INGRESA
    Task<LoginResponseDto> LoginAsync(LoginRequestDto credentials);
    Task<RegisterResponseDto> RegisterAsync(RegisterRequestDto request);
}