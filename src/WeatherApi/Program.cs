using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.EntityFrameworkCore;
using WeatherApi.Data;
using WeatherApi.Models;
using WeatherApi.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add Application Insights
builder.Services.AddApplicationInsightsTelemetry();

// Add Entity Framework
builder.Services.AddDbContext<WeatherContext>(options =>
{
    var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
    options.UseSqlServer(connectionString);
});

// Add custom services
builder.Services.AddScoped<IWeatherService, WeatherService>();

// Add health checks
builder.Services.AddHealthChecks()
    .AddDbContextCheck<WeatherContext>();

// Add CORS for demo purposes
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(builder =>
    {
        builder.AllowAnyOrigin()
               .AllowAnyHeader()
               .AllowAnyMethod();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment() || app.Environment.IsStaging())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors();
app.UseAuthorization();

// Add health check endpoint
app.MapHealthChecks("/health");

app.MapControllers();

// Ensure database is created and seeded
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<WeatherContext>();
    context.Database.EnsureCreated();
    await SeedData(context);
}

app.Run();

static async Task SeedData(WeatherContext context)
{
    if (!await context.WeatherRecords.AnyAsync())
    {
        var records = new[]
        {
            new WeatherRecord { City = "New York", Temperature = 22, Humidity = 65, Description = "Partly cloudy", RecordedAt = DateTime.UtcNow.AddHours(-1) },
            new WeatherRecord { City = "Los Angeles", Temperature = 28, Humidity = 55, Description = "Sunny", RecordedAt = DateTime.UtcNow.AddHours(-2) },
            new WeatherRecord { City = "Chicago", Temperature = 18, Humidity = 70, Description = "Cloudy", RecordedAt = DateTime.UtcNow.AddHours(-3) },
            new WeatherRecord { City = "Houston", Temperature = 31, Humidity = 80, Description = "Hot and humid", RecordedAt = DateTime.UtcNow.AddHours(-4) },
            new WeatherRecord { City = "Phoenix", Temperature = 35, Humidity = 30, Description = "Very hot and dry", RecordedAt = DateTime.UtcNow.AddHours(-5) }
        };

        context.WeatherRecords.AddRange(records);
        await context.SaveChangesAsync();
    }
}