using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using WebApi.Models;
using System.Security.Claims;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
using WebApi.Services;
using System.Security.Cryptography;
using System.Text;

var builder = WebApplication.CreateBuilder(args);
string? connectionString = builder.Configuration.GetConnectionString("RentalEquipmentManagement");

builder.Services.AddDbContext<RentalEquipmentManagementContext>(p => p.UseSqlServer(connectionString));

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<SiteProvider>();
builder.Services.AddHttpClient("external", client => client.Timeout = TimeSpan.FromSeconds(12))
    .ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler { AllowAutoRedirect = false })
    .RemoveAllLoggers();
builder.Services.AddScoped<SocialLogin>();
builder.Services.AddScoped<PaymentGateway>();
builder.Services.AddMemoryCache();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("account", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "local",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 20, Window = TimeSpan.FromMinutes(1) }));
});

builder.Configuration["Jwt:Issuer"] ??= "RentalEquipmentManagement";
builder.Configuration["Jwt:Audience"] ??= "RentalEquipmentApp";
builder.Configuration["Jwt:Expires"] ??= "1";
builder.Configuration["Jwt:SecretKey"] ??= Convert.ToHexString(RandomNumberGenerator.GetBytes(32));

builder.Services.AddCors(options => options.AddDefaultPolicy(policy =>
    policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

builder.Services.AddAuthentication(p => {
    p.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    p.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(p =>
{
   p.TokenValidationParameters = new Microsoft.IdentityModel.Tokens.TokenValidationParameters
{
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.ASCII.GetBytes(
                builder.Configuration["Jwt:SecretKey"]
                ?? throw new KeyNotFoundException("Jwt:SecretKey")
            )
        ),
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateIssuerSigningKey = true,
        ValidateLifetime = true
    };
    p.Events = new JwtBearerEvents
    {
        OnTokenValidated = async context =>
        {
            var principal = context.Principal!;
            var id = principal.FindFirstValue(ClaimTypes.NameIdentifier);
            var db = context.HttpContext.RequestServices.GetRequiredService<RentalEquipmentManagementContext>();
            var member = await db.Members.AsNoTracking().FirstOrDefaultAsync(p => p.Id == id);
            if (member == null || !member.IsActive || principal.FindFirstValue(ClaimTypes.Role) != member.Role.ToString()
                || (principal.FindFirstValue("ver") ?? "0") != member.SecurityVersion.ToString(System.Globalization.CultureInfo.InvariantCulture))
                context.Fail("Account status or role changed. Sign in again.");
        }
    };
});

builder.Services.AddControllers();
var app = builder.Build();

app.UseCors();
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();
app.UseDefaultFiles();
app.UseStaticFiles();
app.MapControllers();

app.Run();
