using Microsoft.AspNetCore.Mvc;
using WeatherApi.Models;
using WeatherApi.Services;

namespace WeatherApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class WeatherController : ControllerBase
{
    private readonly IWeatherService _weatherService;
    private readonly ILogger<WeatherController> _logger;

    public WeatherController(IWeatherService weatherService, ILogger<WeatherController> logger)
    {
        _weatherService = weatherService;
        _logger = logger;
    }

    /// <summary>
    /// Get current weather for all cities
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<WeatherRecord>>> GetCurrentWeather()
    {
        _logger.LogInformation("Getting current weather for all cities");
        
        try
        {
            var weather = await _weatherService.GetCurrentWeatherAsync();
            return Ok(weather);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting current weather");
            return StatusCode(500, "An error occurred while fetching weather data");
        }
    }

    /// <summary>
    /// Get current weather for a specific city
    /// </summary>
    [HttpGet("{city}")]
    public async Task<ActionResult<WeatherRecord>> GetWeatherByCity(string city)
    {
        _logger.LogInformation("Getting weather for city: {City}", city);
        
        try
        {
            var weather = await _weatherService.GetWeatherByCityAsync(city);
            
            if (weather == null)
            {
                _logger.LogWarning("Weather data not found for city: {City}", city);
                return NotFound($"Weather data not found for city: {city}");
            }

            return Ok(weather);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting weather for city: {City}", city);
            return StatusCode(500, "An error occurred while fetching weather data");
        }
    }

    /// <summary>
    /// Add new weather record
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<WeatherRecord>> CreateWeatherRecord([FromBody] CreateWeatherRecordRequest request)
    {
        _logger.LogInformation("Creating weather record for city: {City}", request.City);
        
        try
        {
            var weatherRecord = await _weatherService.CreateWeatherRecordAsync(request);
            return CreatedAtAction(nameof(GetWeatherByCity), new { city = weatherRecord.City }, weatherRecord);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating weather record for city: {City}", request.City);
            return StatusCode(500, "An error occurred while creating weather record");
        }
    }

    /// <summary>
    /// Get weather forecast (simulated)
    /// </summary>
    [HttpGet("forecast/{city}")]
    public async Task<ActionResult<IEnumerable<WeatherForecast>>> GetWeatherForecast(string city)
    {
        _logger.LogInformation("Getting weather forecast for city: {City}", city);
        
        try
        {
            var forecast = await _weatherService.GetWeatherForecastAsync(city);
            return Ok(forecast);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting weather forecast for city: {City}", city);
            return StatusCode(500, "An error occurred while fetching weather forecast");
        }
    }

    /// <summary>
    /// Health check endpoint
    /// </summary>
    [HttpGet("/health")]
    public IActionResult Health()
    {
        return Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
    }
}