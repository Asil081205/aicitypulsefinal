import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/city_chart.dart'; // ADD THIS IMPORT
import 'details_screen.dart';
import '../services/api_service.dart' hide Position;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  double _scale = 1.0;
  CityArea? _selectedArea;
  bool _showHeatmap = true;

  // Using Geolocator's Position class
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionPermanentlyDeniedDialog();
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Get address from coordinates
      final address = await FreeAPIService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentAddress = address.split(',').take(2).join(',');
        _isLoadingLocation = false;
      });

    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Location Services Disabled',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Please enable location services to see your current location on the map.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Location Permission Denied',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Location permission is needed to show your current position on the map.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Location Permission Permanently Denied',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Location permission is permanently denied. Please enable it in app settings.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps(CityArea area) async {
    final googleUrl = 'https://www.google.com/maps/dir/?api=1&destination=${area.latitude},${area.longitude}';
    final appleUrl = 'https://maps.apple.com/?daddr=${area.latitude},${area.longitude}';

    try {
      if (await canLaunchUrl(Uri.parse(googleUrl))) {
        await launchUrl(Uri.parse(googleUrl));
      } else if (await canLaunchUrl(Uri.parse(appleUrl))) {
        await launchUrl(Uri.parse(appleUrl));
      } else {
        _showCoordinatesDialog(area);
      }
    } catch (e) {
      _showCoordinatesDialog(area);
    }
  }

  void _showCoordinatesDialog(CityArea area) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Coordinates', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                '${area.latitude.toStringAsFixed(6)}, ${area.longitude.toStringAsFixed(6)}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: '${area.latitude}, ${area.longitude}',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coordinates copied to clipboard'),
                  backgroundColor: Colors.cyan,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaMarker(CityArea area) {
    final size = _calculateMarkerSize(area.stressScore);
    final color = _getScoreColor(area.stressScore);

    return Positioned(
      left: area.longitude * 7 + 300,
      top: area.latitude * 7 + 200,
      child: GestureDetector(
        onTap: () => _selectArea(area),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.7),
              border: Border.all(
                color: Colors.white,
                width: _selectedArea?.id == area.id ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                area.stressScore.toStringAsFixed(0),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      color: Colors.black.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LEGEND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildLegendItem('Excellent (0-29)', Colors.green),
            _buildLegendItem('Good (30-44)', const Color(0xFF00CEC9)),
            _buildLegendItem('Moderate (45-59)', Colors.yellow),
            _buildLegendItem('Poor (60-74)', Colors.orange),
            _buildLegendItem('Critical (75-100)', Colors.red),
            _buildLegendItem('Your Location', Colors.blue),
            const SizedBox(height: 12),
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),
            const Text('LAYERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Checkbox(
                  value: _showHeatmap,
                  onChanged: (val) => setState(() => _showHeatmap = val ?? false),
                  fillColor: MaterialStateProperty.all(Colors.cyan),
                ),
                const Text('Heatmap', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAreaDetails() {
    return Positioned(
      top: 20,
      right: 20,
      child: Card(
        color: Colors.black.withOpacity(0.9),
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedArea!.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _selectedArea = null),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildDetailRow('Health Status', _selectedArea!.healthStatus),
              _buildDetailRow('Stress Score', _selectedArea!.stressScore.toStringAsFixed(1)),
              _buildDetailRow('Traffic', '${_selectedArea!.traffic.toInt()}%'),
              _buildDetailRow('Pollution', '${_selectedArea!.pollution.toInt()}%'),
              _buildDetailRow('Last Updated', _formatTime(_selectedArea!.lastUpdated)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openInMaps(_selectedArea!),
                      icon: const Icon(Icons.directions),
                      label: const Text('NAVIGATE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getScoreColor(_selectedArea!.stressScore),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareLocation(_selectedArea!),
                      icon: const Icon(Icons.share),
                      label: const Text('SHARE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToDetails(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                  child: const Text('VIEW DETAILED ANALYSIS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Card(
      color: Colors.black.withOpacity(0.8),
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => setState(() => _scale = (_scale * 1.2).clamp(0.5, 3.0)),
          ),
          Text('${_scale.toStringAsFixed(1)}x', style: const TextStyle(color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: () => setState(() => _scale = (_scale * 0.8).clamp(0.5, 3.0)),
          ),
        ],
      ),
    );
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Centered on your location'),
          backgroundColor: Colors.cyan,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      _getCurrentLocation();
    }
  }

  void _selectArea(CityArea area) {
    setState(() {
      _selectedArea = area;
    });
  }

  void _navigateToDetails() {
    if (_selectedArea != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsScreen(area: _selectedArea!),
        ),
      );
    }
  }

  void _shareLocation(CityArea area) {
    final message = 'Check out ${area.name}\n'
        'Health Status: ${area.healthStatus}\n'
        'Stress Score: ${area.stressScore.toStringAsFixed(1)}\n'
        'Location: https://www.google.com/maps?q=${area.latitude},${area.longitude}';

    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location information copied to clipboard'),
        backgroundColor: Colors.cyan,
      ),
    );
  }

  double _calculateMarkerSize(double score) {
    final baseSize = 40.0;
    final multiplier = (score / 100) * 1.5 + 0.5;
    return baseSize * multiplier * (_scale.clamp(0.5, 3.0) / 2);
  }

  Color _getScoreColor(double score) {
    if (score < 30) return Colors.green;
    if (score < 45) return const Color(0xFF00CEC9);
    if (score < 60) return Colors.yellow;
    if (score < 75) return Colors.orange;
    return Colors.red;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('City Health Map'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.my_location, color: Colors.cyan),
                onPressed: _getCurrentLocation,
              ),
              if (_isLoadingLocation)
                const Positioned(
                  right: 8,
                  top: 8,
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.cyan),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              _showHeatmap ? Icons.layers : Icons.layers_outlined,
              color: Colors.cyan,
            ),
            onPressed: () => setState(() => _showHeatmap = !_showHeatmap),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.black, Color(0xFF0A0A0A)],
              ),
            ),
          ),
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            onInteractionUpdate: (details) {
              setState(() {
                _scale = details.scale ?? 1.0;
              });
            },
            child: Center(
              child: Container(
                width: 800,
                height: 600,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue[900]!, Colors.black],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (_showHeatmap)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: RadialGradient(
                            colors: [
                              Colors.red.withOpacity(0.3),
                              Colors.orange.withOpacity(0.2),
                              Colors.green.withOpacity(0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.1, 0.4, 0.7, 1.0],
                          ),
                        ),
                      ),
                    if (_currentPosition != null)
                      Positioned(
                        left: _currentPosition!.longitude * 7 + 300,
                        top: _currentPosition!.latitude * 7 + 200,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ...cityAreas.map((area) => _buildAreaMarker(area)).toList(),
                    CustomPaint(
                      painter: _InfrastructurePainter(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: _buildLegend(),
          ),
          if (_selectedArea != null) _buildAreaDetails(),
          Positioned(
            right: 20,
            bottom: 20,
            child: _buildZoomControls(),
          ),
          if (_currentAddress != null)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.cyan, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _currentAddress!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnCurrentLocation,
        backgroundColor: Colors.cyan,
        child: const Icon(Icons.gps_fixed),
      ),
    );
  }
}

class _InfrastructurePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    final roadPoints = [
      Offset(100, 300), Offset(700, 300),
      Offset(400, 100), Offset(400, 500),
      Offset(200, 200), Offset(600, 400),
      Offset(200, 400), Offset(600, 200),
    ];

    for (int i = 0; i < roadPoints.length; i += 2) {
      canvas.drawLine(roadPoints[i], roadPoints[i + 1], paint);
    }

    final buildingPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final buildings = [
      Rect.fromCenter(center: const Offset(300, 200), width: 40, height: 60),
      Rect.fromCenter(center: const Offset(500, 250), width: 50, height: 80),
      Rect.fromCenter(center: const Offset(200, 350), width: 60, height: 70),
      Rect.fromCenter(center: const Offset(600, 150), width: 45, height: 65),
    ];

    for (final building in buildings) {
      canvas.drawRect(building, buildingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}