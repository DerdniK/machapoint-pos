using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServicioUsers.Data;
using ServicioUsers.Dtos;
using ServicioUsers.Security;

namespace ServicioUsers.Services
{
    public class AuthService : IAuthService
    {
        private readonly SupaDBContext _context;
        private readonly JwtTokenGenerator _jwtTokenGenerator;

        public AuthService(SupaDBContext context, JwtTokenGenerator jwtTokenGenerator) //? Inyeccion de dependencias, dynamo y jwt
        {
            _context = context;
            _jwtTokenGenerator = jwtTokenGenerator;
        }


        public async Task<LoginResponseDto> LoginAsync(LoginRequestDto credentials)
        {
            var user = await _context.UserTable //^ Esto trae el username
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Username == credentials.Username);

            if(credentials.Password == "")
            {
                return new LoginResponseDto
            {
                Success = false,
                Message = "You don't introduce a password"
            };
            }else if(credentials.Username == "")
            {
                return new LoginResponseDto
            {
                Success = false,
                Message = "You don't introduce a username"
            };
            }else if (user is null || !BCrypt.Net.BCrypt.Verify(credentials.Password, user.PasswordHash))
            {
                return new LoginResponseDto
            {
                Success = false,
                Message = "Wrong credentials"
            };
            }


            string token = _jwtTokenGenerator.GenerateToken(user);

            return new LoginResponseDto
            {
                Success = true,
                Message = "Login succesfull!",
                AuthData = new AuthResponseDto
                {
                    Token = token
                }
            };
        }
    }
}