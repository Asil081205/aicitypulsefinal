import 'dart:async';
import 'dart:math';
import 'package:ai_city_pulse/screens/real_map_screen.dart';
import 'package:ai_city_pulse/screens/ai_prediction_screen.dart';
import 'package:ai_city_pulse/screens/analytics_dashboard.dart'; // ✅ ADD THIS IMPORT
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../widgets/live_city_card.dart';
import 'mobile_scanner_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../widgets/custom_chart.dart';
import '../widgets/city_chart.dart';
import 'map_screen.dart';
import 'details_screen.dart';
import 'settings_screen.dart';
import '../services/api_service.dart';
import '../services/real_government_api_service.dart';
import '../services/live_data_service.dart';
import '../widgets/live_data_dashboard.dart';
import '../services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  // ============== ADD TAB CONTROLLER ==============
  late TabController _tabController;

  // ============== CONTROLLERS & STREAMS ==============
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<Map<String, dynamic>>? _iotSubscription;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final RealGovernmentAPIService _realApiService = RealGovernmentAPIService();

  // ============== DATA MODELS ==============
  Map<String, dynamic> _realTimeData = {};
  Map<String, dynamic> _analytics = {};
  List<CityArea> _filteredAreas = [];

  // ============== UI STATE ==============
  bool _isLoading = true;
  bool _isRefreshing = false;
  double _cityScore = 54.9;
  String _selectedFilter = 'All';
  int _notificationCount = 0;

  // ============== LOCATION DATA ==============
  String? _currentLocation;
  Position? _currentPosition;

  // ============== SERVICES ==============
  final StorageService _storageService = StorageService();

  // ============== LIFECYCLE METHODS ==============
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeAnimations();
    _tabController = TabController(length: 2, vsync: this);
    _initializeApp();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        debugPrint('⚠️ Force loading complete after timeout');
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _iotSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  // ============== ✅ CLEAN INITIALIZATION ==============
  Future<void> _initializeApp() async {
    try {
      await _storageService.init();
      await _realApiService.init();
      await _checkLocationPermission();
    } catch (e) {
      debugPrint('❌ Service init error: $e');
    }

    _initializeData();
    _startIoTStream();
    _getCurrentLocation();
  }

  // ============== ADD LOCATION PERMISSION CHECK ==============
  Future<void> _checkLocationPermission() async {
    try {
      var status = await Permission.location.status;
      if (!status.isGranted) {
        await Permission.location.request();
      }
    } catch (e) {
      debugPrint('❌ Location permission error: $e');
    }
  }

  void _initializeData() {
    if (cityAreas.isEmpty) {
      debugPrint('⚠️ cityAreas is empty, using default data');
      setState(() {
        _cityScore = 54.9;
        _analytics = {
          'trend': 0.0,
          'hotspots': [],
          'prediction': 54.9,
          'healthDistribution': {
            'Excellent': 20,
            'Good': 30,
            'Moderate': 25,
            'Poor': 15,
            'Critical': 10,
          }
        };
        _filteredAreas = [];
        _isLoading = false;
      });
      return;
    }

    try {
      double overallScore = 0;
      final scores = cityAreas.map((a) => a.stressScore);
      overallScore = scores.reduce((a, b) => a + b) / scores.length;

      setState(() {
        _cityScore = double.parse(overallScore.toStringAsFixed(1));
        _analytics = CityAnalytics.analyzeTrends(cityAreas);
        _filteredAreas = cityAreas;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error calculating city score: $e');
      setState(() {
        _cityScore = 54.9;
        _isLoading = false;
      });
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutCubic,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _startIoTStream() {
    try {
      _iotSubscription = IoTDataStream.getRealTimeData().listen((data) {
        if (mounted) {
          setState(() {
            _realTimeData = data;
          });
        }
      }, onError: (error) {
        debugPrint('❌ IoT Stream error: $error');
        if (mounted) {
          setState(() {
            _realTimeData = {
              'temperature': 28,
              'humidity': 65,
              'airQuality': 85,
              'trafficFlow': 70,
              'energyConsumption': 75,
              'noiseLevel': 55,
              'publicTransportLoad': 60,
            };
          });
        }
      });
    } catch (e) {
      debugPrint('❌ IoT Stream init error: $e');
    }
  }

  // ============== LOCATION METHODS ==============
  Future<void> _getCurrentLocation() async {
    try {
      final position = await FreeAPIService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
        });

        final address = await FreeAPIService.getAddressFromLatLng(
            position.latitude,
            position.longitude
        );

        if (mounted) {
          setState(() {
            _currentLocation = address;
          });
        }

        await _storageService.saveLastLocation(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('❌ Location error: $e');
    }
  }

  // ============== DATA METHODS ==============
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    _initializeData();
    await _getCurrentLocation();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  // ============== COLOR UTILITIES ==============
  Color _getScoreColor(double score) {
    if (score < 30) return const Color(0xFF00B894);
    if (score < 45) return const Color(0xFF00CEC9);
    if (score < 60) return const Color(0xFFFDCB6E);
    if (score < 75) return const Color(0xFFE17055);
    return const Color(0xFFD63031);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Excellent': return const Color(0xFF00B894);
      case 'Good': return const Color(0xFF00CEC9);
      case 'Moderate': return const Color(0xFFFDCB6E);
      case 'Poor': return const Color(0xFFE17055);
      case 'Critical': return const Color(0xFFD63031);
      default: return Colors.grey;
    }
  }

  Color _getValueColor(double value) {
    if (value < 40) return Colors.green;
    if (value < 70) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(double score) {
    if (score < 30) return Icons.verified;
    if (score < 45) return Icons.check_circle;
    if (score < 60) return Icons.warning;
    if (score < 75) return Icons.error_outline;
    return Icons.dangerous;
  }

  // ============== QR SCANNER METHODS ==============
  void _scanQRCode() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MobileScannerScreen(),
        ),
      );
    } else {
      _showCameraPermissionDialog();
    }
  }

  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Camera Permission Required',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Camera permission is needed to scan QR codes for city area information.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _simulateQRScan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'QR Scanner',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_scanner, color: Colors.cyan, size: 80),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Scanning...\n\nSimulated QR Scanner',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showScannedArea();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text('Simulate Scan'),
          ),
        ],
      ),
    );
  }

  void _showScannedArea() {
    if (cityAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No city areas available')),
      );
      return;
    }

    final random = Random();
    final area = cityAreas[random.nextInt(cityAreas.length)];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            Icon(Icons.qr_code, color: _getScoreColor(area.stressScore)),
            const SizedBox(width: 10),
            Text(
              'Scanned: ${area.name}',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getScoreColor(area.stressScore).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Health Status: ${area.healthStatus}',
                    style: TextStyle(color: _getScoreColor(area.stressScore)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stress Score: ${area.stressScore.toStringAsFixed(1)}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ],
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
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailsScreen(area: area)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  // ============== THEME AWARE COLORS ==============
  Color _getBackgroundColor() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    if (themeService.isAmoledMode) {
      return Colors.black;
    }
    return Theme.of(context).scaffoldBackgroundColor;
  }

  Color _getCardColor() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    if (themeService.isAmoledMode) {
      return const Color(0xFF0A0A0A);
    }
    return Theme.of(context).cardColor;
  }

  // ============== UI BUILD METHODS ==============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoading() : _buildContent(),
      floatingActionButton: _buildFloatingActionButton(),
      drawer: _buildDrawer(),
    );
  }

