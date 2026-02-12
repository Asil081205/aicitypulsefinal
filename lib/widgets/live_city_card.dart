import 'dart:async';
import 'package:flutter/material.dart';
import '../services/live_data_service.dart';

class LiveCityCard extends StatefulWidget {
  final String cityName;
  final double latitude;
  final double longitude;
  final VoidCallback onTap;

  const LiveCityCard({
    super.key,
    required this.cityName,
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  @override
  State<LiveCityCard> createState() => _LiveCityCardState();
}

class _LiveCityCardState extends State<LiveCityCard> {
  final LiveDataService _liveService = LiveDataService();
  Map<String, dynamic> _cityStatus = {};
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchLiveData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _fetchLiveData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveData() async {
    final status = await _liveService.getCompleteCityStatus(
      widget.cityName,
      widget.latitude,
      widget.longitude,
    );

    if (mounted) {
      setState(() {
        _cityStatus = status;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _getStressColor(_getStressScore()).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Reduced from 16 to 12
          child: _isLoading
              ? const Center(
            child: SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(
                color: Colors.cyan,
                strokeWidth: 2,
              ),
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Important!
            children: [
              // City Name & Live Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.cityName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _hasLiveData() ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _hasLiveData() ? 'LIVE' : 'CACHED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Metrics Row - 3 columns
              Row(
                children: [
                  Expanded(
                    child: _buildMetric(
                      'AQI',
                      '${_getAQIValue()}',
                      _getAQIColor(),
                      Icons.air,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildMetric(
                      'TRAFFIC',
                      '${_getTrafficValue()}%',
                      Colors.cyan,
                      Icons.traffic,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildMetric(
                      'NOISE',
                      '${_getNoiseValue()}dB',
                      _getNoiseColor(),
                      Icons.volume_up,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Stress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HEALTH',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getHealthStatus(),
                        style: TextStyle(
                          color: _getStressColor(_getStressScore()),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  LinearProgressIndicator(
                    value: _getStressScore() / 100,
                    backgroundColor: Colors.grey[800],
                    color: _getStressColor(_getStressScore()),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Timestamp
              Text(
                _formatTime(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 8,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ============== GETTERS WITH SAFE TYPE CONVERSION ==============
  double _getAQIValue() {
    final aqi = _cityStatus['aqi']?['aqi'];
    if (aqi == null) return 85;
    if (aqi is int) return aqi.toDouble();
    if (aqi is double) return aqi;
    return 85;
  }

  double _getTrafficValue() {
    final traffic = _cityStatus['traffic']?['congestion'];
    if (traffic == null) return 70;
    if (traffic is int) return traffic.toDouble();
    if (traffic is double) return traffic;
    return 70;
  }

  double _getNoiseValue() {
    final noise = _cityStatus['noise']?['noise'];
    if (noise == null) return 75;
    if (noise is int) return noise.toDouble();
    if (noise is double) return noise;
    return 75;
  }

  double _getStressScore() {
    final stress = _cityStatus['stress'];
    if (stress == null) return 70;
    if (stress is int) return stress.toDouble();
    if (stress is double) return stress;
    if (stress is String) return double.tryParse(stress) ?? 70;
    return 70;
  }

  String _getHealthStatus() {
    return _cityStatus['health_status'] ?? 'Moderate';
  }

  bool _hasLiveData() {
    return _cityStatus['hasLiveData'] == true;
  }

  Color _getAQIColor() {
    final aqi = _getAQIValue();
    if (aqi < 50) return Colors.green;
    if (aqi < 100) return Colors.yellow;
    if (aqi < 150) return Colors.orange;
    if (aqi < 200) return Colors.red;
    return Colors.purple;
  }

  Color _getNoiseColor() {
    final noise = _getNoiseValue();
    if (noise < 40) return Colors.green;
    if (noise < 55) return Colors.yellow;
    if (noise < 70) return Colors.orange;
    if (noise < 85) return Colors.red;
    return Colors.purple;
  }

  Color _getStressColor(double score) {
    if (score < 30) return Colors.green;
    if (score < 45) return Colors.lightGreen;
    if (score < 60) return Colors.yellow;
    if (score < 75) return Colors.orange;
    return Colors.red;
  }

  String _formatTime() {
    final timestamp = _cityStatus['timestamp'];
    if (timestamp == null) return '';
    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds}s ago';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }
}