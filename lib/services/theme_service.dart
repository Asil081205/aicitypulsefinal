import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  dark,      // Dark theme
  light,     // Light theme
  amoled,    // AMOLED Black (true black, saves battery)
  system,    // Follow system theme
}

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  late AppTheme _currentTheme;

  ThemeService() {
    _loadTheme();
  }

  AppTheme get currentTheme => _currentTheme;

  bool get isDarkMode => _currentTheme == AppTheme.dark || _currentTheme == AppTheme.amoled;

  bool get isAmoledMode => _currentTheme == AppTheme.amoled;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _currentTheme = AppTheme.values[themeIndex];
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
    notifyListeners();
  }

  // Get theme data based on current selection
  ThemeData getThemeData(Brightness systemBrightness) {
    switch (_currentTheme) {
      case AppTheme.light:
        return _buildLightTheme();
      case AppTheme.dark:
        return _buildDarkTheme();
      case AppTheme.amoled:
        return _buildAmoledTheme();
      case AppTheme.system:
        return systemBrightness == Brightness.dark
            ? _buildDarkTheme()
            : _buildLightTheme();
    }
  }

  // ============== LIGHT THEME ==============
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.cyan,
      primarySwatch: Colors.cyan,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,

      colorScheme: const ColorScheme.light(
        primary: Colors.cyan,
        secondary: Colors.cyanAccent,
        background: Colors.white,
        surface: Colors.white,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onBackground: Colors.black87,
        onSurface: Colors.black87,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.cyan),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 1,
      ),
    );
  }

  // ============== DARK THEME ==============
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.cyan,
      primarySwatch: Colors.cyan,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),

      colorScheme: const ColorScheme.dark(
        primary: Colors.cyan,
        secondary: Colors.cyanAccent,
        background: Color(0xFF121212),
        surface: Color(0xFF1E1E1E),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.cyan),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.grey[800]!,
        thickness: 1,
      ),
    );
  }

  // ============== AMOLED BLACK THEME ==============
  ThemeData _buildAmoledTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.cyan,
      primarySwatch: Colors.cyan,
      scaffoldBackgroundColor: Colors.black,
      cardColor: const Color(0xFF0A0A0A),

      colorScheme: const ColorScheme.dark(
        primary: Colors.cyan,
        secondary: Colors.cyanAccent,
        background: Colors.black,
        surface: Color(0xFF0A0A0A),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.cyan),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF1A1A1A),
        thickness: 1,
      ),
    );
  }
}