// ============== ✅ FIXED APPBAR - NO DEBUG ICON ==============
  AppBar _buildAppBar() {
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.cyan, size: 22),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Open navigation menu',
        ),
      ),

      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.precision_manufacturing, color: Colors.cyan, size: 22),
              const SizedBox(width: 6),
              const Text(
                'AI CITY PULSE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          if (_currentLocation != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.cyan, size: 12),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _currentLocation!.split(',').first,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),

      toolbarHeight: _currentLocation != null ? 88 : 64,
      backgroundColor: _getCardColor(),
      elevation: 0,
      titleSpacing: 0,

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          height: 52,
          padding: const EdgeInsets.only(top: 6),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.cyan,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.cyan,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(
                icon: Icon(Icons.dashboard, size: 20),
                text: 'DASHBOARD',
              ),
              Tab(
                icon: Icon(Icons.sensors, size: 20),
                text: 'LIVE DATA',
              ),
            ],
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),

      systemOverlayStyle: SystemUiOverlayStyle.light,

      actions: [
        Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return IconButton(
              icon: Icon(
                themeService.isAmoledMode
                    ? Icons.brightness_2
                    : themeService.isDarkMode
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: Colors.cyan,
                size: 20,
              ),
              onPressed: () {
                final nextIndex = (themeService.currentTheme.index + 1) % AppTheme.values.length;
                themeService.setTheme(AppTheme.values[nextIndex]);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Theme: ${themeService.currentTheme.name}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.cyan,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 20,
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: Colors.cyan, size: 20),
          onPressed: _scanQRCode,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 20,
        ),
      ],
    );
  }

  // 🔴 REMOVED: _debugAPIs() method completely

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(_getScoreColor(_cityScore)),
          ),
          const SizedBox(height: 20),
          Text(
            'Analyzing City Health...',
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 8),
          Text(
            'Using default data',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          if (_isRefreshing)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'Refreshing data...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: DASHBOARD
              RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refreshData,
                backgroundColor: _getCardColor(),
                color: Colors.cyan,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildCityPulseCard(),
                          const SizedBox(height: 20),
                          _buildQuickStats(),
                          const SizedBox(height: 20),
                          _buildRealTimeDashboard(),
                          const SizedBox(height: 20),
                          _buildLiveCityGrid(),
                          const SizedBox(height: 20),
                          _buildPredictiveInsights(),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              // TAB 2: LIVE DATA
              LiveDataDashboard(
                latitude: _currentPosition?.latitude ?? 13.0827,
                longitude: _currentPosition?.longitude ?? 80.2707,
                city: _currentLocation?.split(',').first ?? 'Chennai',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============== Live City Grid ==============
  Widget _buildLiveCityGrid() {
    if (cityAreas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No city areas available',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'LIVE CITY STATUS',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'REAL-TIME',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Live AQI, Traffic & Noise data from CPCB, WAQI & TomTom',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: cityAreas.length,
          itemBuilder: (context, index) {
            final area = cityAreas[index];
            return LiveCityCard(
              cityName: area.name,
              latitude: area.latitude,
              longitude: area.longitude,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailsScreen(area: area),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ============== Dashboard Item ==============
  Widget _buildDashboardItem(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.cyan, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityPulseCard() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: _getCardColor(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CITY HEALTH INDEX',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _cityScore.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: _getScoreColor(_cityScore),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              _getScoreColor(_cityScore).withOpacity(0.3),
                              _getScoreColor(_cityScore).withOpacity(0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.1, 0.5, 1.0],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getScoreColor(_cityScore),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _getScoreIcon(_cityScore),
                            size: 40,
                            color: _getScoreColor(_cityScore),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _cityScore / 100,
                    backgroundColor: Colors.grey[800],
                    color: _getScoreColor(_cityScore),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatChip('Trend', '${_analytics['trend'] > 0 ? '+' : ''}${_analytics['trend']?.toStringAsFixed(1) ?? '0.0'}%'),
                      _buildStatChip('Hotspots', '${_analytics['hotspots']?.length ?? 0}'),
                      _buildStatChip('Prediction', '${_analytics['prediction']?.toStringAsFixed(1) ?? '54.9'}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Air Quality', '${_realTimeData['airQuality']?.toInt() ?? 85}', 'AQI', Icons.air)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Traffic', '${_realTimeData['trafficFlow']?.toInt() ?? 70}%', 'Flow', Icons.traffic)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Energy', '${_realTimeData['energyConsumption']?.toInt() ?? 75}%', 'Load', Icons.bolt)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon) {
    return Card(
      color: _getCardColor(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.cyan, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeDashboard() {
    return Card(
      color: _getCardColor(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sensors, color: Colors.cyan, size: 20),
                const SizedBox(width: 8),
                Text(
                  'REAL-TIME DASHBOARD',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Live',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 4)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildDashboardItem('Temperature', '${_realTimeData['temperature']?.toInt() ?? 28}°C', Icons.thermostat),
                _buildDashboardItem('Humidity', '${_realTimeData['humidity']?.toInt() ?? 65}%', Icons.water_drop),
                _buildDashboardItem('Noise', '${_realTimeData['noiseLevel']?.toInt() ?? 55} dB', Icons.volume_up),
                _buildDashboardItem('Transport', '${_realTimeData['publicTransportLoad']?.toInt() ?? 60}%', Icons.directions_bus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============== Original static area cards for filter ==============
  Widget _buildStaticAreaGrid() {
    if (cityAreas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No city areas available',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CITY AREAS',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, color: Colors.cyan),
              onSelected: (value) {
                setState(() {
                  _selectedFilter = value;
                  _filteredAreas = value == 'All'
                      ? cityAreas
                      : cityAreas.where((a) => a.healthStatus == value).toList();
                });
              },
              itemBuilder: (context) => ['All', 'Excellent', 'Good', 'Moderate', 'Poor', 'Critical']
                  .map((status) => PopupMenuItem(value: status, child: Text(status)))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemCount: _filteredAreas.isEmpty ? cityAreas.length : _filteredAreas.length,
          itemBuilder: (context, index) {
            final area = _filteredAreas.isEmpty ? cityAreas[index] : _filteredAreas[index];
            return _buildAreaCard(area);
          },
        ),
      ],
    );
  }

  Widget _buildAreaCard(CityArea area) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DetailsScreen(area: area)),
      ),
      child: Card(
        color: _getScoreColor(area.stressScore).withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _getScoreColor(area.stressScore).withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      area.name,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getScoreColor(area.stressScore),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      area.stressScore.toStringAsFixed(0),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                area.healthStatus,
                style: TextStyle(
                  color: _getScoreColor(area.stressScore),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: area.stressScore / 100,
                backgroundColor: Colors.grey[800],
                color: _getScoreColor(area.stressScore),
                minHeight: 4,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${area.latitude.toStringAsFixed(2)}, ${area.longitude.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictiveInsights() {
    final recommendations = CityAnalytics.generateRecommendations(cityAreas, _cityScore);

    return Card(
      color: _getCardColor(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.cyan),
                const SizedBox(width: 8),
                Text(
                  'AI PREDICTIONS',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AIPredictionScreen(
                      city: cityAreas.isNotEmpty ? cityAreas[0] : cityAreas[0],
                    )),
                  ),
                  child: const Text('VIEW ALL', style: TextStyle(color: Colors.cyan)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.take(3).map((rec) => _buildInsightItem(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights, color: Colors.cyan, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RealMapScreen()),
      ),
      icon: const Icon(Icons.map),
      label: const Text('View Map'),
      backgroundColor: Colors.cyan,
      foregroundColor: Colors.black,
    );
  }

  // ============== ✅ FIXED DRAWER - NO DUPLICATES, CLEAR NAMES ==============
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _getCardColor(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: _getCardColor()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.precision_manufacturing, size: 40, color: Colors.cyan),
                const SizedBox(height: 10),
                Text(
                  'AI City Pulse',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v2.0.0',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.cyan),
            title: Text(
              'Dashboard',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.sensors, color: Colors.cyan),
            title: Text(
              'Live Data',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.cyan),
            title: Text(
              'Settings',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette, color: Colors.cyan),
            title: Text(
              'Theme',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          // ✅ ANALYTICS DASHBOARD - NEW DASHBOARD
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.cyan),
            title: Text(
              'Analytics Dashboard',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsDashboard(),
                ),
              );
            },
          ),
          // ✅ AI PREDICTIONS - PER CITY PREDICTIONS
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.cyan),
            title: Text(
              'City AI Predictions',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            onTap: () {
              Navigator.pop(context);
              if (cityAreas.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No city data available for predictions'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AIPredictionScreen(
                    city: cityAreas[0],
                  ),
                ),
              );
            },
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.cyan),
            title: Text(
              'Help & Support',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            onTap: () => _showHelpDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.cyan),
            title: Text(
              'About',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            onTap: () => _showAboutDialog(),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getCardColor(),
        title: Text(
          'Help & Support',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📘 How to use:',
              style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '• Tap on any area card to view details',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            Text(
              '• Use filter to sort areas by health status',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            Text(
              '• Click "View Map" to see city heatmap',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            Text(
              '• Swipe left/right to switch between Dashboard and Live Data',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            Text(
              '• QR Scanner simulates scanning areas',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 16),
            Text(
              '📧 Contact: support@aicitypulse.com',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getCardColor(),
        title: Text(
          'About',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.precision_manufacturing, size: 60, color: Colors.cyan),
            const SizedBox(height: 16),
            Text(
              'AI City Pulse',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 2.0.0',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              'Advanced Urban Health Monitoring System\n'
                  'Built with Flutter - Student Project',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '© 2024 AI City Pulse',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }
}