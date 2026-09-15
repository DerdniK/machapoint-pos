using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Amazon.Lambda.AspNetCoreServer.Hosting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using ServicioCut.Data;
using ServicioCut.Services;

DotNetEnv.Env.TraversePath().Load();

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddEnvironmentVariables();

// Integración con AWS Lambda (HTTP API / Gateway v2)
builder.Services.AddAWSLambdaHosting(LambdaEventSource.HttpApi);

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Conexión a Base de Datos (Mantiene SupaDBContext)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");

builder.Services.AddDbContext<SupaDBContext>(options =>
    options.UseNpgsql(connectionString));

// Inyección de dependencias para cortes de caja (ServicioCut)
builder.Services.AddScoped<ICutService, CutService>();

// Lectura de clave secreta con soporte para Base64 y UTF8 (paridad con ServicioUsers)
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
var supabaseUrl = builder.Configuration["Supabase:Url"]
    ?? Environment.GetEnvironmentVariable("Supabase__Url")
    ?? "https://rbhdpforntgwfbuqychm.supabase.co";

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

                // Si proviene de Supabase (Google) o usa algoritmo asimétrico ES256
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

        // Token generado por ServicioUsers (HS256)
        return "LocalAuth";
    };
})
// Validador 1: Tokens locales propios (HS256)
.AddJwtBearer("LocalAuth", options =>
{
    options.UseSecurityTokenValidators = true;
    options.MapInboundClaims = false;
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;

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
        OnAuthenticationFailed = context =>
        {
            Console.WriteLine($"[LocalAuth FAIL - Cut] {context.Exception.Message}");
            return Task.CompletedTask;
        },
        OnTokenValidated = context =>
        {
            Console.WriteLine($"[LocalAuth OK - Cut] Token validado con éxito");
            return Task.CompletedTask;
        }
    };
})
// Validador 2: Tokens de Google OAuth vía Supabase (ES256)
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
            // Otorga permisos de Admin al identity autenticado con Google
            if (context.Principal?.Identity is ClaimsIdentity identity)
            {
                if (!identity.HasClaim(c => c.Type == "role" && c.Value == "Admin"))
                {
                    identity.AddClaim(new Claim("role", "Admin"));
                    identity.AddClaim(new Claim(ClaimTypes.Role, "Admin"));
                }
            }
            Console.WriteLine($"[SupabaseAuth OK - Cut] Usuario autenticado y autorizado.");
            return Task.CompletedTask;
        },
        OnAuthenticationFailed = context =>
        {
            Console.WriteLine($"[SupabaseAuth FAIL - Cut] {context.Exception.Message}");
            return Task.CompletedTask;
        }
    };
});

// Políticas de autorización adaptadas para cortes y arqueos de caja
builder.Services.AddAuthorization(options =>
{
    // Para auditorías, ajustes forzados de corte o reportes globales
    options.AddPolicy("AdminOnly", policy => 
        policy.RequireRole("Admin", "authenticated"));

    // Cortes de caja regulares (Corte X / Parcial)
    options.AddPolicy("CajeroOnly", policy => 
        policy.RequireRole("Cajero", "Admin", "authenticated"));

    // Para cortes definitivos de fin de día (Corte Z) o arqueos ciegos
    options.AddPolicy("SupervisorOrAdmin", policy => 
        policy.RequireRole("Supervisor", "Admin", "authenticated"));
});

builder.Services.AddControllers();

var app = builder.Build();

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();