import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_service.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoRefresh = true;
  String _refreshInterval = '30';
  List<String> _favoriteAreas = [];

  final List<String> _intervals = ['15', '30', '60', '300'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _autoRefresh = prefs.getBool('auto_refresh') ?? true;
      _refreshInterval = prefs.getString('refresh_interval') ?? '30';
      _favoriteAreas = prefs.getStringList('favorites') ?? [];
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) prefs.setBool(key, value);
    if (value is String) prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final isAmoled = themeService.isAmoledMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ============== THEME SECTION ==============
          _buildSection(
            title: 'THEME',
            icon: isAmoled
                ? Icons.brightness_2
                : (isDark ? Icons.dark_mode : Icons.light_mode),
            color: Colors.cyan,
            children: [
              RadioListTile<AppTheme>(
                title: const Text('Light Mode'),
                subtitle: const Text('Clean, bright interface'),
                value: AppTheme.light,
                groupValue: themeService.currentTheme,
                activeColor: Colors.cyan,
                onChanged: (value) => themeService.setTheme(value!),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.light_mode, color: Colors.amber),
                ),
              ),
              RadioListTile<AppTheme>(
                title: const Text('Dark Mode'),
                subtitle: const Text('Easy on the eyes'),
                value: AppTheme.dark,
                groupValue: themeService.currentTheme,
                activeColor: Colors.cyan,
                onChanged: (value) => themeService.setTheme(value!),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.dark_mode, color: Colors.deepPurple),
                ),
              ),
              RadioListTile<AppTheme>(
                title: const Text('AMOLED Black'),
                subtitle: const Text('True black - saves battery on OLED screens'),
                value: AppTheme.amoled,
                groupValue: themeService.currentTheme,
                activeColor: Colors.cyan,
                onChanged: (value) => themeService.setTheme(value!),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.brightness_2, color: Colors.cyan),
                ),
              ),
              RadioListTile<AppTheme>(
                title: const Text('System Default'),
                subtitle: const Text('Follow your device theme'),
                value: AppTheme.system,
                groupValue: themeService.currentTheme,
                activeColor: Colors.cyan,
                onChanged: (value) => themeService.setTheme(value!),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.settings_brightness, color: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ============== NOTIFICATIONS SECTION ==============
          _buildSection(
            title: 'NOTIFICATIONS',
            icon: Icons.notifications,
            color: Colors.cyan,
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive alerts for critical areas'),
                value: _notificationsEnabled,
                activeColor: Colors.cyan,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _saveSetting('notifications_enabled', value);
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ============== APP SETTINGS ==============
          _buildSection(
            title: 'APP SETTINGS',
            icon: Icons.settings,
            color: Colors.cyan,
            children: [
              SwitchListTile(
                title: const Text('Auto Refresh'),
                subtitle: const Text('Automatically refresh data'),
                value: _autoRefresh,
                activeColor: Colors.cyan,
                onChanged: (value) {
                  setState(() => _autoRefresh = value);
                  _saveSetting('auto_refresh', value);
                },
              ),
              if (_autoRefresh)
                ListTile(
                  title: const Text('Refresh Interval'),
                  subtitle: Text('$_refreshInterval seconds'),
                  trailing: DropdownButton<String>(
                    value: _refreshInterval,
                    dropdownColor: Theme.of(context).cardColor,
                    items: _intervals.map((interval) {
                      return DropdownMenuItem(
                        value: interval,
                        child: Text('$interval seconds'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _refreshInterval = value);
                        _saveSetting('refresh_interval', value);
                      }
                    },
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ============== FAVORITE AREAS ==============
          if (_favoriteAreas.isNotEmpty)
            _buildSection(
              title: 'FAVORITE AREAS',
              icon: Icons.favorite,
              color: Colors.red,
              children: _favoriteAreas.map((areaId) {
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.cyan),
                  title: Text(areaId),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _favoriteAreas.remove(areaId);
                        _saveSetting('favorites', _favoriteAreas);
                      });
                    },
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 20),

          // ============== ABOUT SECTION - ENHANCED ==============
          _buildAboutSection(),

          const SizedBox(height: 20),

          // ============== AMOLED INFO CARD ==============
          _buildAmoledInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  // ============== ✅ ENHANCED ABOUT SECTION WITH FULL DESCRIPTION ==============
  Widget _buildAboutSection() {
    return Card(
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.cyan, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'ABOUT',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // App Logo and Name
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF00BCD4),
                        Color(0xFF006064),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.precision_manufacturing,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'AI City Pulse',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 2.0.0',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.grey[800]),
          ),

          // ✅ DETAILED DESCRIPTION SECTION
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📱 ABOUT THIS APP',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'AI City Pulse is an advanced urban health monitoring system that provides real-time data on air quality, traffic congestion, and noise pollution across major Indian cities. Powered by AI and machine learning, it helps citizens make informed decisions about their daily activities.',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  '✨ KEY FEATURES',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFeatureItem('🌍', 'Real-time AQI, Traffic & Noise data from CPCB, WAQI & TomTom'),
                _buildFeatureItem('🗺️', 'Live interactive maps with city health heatmaps'),
                _buildFeatureItem('🧠', 'AI-powered 24-hour stress predictions'),
                _buildFeatureItem('📊', 'Historical trends and city comparisons'),
                _buildFeatureItem('🎨', 'AMOLED Black mode for battery saving'),
                _buildFeatureItem('🔔', 'Critical alerts for dangerous pollution levels'),

                const SizedBox(height: 16),

                const Text(
                  '🏙️ SUPPORTED CITIES',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Chennai', 'Bengaluru', 'Mumbai', 'New Delhi',
                    'Pune', 'Hyderabad', 'Kolkata', 'Ahmedabad'
                  ].map((city) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                    ),
                    child: Text(
                      city,
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 12,
                      ),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 16),

                const Text(
                  '🎯 MISSION',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'To empower citizens with real-time environmental data, enabling healthier lifestyle choices and contributing to smarter, more sustainable cities.',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.grey[800]),
          ),

          // Tech Stack
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🛠️ BUILT WITH',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTechChip('Flutter'),
                    _buildTechChip('Dart'),
                    _buildTechChip('TensorFlow Lite'),
                    _buildTechChip('OpenWeatherMap'),
                    _buildTechChip('TomTom Maps'),
                    _buildTechChip('CPCB'),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📧 Contact',
                          style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'support@aicitypulse.com',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '© 2024',
                          style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI City Pulse',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // GitHub Button
                OutlinedButton.icon(
                  onPressed: () async {
                    final url = 'https://github.com/yourusername/ai-city-pulse';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    }
                  },
                  icon: const Icon(Icons.code, size: 18),
                  label: const Text('VIEW ON GITHUB'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyan,
                    side: const BorderSide(color: Colors.cyan),
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildAmoledInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.cyan.withOpacity(0.1)
            : Colors.cyan.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.brightness_2, color: Colors.cyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                'AMOLED Black Mode',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'On OLED screens, true black pixels turn off completely, saving battery life. Perfect for AMOLED displays!',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}