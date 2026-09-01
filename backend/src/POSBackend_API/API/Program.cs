using Microsoft.EntityFrameworkCore;
using Npgsql.EntityFrameworkCore.PostgreSQL;
using POSBackend_API.Services;
using POSBackend_API.Data;
using POSBackend_API.Security;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

DotNetEnv.Env.TraversePath().Load(); // Cargar el .env

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddEnvironmentVariables();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<SupaDBContext>(options =>
    options.UseNpgsql(connectionString));

builder.Services.AddAWSLambdaHosting(LambdaEventSource.HttpApi);

builder.Services.AddScoped<JwtTokenGenerator>();
builder.Services.AddScoped<IHealthService, HealthService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IProductService, ProductService>();

var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secretKey = jwtSettings["JwtSettings:SecretKey"]
    ?? Environment.GetEnvironmentVariable("JwtSettings__SecretKey")
    ?? throw new InvalidOperationException("JwtSettings:SecretKey no está configurada en las variables de entorno.");

var issuer = builder.Configuration["JwtSettings:Issuer"] 
    ?? Environment.GetEnvironmentVariable("JwtSettings__Issuer");

var audience = builder.Configuration["JwtSettings:Audience"] 
    ?? Environment.GetEnvironmentVariable("JwtSettings__Audience");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = issuer,
        ValidAudience = audience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddControllers();

var app = builder.Build();

app.UseCors("AllowAll");
app.UseAuthentication(); // Valida el JWT
app.UseAuthorization();  // Valida permisos/roles
app.MapControllers();


app.Run();
