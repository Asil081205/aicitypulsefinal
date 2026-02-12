import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/real_government_api_service.dart';

class LiveDataDashboard extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String city;

  const LiveDataDashboard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.city,
  });

  @override
  State<LiveDataDashboard> createState() => _LiveDataDashboardState();
}

class _LiveDataDashboardState extends State<LiveDataDashboard> {
  // ============== USE REAL API SERVICE ==============
  final RealGovernmentAPIService _apiService = RealGovernmentAPIService();

  // Live data streams
  StreamSubscription? _weatherSubscription;
  StreamSubscription? _airQualitySubscription;
  StreamSubscription? _trafficSubscription;
  StreamSubscription? _accelerometerSubscription;

  // Real-time data
  Map<String, dynamic> _weatherData = {};
  Map<String, dynamic> _airQualityData = {};
  List<Map<String, dynamic>> _nearbyPlaces = [];
  List<Map<String, dynamic>> _trafficIncidents = [];
  Map<String, double> _noiseLevels = {};

  // Sensor data
  double _accelerometerX = 0.0;
  double _accelerometerY = 0.0;
  double _accelerometerZ = 0.0;

  bool _isLoading = true;
  bool _sensorsSupported = true;

  @override
  void initState() {
    super.initState();
    _initializeApi();
    _initializeLiveData();
    _initializeSensors();
  }

