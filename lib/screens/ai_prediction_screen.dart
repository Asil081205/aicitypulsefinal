import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ai_prediction_service.dart';
import '../widgets/city_chart.dart';

class AIPredictionScreen extends StatefulWidget {
  final CityArea city;

  const AIPredictionScreen({
    super.key,
    required this.city,
  });

  @override
  State<AIPredictionScreen> createState() => _AIPredictionScreenState();
}

class _AIPredictionScreenState extends State<AIPredictionScreen> {
  final AIPredictionService _aiService = AIPredictionService();

  bool _isLoading = true;
  bool _isDisposed = false; // ✅ Add this flag
  Map<String, dynamic> _predictions = {};

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  @override
  void dispose() {
    _isDisposed = true; // ✅ Set flag when disposed
    _aiService.dispose();
    super.dispose();
  }

  Future<void> _initializeAI() async {
    // Load model first
    await _aiService.loadModel();

    // Generate predictions
    await _getPredictions();
  }

  Future<void> _getPredictions() async {
    if (_isDisposed) return; // ✅ Don't proceed if disposed

    setState(() {
      _isLoading = true;
    });

    try {
      final predictions = await _aiService.predictCityStress(
        widget.city,
        [], // Empty historical data for now
      );

      if (!_isDisposed && mounted) { // ✅ Check both flags
        setState(() {
          _predictions = predictions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Prediction error: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'AI Predictions - ${widget.city.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : _buildPredictionScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.cyan.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.cyan,
                strokeWidth: 4,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'GENERATING AI PREDICTIONS...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing patterns for ${widget.city.name}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionScreen() {
    final predictions = _predictions['predictions'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Status Card
          _buildAIStatusCard(),

          const SizedBox(height: 24),

          // Summary Cards
          _buildSummaryCards(),

          const SizedBox(height: 24),

          // Prediction Chart
          if (predictions.isNotEmpty) _buildPredictionChart(predictions),

          const SizedBox(height: 24),

          // Critical Hours
          if (_predictions['critical_hours'] != null &&
              (_predictions['critical_hours'] as List).isNotEmpty)
            _buildCriticalHours(),

          const SizedBox(height: 24),

          // Hourly Predictions List
          if (predictions.isNotEmpty) _buildHourlyPredictions(predictions),
        ],
      ),
    );
  }

  Widget _buildAIStatusCard() {
    final modelUsed = _predictions['model_used'] ?? 'Statistical AI';
    final confidence = _predictions['confidence_level'] ?? 'medium';

    Color confidenceColor;
    IconData confidenceIcon;

    switch (confidence) {
      case 'high':
        confidenceColor = Colors.green;
        confidenceIcon = Icons.verified;
        break;
      case 'medium':
        confidenceColor = Colors.orange;
        confidenceIcon = Icons.auto_awesome;
        break;
      default:
        confidenceColor = Colors.yellow;
        confidenceIcon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan[900]!,
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.cyan,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI PREDICTION ENGINE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Using $modelUsed',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: confidenceColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: confidenceColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  confidenceIcon,
                  color: confidenceColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  confidence.toUpperCase(),
                  style: TextStyle(
                    color: confidenceColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'AVERAGE',
            '${_predictions['average_score'] ?? 0}',
            'score',
            _getScoreColor(_predictions['average_score']?.toDouble() ?? 54.9),
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'PEAK',
            '${_predictions['max_score'] ?? 0}',
            'at ${_predictions['peak_hour'] ?? 0}:00',
            _getScoreColor(_predictions['max_score']?.toDouble() ?? 74.9),
            Icons.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'TREND',
            _predictions['trend'] ?? 'stable',
            _getTrendIcon(_predictions['trend'] ?? 'stable'),
            _getTrendColor(_predictions['trend'] ?? 'stable'),
            Icons.timeline,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label,
      String value,
      String subtitle,
      Color color,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionChart(List<dynamic> predictions) {
    final spots = <FlSpot>[];
    for (int i = 0; i < predictions.length; i++) {
      final score = (predictions[i]['score'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), score));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '24-HOUR PREDICTION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'AI GENERATED',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[800]!,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey[800]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < predictions.length) {
                          final hour = predictions[index]['hour'];
                          return Text(
                            '${hour}:00',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[800]!),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.cyan,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final score = spot.y;
                        return FlDotCirclePainter(
                          radius: 4,
                          color: _getScoreColor(score),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.cyan.withOpacity(0.1),
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

  Widget _buildCriticalHours() {
    final criticalHours = _predictions['critical_hours'] as List<int>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[900]!.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'CRITICAL HOURS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: criticalHours.map((hour) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  '${hour}:00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'High stress levels predicted. Consider avoiding travel during these hours.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyPredictions(List<dynamic> predictions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOURLY BREAKDOWN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: predictions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final prediction = predictions[index];
              final hour = prediction['hour'];
              final score = prediction['score'];
              final status = prediction['status'];
              final confidence = prediction['confidence'];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getScoreColor(score).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${hour}:00',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status,
                            style: TextStyle(
                              color: _getScoreColor(score),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: score / 100,
                            backgroundColor: Colors.grey[800],
                            color: _getScoreColor(score),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Stress Score',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                score.toStringAsFixed(1),
                                style: TextStyle(
                                  color: _getScoreColor(score),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${confidence.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getTrendIcon(String trend) {
    switch (trend) {
      case 'rising': return '↑';
      case 'falling': return '↓';
      default: return '→';
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'rising': return Colors.orange;
      case 'falling': return Colors.green;
      default: return Colors.cyan;
    }
  }

  Color _getScoreColor(double score) {
    if (score < 30) return const Color(0xFF00B894);
    if (score < 45) return const Color(0xFF00CEC9);
    if (score < 60) return const Color(0xFFFDCB6E);
    if (score < 75) return const Color(0xFFE17055);
    return const Color(0xFFD63031);
  }
}