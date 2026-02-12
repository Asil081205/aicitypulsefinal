import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Position class for location data
class Position {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;
  final double altitude;
  final double heading;
  final double speed;
  final double speedAccuracy;
  final double altitudeAccuracy;
  final double headingAccuracy;

  Position({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy = 0,
    this.altitude = 0,
    this.heading = 0,
    this.speed = 0,
    this.speedAccuracy = 0,
    this.altitudeAccuracy = 0,
    this.headingAccuracy = 0,
  });
}

// FREE APIs - No payment required
class FreeAPIService {
  static final Random _random = Random();

  // Check internet connectivity
  static Future<bool> hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition();
      return Position(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        altitude: position.altitude,
        heading: position.heading,
        speed: position.speed,
        speedAccuracy: position.speedAccuracy,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } catch (e) {
      print('Location error: $e');
      return null;
    }
  }

  // Get address from coordinates (Free - OpenStreetMap)
// Get address from coordinates (Free - OpenStreetMap) - REAL IMPLEMENTATION
  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final hasInternet = await FreeAPIService.hasInternet();
      if (!hasInternet) {
        return _getFallbackAddress(lat, lng);
      }

      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'AICityPulse/2.0.0', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];

        // Build address from real components
        String city = address['city'] ??
            address['town'] ??
            address['village'] ??
            address['suburb'] ??
            'Unknown';

        String state = address['state'] ??
            address['state_district'] ??
            '';

        String country = address['country'] ?? '';

        if (city.isNotEmpty && state.isNotEmpty) {
          return '$city, $state';
        } else if (city.isNotEmpty) {
          return city;
        }
        return data['display_name']?.split(',').take(2).join(',') ?? 'Unknown Location';
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    return _getFallbackAddress(lat, lng);
  }

  static String _getFallbackAddress(double lat, double lng) {
    // Reverse geocode approximate location based on coordinates
    if (lat > 8 && lat < 14 && lng > 77 && lng < 81) {
      return 'Chennai, Tamil Nadu';
    } else if (lat > 18 && lat < 23 && lng > 72 && lng < 76) {
      return 'Mumbai, Maharashtra';
    } else if (lat > 28 && lat < 32 && lng > 76 && lng < 78) {
      return 'Delhi NCR';
    } else if (lat > 12 && lat < 18 && lng > 77 && lng < 79) {
      return 'Bengaluru, Karnataka';
    } else {
      return 'Location Detected';
    }
  }

  // Get weather data (Simulated for demo)
  static Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return {
      'temperature': 20 + _random.nextInt(15),
      'humidity': 50 + _random.nextInt(40),
      'condition': ['Sunny', 'Cloudy', 'Rainy', 'Clear'][_random.nextInt(4)],
      'windSpeed': 5 + _random.nextInt(20),
    };
  }

  // Get air quality (Simulated for demo)
  static Future<Map<String, dynamic>> getAirQuality(double lat, double lon) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final aqi = 50 + _random.nextInt(150);
    return {
      'aqi': aqi,
      'level': aqi < 50 ? 'Good' : aqi < 100 ? 'Moderate' : 'Poor',
      'pm25': 10 + _random.nextInt(40),
      'pm10': 20 + _random.nextInt(60),
    };
  }

  // Get traffic data (Simulated for demo)
  static Future<Map<String, dynamic>> getTraffic(double lat, double lon) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final hour = DateTime.now().hour;
    final isRushHour = (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19);
    final baseTraffic = isRushHour ? 70 : 30;

    return {
      'congestion': baseTraffic + _random.nextInt(20),
      'flow': _random.nextDouble() * 50 + 20,
      'incidents': _random.nextInt(3),
    };
  }
}

// Local Storage Service (Free)
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save user preferences
  Future<void> setUserPreference(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getUserPreference(String key) {
    return _prefs.getString(key);
  }

  // Save notification settings
  Future<void> setNotificationEnabled(bool enabled) async {
    await _prefs.setBool('notifications_enabled', enabled);
  }

  bool isNotificationEnabled() {
    return _prefs.getBool('notifications_enabled') ?? true;
  }

  // Save favorite areas
  Future<void> addFavoriteArea(String areaId) async {
    List<String> favorites = _prefs.getStringList('favorites') ?? [];
    if (!favorites.contains(areaId)) {
      favorites.add(areaId);
      await _prefs.setStringList('favorites', favorites);
    }
  }

  Future<void> removeFavoriteArea(String areaId) async {
    List<String> favorites = _prefs.getStringList('favorites') ?? [];
    favorites.remove(areaId);
    await _prefs.setStringList('favorites', favorites);
  }

  List<String> getFavoriteAreas() {
    return _prefs.getStringList('favorites') ?? [];
  }

  // Save last known location
  Future<void> saveLastLocation(double lat, double lng) async {
    await _prefs.setString('last_lat', lat.toString());
    await _prefs.setString('last_lng', lng.toString());
  }

  Position? getLastLocation() {
    final lat = _prefs.getString('last_lat');
    final lng = _prefs.getString('last_lng');
    if (lat != null && lng != null) {
      return Position(
        latitude: double.parse(lat),
        longitude: double.parse(lng),
        timestamp: DateTime.now(),
      );
    }
    return null;
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _prefs.clear();
  }
}