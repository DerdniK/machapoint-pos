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

// URL base de tu proyecto en Supabase
var supabaseUrl = "https://rbhdpforntgwfbuqychm.supabase.co";

// Configuración JWT validando contra el JWKS oficial de Supabase (compatible con ES256)
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.MapInboundClaims = false;
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;

    // Supabase expone las llaves públicas para verificar firmas ES256
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
        RoleClaimType = "role"
    };
});

// Políticas de autorización por rol (incluye "authenticated" para usuarios de Google)
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin", "authenticated"));
    options.AddPolicy("CajeroOnly", policy => policy.RequireRole("Cajero", "authenticated"));
});

builder.Services.AddControllers();

var app = builder.Build();

// Si está activo el CORS en AWS Lambda Function URL, deja esta línea comentada
// app.UseCors("AllowAll");

app.UseAuthentication(); // Valida el JWT
app.UseAuthorization();  // Valida permisos/roles

app.MapControllers();

app.Run();