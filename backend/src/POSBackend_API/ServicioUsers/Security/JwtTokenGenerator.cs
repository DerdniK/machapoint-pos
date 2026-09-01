using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using ServicioUsers.Models;

namespace ServicioUsers.Security;

public class JwtTokenGenerator
{
    private readonly IConfiguration _config;

    public JwtTokenGenerator(IConfiguration config)
    {
        _config = config;
    }

    public string GenerateToken(User user)
    {
        // 1. Obtener los valores buscando en IConfiguration o directamente en las variables de entorno
        var secretKey = _config["JwtSettings:SecretKey"]
                     ?? Environment.GetEnvironmentVariable("JwtSettings__SecretKey")
                     ?? Environment.GetEnvironmentVariable("JWT_SECRET_KEY");

        // Validación de seguridad para evitar ArgumentNullException
        if (string.IsNullOrWhiteSpace(secretKey))
        {
            throw new InvalidOperationException("No se encontró la clave secreta de JWT (SecretKey) en la configuración ni en las variables de entorno.");
        }

        var issuer = _config["JwtSettings:Issuer"]
                  ?? Environment.GetEnvironmentVariable("JwtSettings__Issuer");

        var audience = _config["JwtSettings:Audience"]
                    ?? Environment.GetEnvironmentVariable("JwtSettings__Audience");

        var expirationHours = _config["JwtSettings:ExpirationInHours"]
                           ?? Environment.GetEnvironmentVariable("JwtSettings__ExpirationInHours") 
                           ?? "2";

        // 2. Definición de Claims
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.UserId.ToString()),
            new Claim("User_FirstName", user.First_name ?? ""),
            new Claim("User_LastName", user.Last_name ?? ""),
            new Claim("roleId", user.RoleID.ToString() ?? "")
        };

        // 3. Firma del token
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddHours(double.Parse(expirationHours)),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}