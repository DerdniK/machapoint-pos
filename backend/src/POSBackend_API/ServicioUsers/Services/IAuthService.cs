using ServicioUsers.Dtos;

namespace ServicioUsers.Services;

public interface IAuthService
{
    //? LO QUE VA A REGRESAR                    LO QUE INGRESA
    Task<LoginResponseDto> LoginAsync(LoginRequestDto credentials);
}