import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../widgets/city_chart.dart';

// ===========================================
// AI PREDICTION SERVICE - STATISTICAL VERSION
// No TensorFlow Lite dependencies - WORKS IMMEDIATELY!
// ===========================================

class AIPredictionService {
  static final AIPredictionService _instance = AIPredictionService._internal();
  factory AIPredictionService() => _instance;
  AIPredictionService._internal();

  // ============== LOAD MODEL (FAKE) ==============
  Future<void> loadModel() async {
    debugPrint('🤖 Using statistical prediction engine');
    return Future.value();
  }

  // ============== PREDICT CITY STRESS ==============
  Future<Map<String, dynamic>> predictCityStress(
      CityArea city,
      List<Map<String, dynamic>> historicalData,
      ) async {
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 500));

    final predictions = _generatePredictions(city);
    return _processPredictions(predictions, city);
  }

  // ============== GENERATE PREDICTIONS ==============
  List<double> _generatePredictions(CityArea city) {
    final predictions = <double>[];
    final random = Random();
    final baseScore = city.stressScore;

    for (int i = 0; i < 24; i++) {
      final hour = (DateTime.now().hour + i) % 24;

      // Realistic city patterns
      double morningRush = (hour >= 7 && hour <= 9) ? 15.0 : 0.0;
      double eveningRush = (hour >= 17 && hour <= 19) ? 20.0 : 0.0;
      double nightTime = (hour >= 22 || hour <= 5) ? -10.0 : 0.0;
      double lunchTime = (hour >= 12 && hour <= 14) ? 8.0 : 0.0;

      // Trend over 24 hours
      double trend = i * 0.2;

      // Random variation
      double variation = random.nextDouble() * 6 - 3;

      double prediction = baseScore + morningRush + eveningRush + nightTime + lunchTime + trend + variation;
      predictions.add(prediction.clamp(0, 100));
    }

    return predictions;
  }

  // ============== PROCESS PREDICTIONS ==============
  Map<String, dynamic> _processPredictions(
      List<double> predictions,
      CityArea city,
      ) {
    final now = DateTime.now();
    final hourlyPredictions = <Map<String, dynamic>>[];

    for (int i = 0; i < predictions.length; i++) {
      final hour = now.add(Duration(hours: i));
      final score = predictions[i];

      hourlyPredictions.add({
        'hour': hour.hour,
        'timestamp': hour.toIso8601String(),
        'score': double.parse(score.toStringAsFixed(1)),
        'status': _getStressStatus(score),
        'confidence': _calculateConfidence(i),
      });
    }

    // Calculate statistics
    double avg = predictions.reduce((a, b) => a + b) / predictions.length;
    double max = predictions.reduce((a, b) => a > b ? a : b);
    double min = predictions.reduce((a, b) => a < b ? a : b);

    // Find critical hours
    List<int> criticalHours = [];
    for (int i = 0; i < predictions.length; i++) {
      if (predictions[i] > 75) {
        criticalHours.add(now.add(Duration(hours: i)).hour);
      }
    }

    return {
      'city_id': city.id,
      'city_name': city.name,
      'predictions': hourlyPredictions,
      'average_score': double.parse(avg.toStringAsFixed(1)),
      'max_score': double.parse(max.toStringAsFixed(1)),
      'min_score': double.parse(min.toStringAsFixed(1)),
      'critical_hours': criticalHours,
      'peak_hour': _findPeakHour(hourlyPredictions),
      'trend': _calculateTrend(predictions),
      'confidence_level': _getOverallConfidence(predictions),
      'generated_at': DateTime.now().toIso8601String(),
      'model_used': 'Statistical AI',
    };
  }

  // ============== UTILITY METHODS ==============

  String _getStressStatus(double score) {
    if (score < 30) return 'Excellent';
    if (score < 45) return 'Good';
    if (score < 60) return 'Moderate';
    if (score < 75) return 'Poor';
    return 'Critical';
  }

  double _calculateConfidence(int hourIndex) {
    // Confidence decreases as we predict further into the future
    return max(60.0, 95.0 - hourIndex * 1.5);
  }

  String _calculateTrend(List<double> predictions) {
    if (predictions.isEmpty) return 'stable';
    double first = predictions.first;
    double last = predictions.last;
    double diff = last - first;
    if (diff > 5) return 'rising';
    if (diff < -5) return 'falling';
    return 'stable';
  }

  String _getOverallConfidence(List<double> predictions) {
    double total = 0;
    for (int i = 0; i < predictions.length; i++) {
      total += _calculateConfidence(i);
    }
    double avg = total / predictions.length;
    if (avg > 85) return 'high';
    if (avg > 70) return 'medium';
    return 'low';
  }

  int _findPeakHour(List<Map<String, dynamic>> predictions) {
    if (predictions.isEmpty) return 12;
    var peak = predictions.reduce((a, b) =>
    a['score'] > b['score'] ? a : b
    );
    return peak['hour'];
  }

  // ============== DISPOSE ==============
  void dispose() {
    debugPrint('🔒 AI Prediction Service closed');
  }
}