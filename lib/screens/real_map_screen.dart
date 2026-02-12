import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../widgets/city_chart.dart';
import 'details_screen.dart';
import '../services/api_service.dart' hide Position;

class RealMapScreen extends StatefulWidget {
  const RealMapScreen({super.key});

  @override
  State<RealMapScreen> createState() => _RealMapScreenState();
}

class _RealMapScreenState extends State<RealMapScreen> {
  late final WebViewController _controller;
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = true;
  bool _showAreaList = true;
  CityArea? _selectedArea;
  bool _isWebViewReady = false;

  final Set<String> _processedMarkers = {};

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _getCurrentLocation();
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;

    // Don't access Theme.of() here - move to didChangeDependencies
    params = const PlatformWebViewControllerCreationParams();

    _controller = WebViewController.fromPlatformCreationParams(params);

    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView loading: $progress%');
          },
          onPageStarted: (String url) {
            debugPrint('Page started: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished: $url');
            _addMarkersToMap();
            setState(() {
              _isLoading = false;
              _isWebViewReady = true;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            setState(() {
              _isLoading = false;
              _isWebViewReady = false;
            });
          },
        ),
      )
      ..loadHtmlString(_generateMapHtml());
  }

  // Move Theme-dependent code here
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Any Theme.of(context) calls should go here
  }

  String _generateMapHtml() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        <style>
            * { margin: 0; padding: 0; }
            body, html { 
                width: 100%; 
                height: 100%; 
                background: #000;
            }
            #map { 
                width: 100%; 
                height: 100%; 
                background: #0a0a0a;
            }
            .custom-marker {
                background: transparent;
                border: none;
            }
            .leaflet-control-attribution {
                background: rgba(0,0,0,0.7) !important;
                color: #999 !important;
            }
            .leaflet-control-attribution a {
                color: #00BCD4 !important;
            }
            .leaflet-popup-content-wrapper {
                background: #1a1a1a !important;
                color: white !important;
                border-radius: 8px !important;
                border-left: 4px solid #00BCD4 !important;
            }
            .leaflet-popup-tip {
                background: #1a1a1a !important;
            }
            .leaflet-popup-close-button {
                color: white !important;
            }
        </style>
    </head>
    <body>
        <div id="map"></div>
        <script>
            // Initialize map centered on India
            var map = L.map('map').setView([20.5937, 78.9629], 5);
            
            // Use OpenStreetMap tiles
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
                maxZoom: 19,
                minZoom: 4
            }).addTo(map);

            // Add scale control
            L.control.scale({imperial: false, metric: true}).addTo(map);

            // Make map available to Flutter
            window.map = map;
            window.markers = [];
            
            // Handler for Flutter communication
            window.flutter_inappwebview = {
                callHandler: function(name, args) {
                    if (window._flutter_inappwebview && window._flutter_inappwebview.callHandler) {
                        window._flutter_inappwebview.callHandler(name, args);
                    }
                }
            };
        </script>
    </body>
    </html>
    ''';
  }

  Future<void> _addMarkersToMap() async {
    if (cityAreas.isEmpty) return;

    await Future.delayed(const Duration(milliseconds: 500));

    for (final area in cityAreas) {
      if (_processedMarkers.contains(area.id)) continue;

      final color = _getMarkerColor(area.stressScore);
      final popupHtml = _generatePopupHtml(area);

      final js = '''
        var marker = L.marker([${area.latitude}, ${area.longitude}], {
          icon: L.divIcon({
            className: 'custom-marker',
            html: '<div style="background: $color; width: 20px; height: 20px; border-radius: 50%; border: 2px solid white; box-shadow: 0 0 15px $color;"></div>',
            iconSize: [24, 24],
            popupAnchor: [0, -12]
          })
        }).addTo(window.map);
        
        marker.bindPopup(`$popupHtml`);
        
        marker.on('click', function(e) {
          if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('selectArea', '${area.id}');
          }
        });
        
        window.markers.push(marker);
      ''';

      await _controller.runJavaScript(js);
      _processedMarkers.add(area.id);
    }
  }

  String _getMarkerColor(double score) {
    if (score < 30) return '#00B894';
    if (score < 45) return '#00CEC9';
    if (score < 60) return '#FDCB6E';
    if (score < 75) return '#E17055';
    return '#D63031';
  }

  Color _getColorFromScore(double score) {
    if (score < 30) return const Color(0xFF00B894);
    if (score < 45) return const Color(0xFF00CEC9);
    if (score < 60) return const Color(0xFFFDCB6E);
    if (score < 75) return const Color(0xFFE17055);
    return const Color(0xFFD63031);
  }

  String _generatePopupHtml(CityArea area) {
    final color = _getMarkerColor(area.stressScore);
    return '''
      <div style="background: #1a1a1a; color: white; padding: 12px; border-radius: 8px; min-width: 200px;">
        <h3 style="margin: 0 0 8px 0; color: white; font-size: 16px;">${area.name}</h3>
        <div style="margin-bottom: 8px;">
          <span style="background: $color; padding: 4px 8px; border-radius: 12px; font-size: 12px; color: white;">${area.healthStatus}</span>
          <span style="margin-left: 8px; font-weight: bold; color: white;">Score: ${area.stressScore.toStringAsFixed(1)}</span>
        </div>
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 8px; color: white;">
          <div><span style="color: #999;">Traffic:</span> ${area.traffic.toInt()}%</div>
          <div><span style="color: #999;">Pollution:</span> ${area.pollution.toInt()}%</div>
          <div><span style="color: #999;">Noise:</span> ${area.noise.toInt()} dB</div>
          <div><span style="color: #999;">Crowd:</span> ${area.crowd.toInt()}%</div>
        </div>
        <button onclick="window.flutter_inappwebview.callHandler('selectArea', '${area.id}')" 
                style="background: $color; color: white; border: none; padding: 8px 16px; border-radius: 4px; width: 100%; cursor: pointer; font-weight: bold;">
          View Details
        </button>
      </div>
    ''';
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }

      final address = await FreeAPIService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _currentAddress = address;
        });
      }

      _centerMap(position.latitude, position.longitude);
      _addUserMarker(position.latitude, position.longitude);

    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _centerMap(double lat, double lng) async {
    if (!_isWebViewReady) {
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    final js = '''
      if (window.map) {
        window.map.setView([$lat, $lng], 13);
      }
    ''';
    await _controller.runJavaScript(js);
  }

  Future<void> _addUserMarker(double lat, double lng) async {
    if (!_isWebViewReady) return;

    final js = '''
      if (window.map) {
        // Remove existing user marker if any
        if (window.userMarker) {
          window.map.removeLayer(window.userMarker);
        }
        
        var userMarker = L.marker([$lat, $lng], {
          icon: L.divIcon({
            className: 'custom-marker',
            html: '<div style="position: relative;">' +
                  '<div style="background: #2196F3; width: 16px; height: 16px; border-radius: 50%; border: 3px solid white; box-shadow: 0 0 20px #2196F3; position: relative; z-index: 2;"></div>' +
                  '<div style="position: absolute; top: -8px; left: -8px; width: 32px; height: 32px; border-radius: 50%; background: rgba(33, 150, 243, 0.2); animation: pulse 2s infinite; z-index: 1;"></div>' +
                  '</div>',
            iconSize: [32, 32],
            popupAnchor: [0, -16]
          })
        }).addTo(window.map);
        
        userMarker.bindPopup('<div style="background: #1a1a1a; color: white; padding: 12px; border-radius: 8px;"><strong style="color: #2196F3;">Your Location</strong><br>${_currentAddress ?? 'Current Location'}</div>');
        
        window.userMarker = userMarker;
      }
    ''';
    await _controller.runJavaScript(js);
  }

  void _selectArea(String areaId) {
    try {
      final area = cityAreas.firstWhere((a) => a.id == areaId);
      if (mounted) {
        setState(() {
          _selectedArea = area;
          _showAreaList = false;
        });
      }
    } catch (e) {
      debugPrint('Error selecting area: $e');
    }
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
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.cyan),
            onPressed: () {
              if (_currentPosition != null) {
                _centerMap(_currentPosition!.latitude, _currentPosition!.longitude);
              } else {
                _getCurrentLocation();
              }
            },
          ),
          IconButton(
            icon: Icon(
              _showAreaList ? Icons.layers : Icons.layers_outlined,
              color: Colors.cyan,
            ),
            onPressed: () {
              setState(() {
                _showAreaList = !_showAreaList;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Real Map View
          if (!_isLoading && _isWebViewReady)
            WebViewWidget(controller: _controller)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.cyan),
            ),

          // Location Banner
          if (_currentAddress != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.cyan, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentAddress!,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Legend
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LEGEND',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ..._buildLegendItems(),
                ],
              ),
            ),
          ),

          // Area Details Panel
          if (_selectedArea != null)
            Positioned(
              top: 80,
              right: 20,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getColorFromScore(_selectedArea!.stressScore).withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedArea!.name,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () => setState(() => _selectedArea = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getColorFromScore(_selectedArea!.stressScore),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedArea!.healthStatus,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Stress Score', '${_selectedArea!.stressScore.toStringAsFixed(1)}'),
                    _buildDetailRow('Traffic', '${_selectedArea!.traffic.toInt()}%'),
                    _buildDetailRow('Pollution', '${_selectedArea!.pollution.toInt()}%'),
                    _buildDetailRow('Noise', '${_selectedArea!.noise.toInt()} dB'),
                    _buildDetailRow('Crowd', '${_selectedArea!.crowd.toInt()}%'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsScreen(area: _selectedArea!),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getColorFromScore(_selectedArea!.stressScore),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('VIEW DETAILS'),
                    ),
                  ],
                ),
              ),
            ),

          // Area List Toggle
          if (_showAreaList)
            Positioned(
              top: 80,
              left: 20,
              child: Container(
                width: 250,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.location_city, color: Colors.cyan, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'CITY AREAS',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                            onPressed: () => setState(() => _showAreaList = false),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.grey, height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: cityAreas.length,
                        itemBuilder: (context, index) {
                          final area = cityAreas[index];
                          return ListTile(
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getColorFromScore(area.stressScore),
                              ),
                            ),
                            title: Text(
                              area.name,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            trailing: Text(
                              area.stressScore.toStringAsFixed(0),
                              style: TextStyle(
                                color: _getColorFromScore(area.stressScore),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedArea = area;
                              });
                              _centerMap(area.latitude, area.longitude);
                            },
                          );
                        },
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

  List<Widget> _buildLegendItems() {
    final items = [
      {'color': const Color(0xFF00B894), 'label': 'Excellent (0-29)'},
      {'color': const Color(0xFF00CEC9), 'label': 'Good (30-44)'},
      {'color': const Color(0xFFFDCB6E), 'label': 'Moderate (45-59)'},
      {'color': const Color(0xFFE17055), 'label': 'Poor (60-74)'},
      {'color': const Color(0xFFD63031), 'label': 'Critical (75-100)'},
      {'color': const Color(0xFF2196F3), 'label': 'Your Location'},
    ];

    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item['color'] as Color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item['label']! as String,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}