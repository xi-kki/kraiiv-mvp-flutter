import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';

class FoodItem {
  final String id;
  final String name;
  final String category;
  final String feedbackTemplate;
  final int healthScore;
  final List<String> keywords;
  final int calories;
  final double protein;
  final String insight;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.feedbackTemplate,
    required this.healthScore,
    required this.keywords,
    this.calories = 0,
    this.protein = 0,
    this.insight = '',
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      feedbackTemplate: json['feedback_template'],
      healthScore: json['health_score'],
      keywords: List<String>.from(json['keywords']),
      calories: json['calories'] as int? ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      insight: json['insight'] as String? ?? '',
    );
  }

  /// Foods from the Nigerian database count as "local".
  bool get isLocal => int.tryParse(id) != null && int.parse(id) <= 100;
}

class FoodRepository {
  List<FoodItem> _foods = [];

  Future<void> loadFoods() async {
    try {
      final raw = await rootBundle.loadString('assets/data/nigerian_foods.json');
      final data = json.decode(raw) as List<dynamic>;
      _foods = data
          .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList();
      debugPrint('Loaded ${_foods.length} foods');
    } catch (e) {
      debugPrint('Failed to load foods: $e');
    }
  }

  /// Best-effort match by keyword, then by name substring.
  FoodItem matchFood(String query) {
    final lowerQuery = query.toLowerCase().trim();

    for (final food in _foods) {
      for (final keyword in food.keywords) {
        if (lowerQuery.contains(keyword.toLowerCase()) ||
            keyword.toLowerCase().contains(lowerQuery)) {
          return food;
        }
      }
    }
    for (final food in _foods) {
      if (food.name.toLowerCase().contains(lowerQuery)) {
        return food;
      }
    }

    // Default fallback if no match found
    return FoodItem(
      id: 'default',
      name: 'Your Meal',
      category: 'mixed',
      feedbackTemplate:
          'Nice one! Keeping track is the first big step. Let’s make sure you rehydrate with water and get ready for a balanced next meal.',
      healthScore: 6,
      keywords: [],
      calories: 350,
      protein: 12,
      insight: 'Keeping track of what you eat is the first big step to intentional eating.',
    );
  }
}
