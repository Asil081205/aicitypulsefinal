import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'services/theme_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'AI City Pulse',
          debugShowCheckedModeBanner: false,
          theme: themeService.getThemeData(
            WidgetsBinding.instance.window.platformBrightness,
          ),
          home: const WelcomeScreen(),
        );
      },
    );
  }
}