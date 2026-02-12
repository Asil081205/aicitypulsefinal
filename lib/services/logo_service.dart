import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LogoService {
  static const String _defaultLogoPath = 'assets/logo/app_logo.png';

  // Get logo image provider
  static ImageProvider getLogo({String? customPath}) {
    try {
      return AssetImage(customPath ?? _defaultLogoPath);
    } catch (e) {
      // Fallback to icon if asset not found
      return const AssetImage('assets/logo/city pulse.png');
    }
  }

  // Build logo widget with fallback
  static Widget buildLogo({
    double size = 100,
    BoxFit fit = BoxFit.contain,
    String? path,
  }) {
    try {
      return Image.asset(
        path ?? _defaultLogoPath,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon logo
          return Image.asset(
            'assets/logo/city pulse.png',
            width: size,
            height: size,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              // Final fallback - gradient circle with icon
              return Container(
                width: size,
                height: size,
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
                      blurRadius: size * 0.2,
                      spreadRadius: size * 0.05,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.precision_manufacturing,
                    size: size * 0.5,
                    color: Colors.white,
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      // Return fallback widget
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            colors: [
              Color(0xFF00BCD4),
              Color(0xFF006064),
            ],
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.precision_manufacturing,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
      );
    }
  }
}