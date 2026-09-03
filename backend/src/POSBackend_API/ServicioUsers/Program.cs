using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Amazon.Lambda.AspNetCoreServer.Hosting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using ServicioUsers.Data;
using ServicioUsers.Services;

DotNetEnv.Env.TraversePath().Load(); // Cargar el .env

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddEnvironmentVariables();

// Integración con AWS Lambda (HTTP API)
builder.Services.AddAWSLambdaHosting(LambdaEventSource.HttpApi);

// CORS para entorno local
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Cadena de conexión a Supabase
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");

builder.Services.AddDbContext<SupaDBContext>(options =>
    options.UseNpgsql(connectionString));

// Inyección de dependencias de ServicioUsers
builder.Services.AddScoped<IHealthService, HealthService>();
builder.Services.AddScoped<IAuthService, AuthService>();

// Lectura del JWT Secret con soporte Base64 y UTF8 (para paridad con la generación en AuthService)
var secretKey = builder.Configuration["JwtSettings:SecretKey"]
    ?? Environment.GetEnvironmentVariable("JwtSettings__SecretKey")
    ?? throw new InvalidOperationException("JwtSettings:SecretKey no está configurada en las variables de entorno.");

byte[] keyBytes;
try
{
    keyBytes = Convert.FromBase64String(secretKey);
}
catch (FormatException)
{
    keyBytes = Encoding.UTF8.GetBytes(secretKey);
}

var localSigningKey = new SymmetricSecurityKey(keyBytes);
var supabaseUrl = "https://rbhdpforntgwfbuqychm.supabase.co";

JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();

// Autenticación dual / dinámica
builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = "DynamicAuth";
    options.DefaultAuthenticateScheme = "DynamicAuth";
    options.DefaultChallengeScheme = "DynamicAuth";
})
.AddPolicyScheme("DynamicAuth", "Supabase or Local JWT", options =>
{
    options.ForwardDefaultSelector = context =>
    {
        string? authHeader = context.Request.Headers["Authorization"].FirstOrDefault();
        if (string.IsNullOrWhiteSpace(authHeader))
        {
            authHeader = context.Request.Headers.Authorization.FirstOrDefault();
        }

        if (string.IsNullOrWhiteSpace(authHeader) || !authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        {
            return "LocalAuth";
        }

        var tokenStr = authHeader.Substring(7).Trim();
        var handler = new JwtSecurityTokenHandler();

        if (handler.CanReadToken(tokenStr))
        {
            try
            {
                var jwt = handler.ReadJwtToken(tokenStr);

                // Si proviene de Supabase (Google OAuth)
                if ((!string.IsNullOrEmpty(jwt.Issuer) && jwt.Issuer.Contains("supabase", StringComparison.OrdinalIgnoreCase)) ||
                    string.Equals(jwt.Header.Alg, "ES256", StringComparison.OrdinalIgnoreCase))
                {
                    return "SupabaseAuth";
                }
            }
            catch
            {
                return "LocalAuth";
            }
        }

        // Token manual generado por AuthService (HS256)
        return "LocalAuth";
    };
})
// Validador 1: Usuarios locales creados a mano (Gustambito - HS256)
.AddJwtBearer("LocalAuth", options =>
{
    options.UseSecurityTokenValidators = true;
    options.MapInboundClaims = false;
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;

    // Supabase expone las llaves públicas para verificar firmas ES256
    options.MetadataAddress = $"{supabaseUrl}/auth/v1/.well-known/openid-configuration";

    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = localSigningKey,
        IssuerSigningKeyResolver = (token, securityToken, kid, validationParameters) => new[] { localSigningKey },
        ValidateIssuer = false,
        ValidateAudience = false,
        ValidateLifetime = true,
        ClockSkew = TimeSpan.FromMinutes(5),
        RoleClaimType = "role",
        NameClaimType = "username"
    };

    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = context =>
        {
            // Mapeo defensivo: asegura que el claim "role" también exista en ClaimTypes.Role
            if (context.Principal?.Identity is ClaimsIdentity identity)
            {
                var roleClaim = identity.FindFirst("role")?.Value;
                if (!string.IsNullOrEmpty(roleClaim) && !identity.HasClaim(c => c.Type == ClaimTypes.Role))
                {
                    identity.AddClaim(new Claim(ClaimTypes.Role, roleClaim));
                }
            }
            Console.WriteLine($"[Users - LocalAuth OK] Usuario autenticado.");
            return Task.CompletedTask;
        },
        OnAuthenticationFailed = context =>
        {
            Console.WriteLine($"[Users - LocalAuth FAIL] {context.Exception.Message}");
            return Task.CompletedTask;
        }
    };
})
// Validador 2: Google OAuth / Supabase (ES256)
.AddJwtBearer("SupabaseAuth", options =>
{
    options.UseSecurityTokenValidators = true;
    options.MapInboundClaims = false;
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.MetadataAddress = $"{supabaseUrl}/auth/v1/.well-known/openid-configuration";
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        ValidateIssuer = true,
        ValidIssuer = $"{supabaseUrl}/auth/v1",
        ValidateAudience = true,
        ValidAudience = "authenticated",
        ValidateLifetime = true,
        ClockSkew = TimeSpan.FromMinutes(5),
        RoleClaimType = "role",
        NameClaimType = "email"
    };

    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = context =>
        {
            // Otorga permisos de Admin a usuarios que entraron por Google OAuth
            if (context.Principal?.Identity is ClaimsIdentity identity)
            {
                if (!identity.HasClaim(c => c.Type == "role" && c.Value == "Admin"))
                {
                    identity.AddClaim(new Claim("role", "Admin"));
                    identity.AddClaim(new Claim(ClaimTypes.Role, "Admin"));
                }
            }
            Console.WriteLine($"[Users - SupabaseAuth OK] Usuario Google autorizado.");
            return Task.CompletedTask;
        },
        OnAuthenticationFailed = context =>
        {
            Console.WriteLine($"[Users - SupabaseAuth FAIL] {context.Exception.Message}");
            return Task.CompletedTask;
        }
    };
});

// Políticas de autorización por rol (incluye "authenticated" para usuarios de Google)
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => 
        policy.RequireRole("Admin", "authenticated"));

    options.AddPolicy("CajeroOnly", policy => 
        policy.RequireRole("Cajero", "Admin", "authenticated"));
});

builder.Services.AddControllers();

var app = builder.Build();

// app.UseCors("AllowAll");

app.UseAuthentication(); // Valida el JWT
app.UseAuthorization();  // Valida permisos/roles

app.MapControllers();

app.Run();