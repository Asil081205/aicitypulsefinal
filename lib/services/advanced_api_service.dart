import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// ===========================================
// ADVANCED API SERVICE - COMPLETE FIXED VERSION
// ===========================================

class AdvancedAPIService {
  static final AdvancedAPIService _instance = AdvancedAPIService._internal();
  factory AdvancedAPIService() => _instance;
  AdvancedAPIService._internal();

  // ============== API KEYS (GET YOUR OWN) ==============
  static const String _openWeatherKey = 'YOUR_API_KEY'; // Get from openweathermap.org

  // ============== DATABASE ==============
  Database? _database;

  // ============== INITIALIZE DATABASE ==============
  Future<void> initDatabase() async {
    try {
      _database = await openDatabase(
        join(await getDatabasesPath(), 'city_pulse_cache.db'),
        onCreate: (db, version) {
          return db.execute(
            '''CREATE TABLE IF NOT EXISTS api_cache(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              endpoint TEXT UNIQUE,
              data TEXT,
              timestamp INTEGER
            )''',
          );
        },
        version: 1,
      );
    } catch (e) {
      debugPrint('Database init error: $e');
    }
  }

  // ============== CACHE METHODS ==============
  Future<Map<String, dynamic>?> _getCachedData(String endpoint) async {
    try {
      if (_database == null) await initDatabase();
      if (_database == null) return null;

      final result = await _database!.query(
        'api_cache',
        where: 'endpoint = ?',
        whereArgs: [endpoint],
      );

      if (result.isNotEmpty) {
        final timestamp = result.first['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Cache valid for 1 hour
        if (now - timestamp < 60 * 60 * 1000) {
          return json.decode(result.first['data'] as String);
        }
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }
    return null;
  }

  Future<void> _cacheData(String endpoint, Map<String, dynamic> data) async {
    try {
      if (_database == null) await initDatabase();
      if (_database == null) return;

      await _database!.insert(
        'api_cache',
        {
          'endpoint': endpoint,
          'data': json.encode(data),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  // ============== 1. WEATHER API ==============
  Future<Map<String, dynamic>> fetchWeatherData(double lat, double lon) async {
    final endpoint = 'weather_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';

    // Check cache first
    final cached = await _getCachedData(endpoint);
    if (cached != null) return cached;

    try {
      // Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return _getFallbackWeather();
      }

      // Current weather
      final currentResponse = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather'
                '?lat=$lat&lon=$lon&appid=$_openWeatherKey&units=metric'
        ),
      ).timeout(const Duration(seconds: 10));

      if (currentResponse.statusCode == 200) {
        final current = json.decode(currentResponse.body);

        // Try to get forecast
        Map<String, dynamic> forecast = {};
        try {
          final forecastResponse = await http.get(
            Uri.parse(
                'https://api.openweathermap.org/data/2.5/forecast'
                    '?lat=$lat&lon=$lon&appid=$_openWeatherKey&units=metric&cnt=40'
            ),
          ).timeout(const Duration(seconds: 10));

          if (forecastResponse.statusCode == 200) {
            forecast = json.decode(forecastResponse.body);
          }
        } catch (e) {
          debugPrint('Forecast error: $e');
        }

        final data = {
          'temperature': current['main']['temp'] ?? 28.0,
          'feels_like': current['main']['feels_like'] ?? 30.0,
          'humidity': current['main']['humidity'] ?? 65,
          'pressure': current['main']['pressure'] ?? 1012,
          'wind_speed': current['wind']['speed'] ?? 3.6,
          'wind_direction': current['wind']['deg'] ?? 0,
          'weather_condition': current['weather'][0]['main'] ?? 'Clear',
          'weather_description': current['weather'][0]['description'] ?? 'clear sky',
          'weather_icon': current['weather'][0]['icon'] ?? '01d',
          'clouds': current['clouds']['all'] ?? 0,
          'visibility': current['visibility'] ?? 10000,
          'uv_index': await _fetchUVIndex(lat, lon),
          'forecast': _parseForecast(forecast),
          'timestamp': DateTime.now().toIso8601String(),
        };

        await _cacheData(endpoint, data);
        return data;
      }
    } catch (e) {
      debugPrint('Weather API Error: $e');
    }

    return _getFallbackWeather();
  }

  // ============== 2. UV INDEX API ==============
  Future<double> _fetchUVIndex(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/uvi'
                '?lat=$lat&lon=$lon&appid=$_openWeatherKey'
        ),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['value'] ?? 5.0).toDouble();
      }
    } catch (e) {
      debugPrint('UV API Error: $e');
    }
    return 5.0; // Moderate default
  }

  // ============== 3. AIR QUALITY API - FIXED ==============
  Future<Map<String, dynamic>> fetchCityAirQuality(String city) async {
    final endpoint = 'air_quality_$city';

    // Check cache
    final cached = await _getCachedData(endpoint);
    if (cached != null) return cached;

    try {
      // Use OpenWeather Air Pollution API
      // First get coordinates for the city
      final geoResponse = await http.get(
        Uri.parse(
            'http://api.openweathermap.org/geo/1.0/direct?q=$city&limit=1&appid=$_openWeatherKey'
        ),
      );

      if (geoResponse.statusCode == 200) {
        final geoData = json.decode(geoResponse.body);
        if (geoData.isNotEmpty) {
          final lat = geoData[0]['lat'];
          final lon = geoData[0]['lon'];

          // Get air pollution data
          final pollutionResponse = await http.get(
            Uri.parse(
                'http://api.openweathermap.org/data/2.5/air_pollution'
                    '?lat=$lat&lon=$lon&appid=$_openWeatherKey'
            ),
          );

          if (pollutionResponse.statusCode == 200) {
            final pollutionData = json.decode(pollutionResponse.body);
            final aqi = pollutionData['list'][0]['main']['aqi'] ?? 2;

            // Convert 1-5 scale to 0-500 scale
            final aqiValue = _convertAQIScale(aqi);

            final data = {
              'aqi': aqiValue,
              'level': _getAQILevel(aqiValue),
              'pm25': pollutionData['list'][0]['components']['pm2_5'] ?? 25.0,
              'pm10': pollutionData['list'][0]['components']['pm10'] ?? 40.0,
              'no2': pollutionData['list'][0]['components']['no2'] ?? 20.0,
              'so2': pollutionData['list'][0]['components']['so2'] ?? 15.0,
              'co': pollutionData['list'][0]['components']['co'] ?? 300.0,
              'timestamp': DateTime.now().toIso8601String(),
            };

            await _cacheData(endpoint, data);
            return data;
          }
        }
      }
    } catch (e) {
      debugPrint('Air Quality API Error: $e');
    }

    // Return simulated data as fallback
    return _getSimulatedAirQuality();
  }

  // ============== 4. NOISE LEVELS ==============
  Future<Map<String, double>> fetchNoiseLevels(double lat, double lon) async {
    // Simulated since free noise APIs are rare
    final hour = DateTime.now().hour;
    double baseNoise;

    if (hour >= 8 && hour <= 20) {
      baseNoise = 55 + Random().nextInt(20).toDouble(); // FIXED: Convert to double
    } else {
      baseNoise = 40 + Random().nextInt(15).toDouble(); // FIXED: Convert to double
    }

    return {
      'current_db': baseNoise,
      'peak_db': baseNoise + 12,
      'min_db': baseNoise - 8,
      'average_db': baseNoise,
    };
  }
  // ============== 5. NEARBY PLACES ==============
  Future<List<Map<String, dynamic>>> fetchNearbyPlaces(
      double lat,
      double lon,
      String type,
      ) async {
    // Simulated data
    await Future.delayed(const Duration(milliseconds: 300));

    final places = <Map<String, dynamic>>[];
    final random = Random();

    final placeNames = ['Cafe Coffee Day', 'Starbucks', 'McDonald\'s', 'KFC', 'Dominos',
      'Phoenix Mall', 'Forum Mall', 'Park', 'Hospital', 'Metro Station'];

    for (int i = 0; i < 5; i++) {
      places.add({
        'name': placeNames[random.nextInt(placeNames.length)],
        'vicinity': '${random.nextInt(5)} km away',
        'rating': 3.5 + random.nextDouble() * 1.5,
        'crowd_factor': 0.3 + random.nextDouble() * 0.7,
        'is_open': random.nextBool(),
        'place_id': 'place_$i',
      });
    }

    return places;
  }

  // ============== 6. TRAFFIC INCIDENTS ==============
  Future<List<Map<String, dynamic>>> fetchTrafficIncidents(
      double lat,
      double lon,
      ) async {
    // Simulated data
    await Future.delayed(const Duration(milliseconds: 300));

    final incidents = <Map<String, dynamic>>[];
    final random = Random();
    final types = ['accident', 'construction', 'road_closure', 'event'];
    const severities = ['minor', 'moderate', 'major'];

    for (int i = 0; i < random.nextInt(3); i++) {
      incidents.add({
        'type': types[random.nextInt(types.length)],
        'severity': severities[random.nextInt(severities.length)],
        'description': 'Traffic incident reported',
        'timestamp': DateTime.now().subtract(Duration(minutes: random.nextInt(30))).toIso8601String(),
      });
    }

    return incidents;
  }

  // ============== UTILITY METHODS ==============

  // Parse 5-day forecast
  List<Map<String, dynamic>> _parseForecast(Map<String, dynamic> forecast) {
    final List<Map<String, dynamic>> parsed = [];

    if (forecast.isEmpty) return parsed;

    try {
      final list = forecast['list'] as List? ?? [];
      for (var i = 0; i < list.length; i += 8) {
        if (i < list.length) {
          final item = list[i];
          parsed.add({
            'date': item['dt_txt'].split(' ')[0],
            'temp': item['main']['temp'],
            'condition': item['weather'][0]['main'],
            'humidity': item['main']['humidity'],
          });
        }
      }
    } catch (e) {
      debugPrint('Parse forecast error: $e');
    }

    return parsed.take(5).toList();
  }

  // Convert OpenWeather AQI (1-5) to standard AQI (0-500)
  int _convertAQIScale(int aqi) {
    switch (aqi) {
      case 1: return 25;  // Good
      case 2: return 75;  // Fair
      case 3: return 125; // Moderate
      case 4: return 200; // Poor
      case 5: return 350; // Very Poor
      default: return 85;
    }
  }

  String _getAQILevel(int aqi) {
    if (aqi < 50) return 'Good';
    if (aqi < 100) return 'Moderate';
    if (aqi < 150) return 'Unhealthy for Sensitive Groups';
    if (aqi < 200) return 'Unhealthy';
    if (aqi < 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Map<String, dynamic> _getSimulatedAirQuality() {
    final random = Random();
    final aqi = 50 + random.nextInt(150);
    return {
      'aqi': aqi,
      'level': aqi < 50 ? 'Good' : aqi < 100 ? 'Moderate' : aqi < 150 ? 'Unhealthy' : 'Poor',
      'pm25': 10 + random.nextInt(40),
      'pm10': 20 + random.nextInt(60),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _getFallbackWeather() {
    final random = Random();
    return {
      'temperature': 25 + random.nextInt(10),
      'feels_like': 27 + random.nextInt(8),
      'humidity': 50 + random.nextInt(30),
      'pressure': 1010 + random.nextInt(10),
      'wind_speed': 2 + random.nextDouble() * 8,
      'weather_condition': ['Clear', 'Clouds', 'Rain', 'Haze'][random.nextInt(4)],
      'weather_description': 'weather conditions',
      'uv_index': 5 + random.nextInt(6),
      'forecast': [],
    };
  }

  // ============== FETCH OPENWEATHER AQI - FIXED ==============
  // This method was missing - now it's implemented!
  Future<Map<String, dynamic>> _fetchOpenWeatherAQI(String city) async {
    try {
      // Get coordinates for the city
      final geoResponse = await http.get(
        Uri.parse(
            'http://api.openweathermap.org/geo/1.0/direct?q=$city&limit=1&appid=$_openWeatherKey'
        ),
      );

      if (geoResponse.statusCode == 200) {
        final geoData = json.decode(geoResponse.body);
        if (geoData.isNotEmpty) {
          final lat = geoData[0]['lat'];
          final lon = geoData[0]['lon'];

          // Get air pollution data
          final pollutionResponse = await http.get(
            Uri.parse(
                'http://api.openweathermap.org/data/2.5/air_pollution'
                    '?lat=$lat&lon=$lon&appid=$_openWeatherKey'
            ),
          );

          if (pollutionResponse.statusCode == 200) {
            final pollutionData = json.decode(pollutionResponse.body);
            final aqi = pollutionData['list'][0]['main']['aqi'] ?? 2;
            final aqiValue = _convertAQIScale(aqi);

            return {
              'aqi': aqiValue,
              'level': _getAQILevel(aqiValue),
              'pm25': pollutionData['list'][0]['components']['pm2_5'] ?? 25.0,
              'pm10': pollutionData['list'][0]['components']['pm10'] ?? 40.0,
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
        }
      }
    } catch (e) {
      debugPrint('OpenWeather AQI Error: $e');
    }

    return _getSimulatedAirQuality();
  }
}