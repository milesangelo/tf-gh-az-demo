using System.ComponentModel.DataAnnotations;

namespace WeatherApi.Models;

public class WeatherRecord
{
    public int Id { get; set; }
    
    [Required]
    [StringLength(100)]
    public string City { get; set; } = string.Empty;
    
    [Range(-50, 60)]
    public double Temperature { get; set; }
    
    [Range(0, 100)]
    public int Humidity { get; set; }
    
    [StringLength(200)]
    public string Description { get; set; } = string.Empty;
    
    public DateTime RecordedAt { get; set; } = DateTime.UtcNow;
}

public class CreateWeatherRecordRequest
{
    [Required]
    [StringLength(100)]
    public string City { get; set; } = string.Empty;
    
    [Range(-50, 60)]
    public double Temperature { get; set; }
    
    [Range(0, 100)]
    public int Humidity { get; set; }
    
    [StringLength(200)]
    public string Description { get; set; } = string.Empty;
}

public class WeatherForecast
{
    public DateTime Date { get; set; }
    public double Temperature { get; set; }
    public int Humidity { get; set; }
    public string Description { get; set; } = string.Empty;
}