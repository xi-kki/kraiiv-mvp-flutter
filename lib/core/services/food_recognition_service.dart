import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Result of an AI food detection call.
class DetectedFood {
  final String name;
  final double confidence;
  final int? calories;
  final double? protein;
  final int? healthScore;
  final String? insight;
  final bool local;

  const DetectedFood({
    required this.name,
    required this.confidence,
    this.calories,
    this.protein,
    this.healthScore,
    this.insight,
    this.local = false,
  });

  factory DetectedFood.fromJson(Map<String, dynamic> json) {
    return DetectedFood(
      name: json['food'] as String? ?? 'Your Meal',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      calories: json['calories'] as int?,
      protein: (json['protein'] as num?)?.toDouble(),
      healthScore: json['healthScore'] as int?,
      insight: json['insight'] as String?,
      local: json['local'] == true,
    );
  }
}

/// Client for the Kraiiv Food Recognition API (model-api/).
///
/// The scanner tries this service first for real AI identification of
/// Nigerian food; when the API is unreachable it falls back to the local
/// keyword matcher so the app stays fully functional offline.
class FoodRecognitionService {
  /// Build-time override. Set with:
  ///   flutter build web --dart-define=KRAIIV_API_URL=https://api.example.com
  static const String _configuredApi = String.fromEnvironment(
    'KRAIIV_API_URL',
    defaultValue: '',
  );

  /// Base URL of the model API. Debug builds default to the local dev API
  /// so `flutter run` works out of the box. Release builds only call the
  /// API when [KRAIIV_API_URL] was explicitly configured at build time —
  /// otherwise the scanner uses the offline matcher and no photo ever
  /// leaves the device.
  static String get apiBase {
    if (_configuredApi.isNotEmpty) return _configuredApi;
    return kReleaseMode ? '' : 'http://localhost:8000';
  }

  /// True when the model API should be attempted at all.
  static bool get apiEnabled => apiBase.isNotEmpty;

  /// Short timeout so the scanner falls back to the local matcher quickly
  /// when the model API is unreachable.
  static const Duration _timeout = Duration(seconds: 4);

  /// Sends a photo to the model API and returns detected foods,
  /// or an empty list when the API is unavailable or not configured.
  static Future<List<DetectedFood>> detect(XFile photo) async {
    if (!apiEnabled) return [];
    try {
      final bytes = await photo.readAsBytes();
      final uri = Uri.parse('$apiBase/detect');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'meal.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      final streamed = await request.send().timeout(_timeout);
      if (streamed.statusCode != 200) {
        debugPrint('Food API returned ${streamed.statusCode}');
        return [];
      }
      final body = await streamed.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final detected = json['detected'] as List<dynamic>? ?? [];
      return detected
          .map((e) => DetectedFood.fromJson(e as Map<String, dynamic>))
          .where((d) => d.confidence >= 0.3)
          .toList();
    } catch (e) {
      debugPrint('Food recognition unavailable ($e) — using local matcher');
      return [];
    }
  }
}
