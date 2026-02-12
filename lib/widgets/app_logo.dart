import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            'AI City Pulse',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ],
    );
  }
}