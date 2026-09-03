using ServicioUsers.Dtos.Auth.Delete;
using ServicioUsers.Dtos.Auth.Login;
using ServicioUsers.Dtos.Auth.Register;
using ServicioUsers.Dtos.Auth.Update;

namespace ServicioUsers.Services;

public interface IAuthService
{
    //? LO QUE VA A REGRESAR                    LO QUE INGRESA
    Task<LoginResponseDto> LoginAsync(LoginRequestDto credentials);
    Task<RegisterResponseDto> RegisterAsync(RegisterRequestDto request);
    Task<DeleteUserResponseDto> DeleteByIdAsync(DeleteUserRequestDto request);
    Task<UpdateUserResponseDto> UpdateUserByIdAsync(UpdateUserRequestDto request);
}