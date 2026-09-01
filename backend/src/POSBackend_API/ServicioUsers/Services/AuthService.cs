using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using ServicioUsers.Data;
using ServicioUsers.Dtos;
using ServicioUsers.Dtos.Auth;
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

        public async Task<RegisterResponseDto> RegisterAsync(RegisterRequestDto request)
        {
            var sql = "CALL public.sp_a_insert_users(@p_username, @p_password, @p_firstname, @p_lastname, @p_roleid)";

            await _context.Database.ExecuteSqlRawAsync(sql,
            new NpgsqlParameter("p_username", request.Username),
            new NpgsqlParameter("p_password", request.Password),
            new NpgsqlParameter("p_firstname", request.Firstname),
            new NpgsqlParameter("p_lastname", request.Lastname),
            new NpgsqlParameter("p_roleid", request.Roleid)
            );

            return new RegisterResponseDto
            {
                Success = true,
                Message = "Usuario registrado exitosamente",
                Roleid = request.Roleid,
                created_at = DateTime.UtcNow
            };
        }
    }
}