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

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.feedbackTemplate,
    required this.healthScore,
    required this.keywords,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      feedbackTemplate: json['feedback_template'],
      healthScore: json['health_score'],
      keywords: List<String>.from(json['keywords']),
    );
  }
}

class FoodRepository {
  List<FoodItem> _foods = [];

  Future<void> loadFoods() async {
    try {
      final String response = await rootBundle.loadString('assets/data/nigerian_foods.json');
      final data = await json.decode(response) as List;
      _foods = data.map((e) => FoodItem.fromJson(e)).toList();
    } catch (e) {
      // Fallback if file not found during early dev without built assets
      debugPrint("Warning: Could not load JSON, using fallback data.");
      _foods = [
        FoodItem(
          id: '1',
          name: 'Jollof Rice and Chicken',
          category: 'rice_based',
          feedbackTemplate: 'Your jollof rice and chicken was tasty! 🍚 This meal gives you good energy from carbs and protein from the chicken. The tomato base is rich in lycopene — a powerful antioxidant. Next time, try adding steamed vegetables or a side salad for extra fibre and vitamins.',
          healthScore: 7,
          keywords: ['jollof', 'rice', 'chicken'],
        ),
        FoodItem(
          id: '2',
          name: 'Eba and Egusi Soup',
          category: 'soups_and_swallows',
          feedbackTemplate: 'Nice one! Egusi is packed with healthy fats and protein from melon seeds. 💪 To balance the heavy carbs in eba, try a smaller portion of eba next time and add more dark leafy greens to the soup.',
          healthScore: 8,
          keywords: ['eba', 'egusi', 'garri'],
        ),
        FoodItem(
          id: '3',
          name: 'Moi Moi and Plantain',
          category: 'beans_based',
          feedbackTemplate: "You're doing well! Moi moi is an excellent source of plant protein and fibre. 🌱 Paired with plantain, you get good energy and potassium. Great combo!",
          healthScore: 9,
          keywords: ['moi moi', 'plantain', 'dodo'],
        ),
        FoodItem(
          id: '4',
          name: 'Suya',
          category: 'snacks',
          feedbackTemplate: 'Suya is a fantastic high-protein snack — the spice blend (yaji) contains ginger and pepper which have anti-inflammatory properties. 🔥 Just remember to pair it with some cabbage, tomatoes, and onions!',
          healthScore: 6,
          keywords: ['suya', 'meat', 'beef'],
        ),
        FoodItem(
          id: '5',
          name: 'Pepper Soup',
          category: 'soups_and_swallows',
          feedbackTemplate: 'Pepper soup is light, warming, and full of aromatic spices! 🍲 The broth is hydrating and the spices aid digestion. A great choice when you want something nourishing without being too heavy.',
          healthScore: 8,
          keywords: ['pepper soup', 'peppersoup'],
        ),
      ];
    }
  }

  FoodItem matchFood(String query) {
    final lowerQuery = query.toLowerCase();
    
    for (final food in _foods) {
      for (final keyword in food.keywords) {
        if (lowerQuery.contains(keyword.toLowerCase())) {
          return food;
        }
      }
    }

    // Default fallback if no match found
    return FoodItem(
      id: 'default',
      name: 'Your Meal',
      category: 'mixed',
      feedbackTemplate: 'Nice one! Keeping track is the first big step. Let’s make sure you rehydrate with water and get ready for a balanced next meal.',
      healthScore: 6,
      keywords: [],
    );
  }
}
