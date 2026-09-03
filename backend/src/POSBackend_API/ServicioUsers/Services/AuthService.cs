using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using ServicioUsers.Data;
using ServicioUsers.Dtos.Auth;
using ServicioUsers.Dtos.Auth.Delete;
using ServicioUsers.Dtos.Auth.Login;
using ServicioUsers.Dtos.Auth.Register;
using ServicioUsers.Dtos.Auth.Update;
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
            string passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

            var sql = "SELECT sp_a_insert_user(@p_username, @p_password, @p_firstname, @p_lastname, @p_roleid)";

            await _context.Database.ExecuteSqlRawAsync(sql,
            new NpgsqlParameter("p_username", request.Username),
            new NpgsqlParameter("p_password", passwordHash),
            new NpgsqlParameter("p_firstname", request.Firstname),
            new NpgsqlParameter("p_lastname", request.Lastname),
            new NpgsqlParameter("p_roleid", request.Roleid)
            );

            return new RegisterResponseDto
            {
                Success = true,
                Message = "Usuario registrado exitosamente",
                Username = request.Username,
                Roleid = request.Roleid,
                created_at = DateTime.UtcNow
            };
        }

        public async Task<DeleteUserResponseDto> DeleteByIdAsync(DeleteUserRequestDto request)
        {

            var sql = "SELECT sp_b_delete_user(@p_userid)";

            await _context.Database.ExecuteSqlRawAsync(sql,
            new NpgsqlParameter("p_userid", request.Userid)
            );

            var deletedId = request.Userid;

            return new DeleteUserResponseDto
            {
                Success = true,
                Message = "Usuario eliminado!",
                Deletedid = deletedId
            };
        }

        public async Task<UpdateUserResponseDto> UpdateUserByIdAsync(UpdateUserRequestDto request)
        {
            string? passwordHash = null;

            if (!string.IsNullOrWhiteSpace(request.Password))
            {
                passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
            }

            var sql = "SELECT sp_c_update_user(@p_userid, @p_username, @p_password, @p_firstname, @p_lastname, @p_roleid)";

            await _context.Database.ExecuteSqlRawAsync(sql,
            new NpgsqlParameter("p_userid", request.Userid),
            new NpgsqlParameter("p_username", (object?)request.Username ?? DBNull.Value),
            new NpgsqlParameter("p_password", (object?)passwordHash ?? DBNull.Value),
            new NpgsqlParameter("p_firstname", (object?)request.Firstname ?? DBNull.Value),
            new NpgsqlParameter("p_lastname", (object?)request.Lastname ?? DBNull.Value),
            new NpgsqlParameter("p_roleid", (object?)request.Roleid ?? DBNull.Value)
            );

            return new UpdateUserResponseDto
            {
                Success = true,
                Message = "Usuario actualizado!",
                Username = request.Username,
                Firstname = request.Firstname,
                Lastname = request.Lastname,
                Roleid = request.Roleid
            };
        }
    }
}