  @override
  void dispose() {
    _weatherSubscription?.cancel();
    _airQualitySubscription?.cancel();
    _trafficSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  // ============== INITIALIZATION ==============
  Future<void> _initializeApi() async {
    await _apiService.init();
  }

  Future<void> _initializeLiveData() async {
    // Initial data fetch
    await _fetchAllData();

    // Set up real-time updates
    _weatherSubscription = Stream.periodic(
      const Duration(minutes: 5),
          (_) => _fetchWeatherData(),
    ).listen((_) {});

    _airQualitySubscription = Stream.periodic(
      const Duration(minutes: 30),
          (_) => _fetchAirQuality(),
    ).listen((_) {});

    _trafficSubscription = Stream.periodic(
      const Duration(minutes: 5),
          (_) => _fetchTrafficData(),
    ).listen((_) {});
  }

  void _initializeSensors() {
    try {
      _accelerometerSubscription = accelerometerEvents.listen(
            (AccelerometerEvent event) {
          if (mounted) {
            setState(() {
              _accelerometerX = event.x;
              _accelerometerY = event.y;
              _accelerometerZ = event.z;
            });
          }
        },
        onError: (error) {
          debugPrint('Accelerometer error: $error');
          setState(() => _sensorsSupported = false);
        },
      );
    } catch (e) {
      debugPrint('Sensors initialization error: $e');
      setState(() => _sensorsSupported = false);
    }
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _fetchWeatherData(),
      _fetchAirQuality(),
      _fetchNearbyPlaces(),
      _fetchTrafficData(),
      _fetchNoiseLevels(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ============== API METHODS ==============
  Future<void> _fetchWeatherData() async {
    try {
      final data = await _apiService.fetchOpenWeatherMap(
        widget.latitude,
        widget.longitude,
      );
      if (mounted) {
        setState(() => _weatherData = data);
      }
    } catch (e) {
      debugPrint('Weather fetch error: $e');
    }
  }

  Future<void> _fetchAirQuality() async {
    try {
      final data = await _apiService.fetchCPCBAirQuality(widget.city);
      if (mounted) {
        setState(() => _airQualityData = data);
      }
    } catch (e) {
      debugPrint('Air quality fetch error: $e');
    }
  }

  Future<void> _fetchNearbyPlaces() async {
    try {
      final places = await _apiService.fetchGooglePlaces(
        widget.latitude,
        widget.longitude,
        'restaurant|cafe|shopping_mall',
      );
      if (mounted) {
        setState(() => _nearbyPlaces = places);
      }
    } catch (e) {
      debugPrint('Places fetch error: $e');
    }
  }

  Future<void> _fetchTrafficData() async {
    try {
      final incidents = await _apiService.fetchTomTomTraffic(
        widget.latitude,
        widget.longitude,
      );
      if (mounted) {
        setState(() => _trafficIncidents = incidents);
      }
    } catch (e) {
      debugPrint('Traffic fetch error: $e');
    }
  }

  Future<void> _fetchNoiseLevels() async {
    // Simulated noise levels (real noise API requires hardware)
    final hour = DateTime.now().hour;
    double baseNoise;

    if (hour >= 8 && hour <= 20) {
      baseNoise = 55 + Random().nextInt(20).toDouble();
    } else {
      baseNoise = 40 + Random().nextInt(15).toDouble();
    }

    if (mounted) {
      setState(() {
        _noiseLevels = {
          'current_db': baseNoise,
          'peak_db': baseNoise + 12,
          'min_db': baseNoise - 8,
          'average_db': baseNoise,
        };
      });
    }
  }

  // ============== BUILD METHODS ==============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? _buildLoadingIndicator()
          : _buildLiveDashboard(),
    );
  }

  Widget _buildLiveDashboard() {
    return CustomScrollView(
      slivers: [
        // LIVE STATUS BAR
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyan.withOpacity(0.2),
                  Colors.black,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'LIVE STREAMING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      TimeOfDay.now().format(context),
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if (_sensorsSupported) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildSensorCard(
                        'Accelerometer',
                        'X: ${_accelerometerX.toStringAsFixed(1)}\nY: ${_accelerometerY.toStringAsFixed(1)}\nZ: ${_accelerometerZ.toStringAsFixed(1)}',
                        Icons.sensors,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // WEATHER CARD
        SliverToBoxAdapter(
          child: _buildWeatherCard(),
        ),

        // AIR QUALITY & NOISE
        SliverToBoxAdapter(
          child: _buildEnvironmentCard(),
        ),

        // REAL-TIME CHART
        SliverToBoxAdapter(
          child: _buildLiveChart(),
        ),

        // NEARBY PLACES
        SliverToBoxAdapter(
          child: _buildNearbyPlaces(),
        ),

        // TRAFFIC INCIDENTS
        SliverToBoxAdapter(
          child: _buildTrafficIncidents(),
        ),
      ],
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[900]!,
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENT WEATHER',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _weatherData['temperature'] != null
                            ? '${_weatherData['temperature'].toStringAsFixed(1)}°C'
                            : '--°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _weatherData['weather_condition'] ?? '--',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _weatherData['feels_like'] != null
                                ? 'Feels like ${_weatherData['feels_like'].toStringAsFixed(1)}°C'
                                : '--',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getWeatherIcon(_weatherData['weather_condition'] ?? ''),
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherMetric(
                'Humidity',
                _weatherData['humidity'] != null
                    ? '${_weatherData['humidity'].toStringAsFixed(0)}%'
                    : '--%',
                Icons.water_drop,
              ),
              _buildWeatherMetric(
                'Wind',
                _weatherData['wind_speed'] != null
                    ? '${_weatherData['wind_speed'].toStringAsFixed(1)} km/h'
                    : '-- km/h',
                Icons.air,
              ),
              _buildWeatherMetric(
                'UV Index',
                _weatherData['uv_index']?.toStringAsFixed(1) ?? '--',
                Icons.wb_sunny,
              ),
              _buildWeatherMetric(
                'Pressure',
                _weatherData['pressure'] != null
                    ? '${_weatherData['pressure'].toStringAsFixed(0)} hPa'
                    : '-- hPa',
                Icons.speed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildGaugeCard(
              'AIR QUALITY',
              _airQualityData['aqi']?.toString() ?? '--',
              'AQI',
              _getAQIColor(_airQualityData['aqi'] ?? 85),
              Icons.air,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildGaugeCard(
              'NOISE LEVEL',
              _noiseLevels['current_db']?.toStringAsFixed(0) ?? '--',
              'dB',
              _getNoiseColor(_noiseLevels['current_db'] ?? 0),
              Icons.volume_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChart() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '24-HOUR TREND',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[800]!,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey[800]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final hours = ['00', '04', '08', '12', '16', '20'];
                        final index = value.toInt() % hours.length;
                        return Text(
                          hours[index],
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[800]!),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateSpots(),
                    isCurved: true,
                    color: Colors.cyan,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.cyan.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyPlaces() {
    if (_nearbyPlaces.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE CROWD DATA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._nearbyPlaces.take(3).map((place) => _buildPlaceCard(place)),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getCrowdColor(place['crowd_factor'] ?? 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${((place['crowd_factor'] ?? 0.5) * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place['name'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      place['rating']?.toStringAsFixed(1) ?? '0.0',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      color: place['is_open'] == true ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      place['is_open'] == true ? 'Open' : 'Closed',
                      style: TextStyle(
                        color: place['is_open'] == true ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficIncidents() {
    if (_trafficIncidents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRAFFIC INCIDENTS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._trafficIncidents.map((incident) => _buildIncidentCard(incident)),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    Color severityColor;
    switch (incident['severity']) {
      case 'major':
      case 'severe':
        severityColor = Colors.red;
        break;
      case 'moderate':
        severityColor = Colors.orange;
        break;
      case 'minor':
        severityColor = Colors.yellow;
        break;
      default:
        severityColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: severityColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getTrafficIcon(incident['type'] ?? 'incident'),
            color: severityColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident['description'] ?? 'Traffic incident',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _getLocationText(incident),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              incident['severity']?.toUpperCase() ?? 'UNKNOWN',
              style: TextStyle(
                color: severityColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============== UTILITY BUILDERS ==============
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.cyan.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.cyan,
                strokeWidth: 4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'FETCHING REAL-TIME DATA...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CPCB • OpenWeatherMap • Google • TomTom',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyan, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildGaugeCard(
      String title,
      String value,
      String unit,
      Color color,
      IconData icon,
      ) {
    double parsedValue = 0;
    try {
      parsedValue = double.tryParse(value) ?? 50;
    } catch (e) {
      parsedValue = 50;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: parsedValue / 200,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeWidth: 8,
                ),
              ),
              Column(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.cyan, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== UTILITY METHODS ==============
  List<FlSpot> _generateSpots() {
    final spots = <FlSpot>[];
    final random = Random();

    for (int i = 0; i < 24; i++) {
      // Generate realistic city stress pattern
      double baseValue = 50;
      double morningRush = (i >= 7 && i <= 9) ? 25 : 0;
      double eveningRush = (i >= 17 && i <= 19) ? 30 : 0;
      double nightTime = (i >= 22 || i <= 5) ? -15 : 0;
      double randomVariation = sin(i * 0.7) * 8 + cos(i * 0.4) * 5;

      double value = baseValue + morningRush + eveningRush + nightTime + randomVariation;
      value = value.clamp(20, 95);

      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }

  String _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      default:
        return '☀️';
    }
  }

  IconData _getTrafficIcon(String type) {
    switch (type) {
      case 'accident':
        return Icons.car_crash;
      case 'road_works':
      case 'construction':
        return Icons.construction;
      case 'road_closed':
        return Icons.block;
      case 'jam':
        return Icons.traffic;
      default:
        return Icons.warning;
    }
  }

  String _getLocationText(Map<String, dynamic> incident) {
    if (incident['from'] != null && incident['to'] != null) {
      return '${incident['from']} → ${incident['to']}';
    }
    return 'Reported ${_getTimeAgo(incident['timestamp'])}';
  }

  Color _getAQIColor(int aqi) {
    if (aqi < 50) return Colors.green;
    if (aqi < 100) return Colors.lightGreen;
    if (aqi < 150) return Colors.yellow;
    if (aqi < 200) return Colors.orange;
    if (aqi < 300) return Colors.red;
    if (aqi < 400) return Colors.purple;
    return const Color(0xFF7E0023); // Maroon
  }

  Color _getNoiseColor(double db) {
    if (db < 40) return Colors.green;
    if (db < 55) return Colors.lightGreen;
    if (db < 70) return Colors.yellow;
    if (db < 85) return Colors.orange;
    return Colors.red;
  }

  Color _getCrowdColor(double factor) {
    if (factor < 0.3) return Colors.green;
    if (factor < 0.6) return Colors.yellow;
    if (factor < 0.8) return Colors.orange;
    return Colors.red;
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return 'just now';
    try {
      final time = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(time);

      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${diff.inDays ~/ 7} weeks ago';
    } catch (e) {
      return 'recently';
    }
  }
}