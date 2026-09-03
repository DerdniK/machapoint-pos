using System.IdentityModel.Tokens.Jwt;
using System.Text;
using Amazon.Lambda.AspNetCoreServer.Hosting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using ServicioProducts.Data;
using ServicioProducts.Services;

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

// Conexión a Base de Datos (Supabase PostgreSQL)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");

builder.Services.AddDbContext<SupaDBContext>(options =>
    options.UseNpgsql(connectionString));

// Inyección de dependencias
builder.Services.AddScoped<IProductService, ProductService>();

// Lectura de configuración JWT (Supabase JWT Secret)
var secretKey = builder.Configuration["JwtSettings:SecretKey"]
    ?? Environment.GetEnvironmentVariable("JwtSettings__SecretKey")
    ?? throw new InvalidOperationException("JwtSettings:SecretKey no está configurada en las variables de entorno.");

var keyBytes = Encoding.UTF8.GetBytes(secretKey);

JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();

// Autenticación JWT y lectura de Roles
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
        ValidateIssuer = false,
        ValidateAudience = false,
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero,
        RoleClaimType = "role" // Permite usar [Authorize(Roles = "Admin")] leyendo el claim "role"
    };
});

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("CajeroOnly", policy => policy.RequireRole("Cajero"));
});

builder.Services.AddControllers();

var app = builder.Build();

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();