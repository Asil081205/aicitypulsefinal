import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/city_chart.dart';
import 'ai_prediction_screen.dart';


class DetailsScreen extends StatelessWidget {
  final CityArea area;
  final Random _random = Random();

  DetailsScreen({super.key, required this.area});

  List<Map<String, dynamic>> _generateHistoricalData() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final value = area.stressScore * (0.9 + _random.nextDouble() * 0.2);
      data.add({'date': date, 'value': value});
    }

    return data;
  }

  // ============== NAVIGATION METHODS ==============
  Future<void> _navigateToLocation(BuildContext context, CityArea area) async {
    final googleUrl = 'https://www.google.com/maps/dir/?api=1&destination=${area.latitude},${area.longitude}';
    final appleUrl = 'https://maps.apple.com/?daddr=${area.latitude},${area.longitude}';

    try {
      if (await canLaunchUrl(Uri.parse(googleUrl))) {
        await launchUrl(Uri.parse(googleUrl));
      } else if (await canLaunchUrl(Uri.parse(appleUrl))) {
        await launchUrl(Uri.parse(appleUrl));
      } else {
        _showCoordinatesDialog(context, area);
      }
    } catch (e) {
      _showCoordinatesDialog(context, area);
    }
  }

  void _showCoordinatesDialog(BuildContext context, CityArea area) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: '${area.latitude}, ${area.longitude}',
              ));
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text('Coordinates copied to clipboard'),
                  backgroundColor: Colors.cyan,
                ),
              );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getScoreColor(area.stressScore).withOpacity(0.3),
                      Colors.black,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        area.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getScoreColor(area.stressScore),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Score: ${area.stressScore.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHealthCard(),
                const SizedBox(height: 20),
                _buildMetricsCard(),
                const SizedBox(height: 20),
                _buildChartCard(),
                const SizedBox(height: 20),
                _buildRecommendationsCard(),
                const SizedBox(height: 20),
                // ✅ ADDED: AI Predictions Button
                _buildAIPredictionButton(context),
                const SizedBox(height: 20),
                _buildLocationCard(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: AI Prediction Button Widget
  Widget _buildAIPredictionButton(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI POWERED PREDICTIONS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Get 24-hour stress forecasts powered by TensorFlow Lite AI',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIPredictionScreen(city: area),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome, color: Colors.black),
              label: const Text(
                'VIEW AI PREDICTIONS',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HEALTH STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getScoreColor(area.stressScore),
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            area.healthStatus,
                            style: TextStyle(
                              color: _getScoreColor(area.stressScore),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last Updated: ${_formatTime(area.lastUpdated)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatItem('Traffic', area.traffic, Icons.traffic),
                      _buildStatItem('Pollution', area.pollution, Icons.air),
                      _buildStatItem('Noise', area.noise, Icons.volume_up),
                      _buildStatItem('Crowd', area.crowd, Icons.people),
                      _buildStatItem('Power', area.power, Icons.bolt),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DETAILED METRICS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...area.subMetrics.entries.map((entry) => _buildMetricRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final historicalData = _generateHistoricalData();

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TREND ANALYSIS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: _LineChartPainter(
                  data: historicalData,
                  lineColor: _getScoreColor(area.stressScore),
                  maxValue: historicalData.map((d) => d['value'] as double).reduce((a, b) => a > b ? a : b) * 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI RECOMMENDATIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._generateRecommendations().map((rec) => _buildRecommendationItem(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LOCATION DATA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: _getScoreColor(area.stressScore)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coordinates',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    Text(
                      '${area.latitude.toStringAsFixed(4)}, ${area.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _navigateToLocation(context, area),
                  icon: const Icon(Icons.directions),
                  label: const Text('NAVIGATE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getScoreColor(area.stressScore),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyan, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getValueColor(value),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${value.toInt()}%',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String metric, double value) {
    final metricName = metric.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(metricName, style: const TextStyle(color: Colors.white)),
              Text('${value.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey[800],
            color: _getScoreColor(area.stressScore),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_forward, color: Colors.cyan, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(recommendation, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score < 30) return const Color(0xFF00B894);
    if (score < 45) return const Color(0xFF00CEC9);
    if (score < 60) return const Color(0xFFFDCB6E);
    if (score < 75) return const Color(0xFFE17055);
    return const Color(0xFFD63031);
  }

  Color _getValueColor(double value) {
    if (value < 40) return Colors.green;
    if (value < 70) return Colors.orange;
    return Colors.red;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  List<String> _generateRecommendations() {
    if (area.stressScore > 70) {
      return [
        'Avoid this area until conditions improve',
        'Use N95 masks if travel is necessary',
        'Report any infrastructure issues immediately',
        'Consider remote work options',
      ];
    } else if (area.stressScore > 50) {
      return [
        'Plan travel during off-peak hours',
        'Monitor air quality updates',
        'Use public transportation alternatives',
        'Reduce energy consumption',
      ];
    } else {
      return [
        'Safe for all activities',
        'Ideal for outdoor events',
        'Sustainable practices in effect',
        'Minimal restrictions required',
      ];
    }
  }
}

// Custom painter for line chart
class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color lineColor;
  final double maxValue;

  _LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final double width = size.width;
    final double height = size.height;
    final double stepX = width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double y = height - (data[i]['value'] / maxValue * height * 0.8) - 20;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw points
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
    }

    canvas.drawPath(path, paint);

    // Draw X-axis labels
    final textStyle = TextStyle(color: Colors.grey[400], fontSize: 10);
    for (int i = 0; i < data.length; i++) {
      final date = data[i]['date'] as DateTime;
      final text = '${date.day}/${date.month}';
      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(i * stepX - textPainter.width / 2, height - 15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}