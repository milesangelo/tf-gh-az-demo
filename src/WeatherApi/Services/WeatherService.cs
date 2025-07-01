using Microsoft.EntityFrameworkCore;
using WeatherApi.Data;
using WeatherApi.Models;

namespace WeatherApi.Services;

public class WeatherService : IWeatherService
{
    private readonly WeatherContext _context;
    private readonly ILogger<WeatherService> _logger;

    public WeatherService(WeatherContext context, ILogger<WeatherService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<IEnumerable<WeatherRecord>> GetCurrentWeatherAsync()
    {
        return await _context.WeatherRecords
            .OrderByDescending(w => w.RecordedAt)
            .Take(10)
            .ToListAsync();
    }

    public async Task<WeatherRecord?> GetWeatherByCityAsync(string city)
    {
        return await _context.WeatherRecords
            .Where(w => w.City.ToLower() == city.ToLower())
            .OrderByDescending(w => w.RecordedAt)
            .FirstOrDefaultAsync();
    }

    public async Task<WeatherRecord> CreateWeatherRecordAsync(CreateWeatherRecordRequest request)
    {
        var weatherRecord = new WeatherRecord
        {
            City = request.City,
            Temperature = request.Temperature,
            Humidity = request.Humidity,
            Description = request.Description,
            RecordedAt = DateTime.UtcNow
        };

        _context.WeatherRecords.Add(weatherRecord);
        await _context.SaveChangesAsync();

        return weatherRecord;
    }

    public async Task<IEnumerable<WeatherForecast>> GetWeatherForecastAsync(string city)
    {
        // Simulated forecast based on current weather
        var currentWeather = await GetWeatherByCityAsync(city);
        
        if (currentWeather == null)
        {
            return Enumerable.Empty<WeatherForecast>();
        }

        var random = new Random();
        var forecasts = new List<WeatherForecast>();

        for (int i = 1; i <= 5; i++)
        {
            forecasts.Add(new WeatherForecast
            {
                Date = DateTime.UtcNow.AddDays(i),
                Temperature = currentWeather.Temperature + random.Next(-5, 6),
                Humidity = Math.Max(0, Math.Min(100, currentWeather.Humidity + random.Next(-20, 21))),
                Description = GenerateRandomDescription()
            });
        }

        return forecasts;
    }

    private static string GenerateRandomDescription()
    {
        var descriptions = new[]
        {
            "Sunny", "Partly cloudy", "Cloudy", "Overcast", "Light rain",
            "Heavy rain", "Thunderstorms", "Snow", "Foggy", "Windy"
        };
        
        var random = new Random();
        return descriptions[random.Next(descriptions.Length)];
    }
}