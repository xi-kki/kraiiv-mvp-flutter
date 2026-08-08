import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'food_recognition_service.dart';

/// Client for Klia's AI chat endpoint on the model API.
///
/// The chat screen tries this first for real AI answers; when the API is
/// unreachable or not configured, it falls back to the local keyword
/// replies so Klia always answers.
class KliaChatService {
  /// Same base URL as the food scanner — one API deployment, two endpoints.
  static String get apiBase => FoodRecognitionService.apiBase;

  static bool get apiEnabled => apiBase.isNotEmpty;

  /// Longer than the scanner timeout: chat is conversational, not a scan.
  static const Duration _timeout = Duration(seconds: 8);

  /// Asks the model API for Klia's reply. Returns null when the API is
  /// unavailable or not configured, so the caller can use its fallback.
  static Future<String?> ask(
    List<Map<String, String>> history,
    String question,
  ) async {
    if (!apiEnabled) return null;
    try {
      final resp = await http
          .post(
            Uri.parse('$apiBase/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'messages': [
                ...history,
                {'role': 'user', 'content': question},
              ],
            }),
          )
          .timeout(_timeout);
      if (resp.statusCode != 200) {
        debugPrint('Chat API returned ${resp.statusCode}');
        return null;
      }
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final reply = json['reply'] as String?;
      return reply?.trim();
    } catch (e) {
      debugPrint('Klia AI unavailable ($e) — using keyword answers');
      return null;
    }
  }
}
