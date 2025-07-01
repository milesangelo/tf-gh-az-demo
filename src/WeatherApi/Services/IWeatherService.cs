using WeatherApi.Models;

namespace WeatherApi.Services;

public interface IWeatherService
{
    Task<IEnumerable<WeatherRecord>> GetCurrentWeatherAsync();
    Task<WeatherRecord?> GetWeatherByCityAsync(string city);
    Task<WeatherRecord> CreateWeatherRecordAsync(CreateWeatherRecordRequest request);
    Task<IEnumerable<WeatherForecast>> GetWeatherForecastAsync(string city);
}