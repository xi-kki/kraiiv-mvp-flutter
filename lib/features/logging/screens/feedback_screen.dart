import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/data_service.dart';
import '../../../data/repository/food_repository.dart';

class InstantFeedbackScreen extends StatefulWidget {
  final String mealName;

  const InstantFeedbackScreen({super.key, required this.mealName});

  @override
  State<InstantFeedbackScreen> createState() => _InstantFeedbackScreenState();
}

class _InstantFeedbackScreenState extends State<InstantFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late Future<FoodItem> _foodMatchFuture;
  bool _mealSaved = false;
  int _ktcEarned = 0;

  @override
  void initState() {
    super.initState();
    final repo = FoodRepository();
    _foodMatchFuture = repo.loadFoods().then((_) => repo.matchFood(widget.mealName));
  }

  Future<void> _saveMeal(FoodItem foodItem) async {
    if (_mealSaved) return;

    // Calculate KTC earned
    int base = 10;
    int bonus = 0;
    if (foodItem.healthScore >= 8) bonus += 5;
    if (DataService.currentStreak >= 3) bonus += 3;
    _ktcEarned = base + bonus;

    await DataService.addMeal(
      name: foodItem.name,
      category: foodItem.category,
      healthScore: foodItem.healthScore,
      feedback: foodItem.feedbackTemplate,
    );

    if (mounted) {
      setState(() => _mealSaved = true);

      // Check if 7-day goal is complete
      if (DataService.is7DayGoalComplete) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.go('/celebration');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: SafeArea(
        child: FutureBuilder<FoodItem>(
          future: _foodMatchFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.supportiveGreen),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing your meal...',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textBody,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.warmBrown),
                      const SizedBox(height: 16),
                      const Text(
                        "Oops! Klia couldn't find that meal.",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Try describing it differently — like 'Jollof rice with chicken' or 'Eba and egusi soup'.",
                        style: TextStyle(color: AppTheme.textBody),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/logging'),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final foodItem = snapshot.data!;

            // Auto-save the meal
            _saveMeal(foodItem);

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Food name
                  Text(
                    foodItem.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.headingBrown,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getCategoryLabel(foodItem.category),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textBody.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Health Score
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: _getScoreColor(foodItem.healthScore).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: _getScoreColor(foodItem.healthScore).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getScoreEmoji(foodItem.healthScore),
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Health Score: ${foodItem.healthScore}/10',
                            style: TextStyle(
                              color: _getScoreColor(foodItem.healthScore),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Feedback Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.warmBrown.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      foodItem.feedbackTemplate,
                      style: const TextStyle(
                        color: AppTheme.textBody,
                        fontSize: 16,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // KTC earned badge
                  if (_mealSaved && _ktcEarned > 0)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.warmBrown.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppTheme.warmBrown.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              '+$_ktcEarned KTC earned!',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warmBrown,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const Spacer(flex: 2),

                  // Actions
                  ElevatedButton(
                    onPressed: () => context.go('/logging'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('Log another meal'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('Done for now'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'rice_based':
        return '🍚 Rice & Grain Based';
      case 'soups_and_swallows':
        return '🥣 Soups & Swallows';
      case 'beans_based':
        return '🫘 Beans & Legumes';
      case 'snacks':
        return '🍿 Snacks & Light Meals';
      default:
        return '🍽️ Mixed Meal';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return AppTheme.supportiveGreen;
    if (score >= 5) return const Color(0xFFD4A017);
    return const Color(0xFFCC6633);
  }

  String _getScoreEmoji(int score) {
    if (score >= 9) return '🌟';
    if (score >= 7) return '😊';
    if (score >= 5) return '👍';
    return '💡';
  }
}
