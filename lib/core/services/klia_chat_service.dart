import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'food_recognition_service.dart';

/// Client for Klia's AI nutrition assistant.
///
/// Follows best security practices:
/// - Allows build-time injection via --dart-define=STITCH_API_KEY=...
/// - Calls Gemini/Stitch or model-api when available
/// - Automatically falls back to high-quality local nutrition responses
class KliaChatService {
  static const String _configuredKey = String.fromEnvironment(
    'STITCH_API_KEY',
    defaultValue: '',
  );

  static String get apiBase => FoodRecognitionService.apiBase;
  static bool get apiEnabled => apiBase.isNotEmpty || _configuredKey.isNotEmpty;

  static const Duration _timeout = Duration(seconds: 8);

  /// Asks Gemini/Stitch API or model API for Klia's reply.
  static Future<String?> ask(
    List<Map<String, String>> history,
    String question,
  ) async {
    // 1. Try Google Gemini / Stitch endpoint if key is present
    if (_configuredKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
        );
        final prompt = '''You are Klia, a warm, supportive, and knowledgeable nutrition coach for Kraiiv (a Nigerian mindful eating companion).
Respond concisely in 1-3 sentences. Tone: encouraging, intentional, culturally aware of Nigerian foods and healthy eating habits.

User asks: $question''';

        final resp = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': _configuredKey,
              },
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ],
                'generationConfig': {
                  'maxOutputTokens': 150,
                  'temperature': 0.7,
                }
              }),
            )
            .timeout(_timeout);

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates.first['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts.first['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                return text.trim();
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Gemini/Stitch API error ($e) — falling back');
      }
    }

    // 2. Try model-api backend if configured
    if (apiBase.isNotEmpty) {
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
        if (resp.statusCode == 200) {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          final reply = json['reply'] as String?;
          if (reply != null && reply.trim().isNotEmpty) {
            return reply.trim();
          }
        }
      } catch (e) {
        debugPrint('model-api unavailable ($e)');
      }
    }

    return null;
  }

  /// Convenience method for single question
  static Future<String> reply(String question) async {
    final aiReply = await ask([], question);
    if (aiReply != null && aiReply.isNotEmpty) {
      return aiReply;
    }
    return replySync(question);
  }

  /// Instant offline fallback keyword replies (matches video prototype exactly)
  static String replySync(String question) {
    final q = question.toLowerCase();

    if (q.contains('protein')) {
      return 'Good sources of plant-based protein include beans, lentils, tofu, tempeh, edamame, and quinoa. Animal sources include eggs, fish, poultry, and lean meats.';
    }
    if (q.contains('local') || q.contains('nigerian') || q.contains('market')) {
      return 'Embracing local ingredients like pumpkin leaves (ugwu), plantains, sweet potatoes, and garden eggs gives you peak nutrients while supporting local farmers!';
    }
    if (q.contains('calorie') || q.contains('weight') || q.contains('fat')) {
      return 'Focus on nutrient density over strict calorie counting. Pairing whole grains with healthy proteins and fiber-rich vegetables keeps you satisfied and energized.';
    }
    if (q.contains('water') || q.contains('hydrat')) {
      return 'Aim for 6-8 glasses of clean water daily. Staying hydrated boosts energy, supports digestion, and helps you tune into real hunger cues.';
    }
    if (q.contains('mindful') || q.contains('habit')) {
      return 'Mindful eating begins with a single intentional breath before your meal. Chew slowly, notice the flavors, and stop when you feel comfortably satisfied.';
    }
    if (q.contains('ktc') || q.contains('reward') || q.contains('token')) {
      return 'You earn KTC tokens by logging meals, scanning fresh foods, and completing daily goals. You can redeem them in the Rewards Hub for vouchers and treats!';
    }
    if (q.contains('hello') || q.contains('hi') || q.contains('hey')) {
      return "Hello! I'm Klia, your nutrition assistant. Ask me anything about mindful eating, local recipes, protein, or staying energized today!";
    }

    return 'Eating with intention is about nourishment and joy. Try adding one colorful vegetable to your next plate, and listen to your body’s natural rhythm.';
  }
}
