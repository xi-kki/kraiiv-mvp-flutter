import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repository/recipe_repository.dart';

/// Recipe detail for the Local & Seasonal Ideas cards.
class RecipeDetailScreen extends StatelessWidget {
  final int index;

  const RecipeDetailScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    const recipes = RecipeRepository.recipes;
    final recipe = recipes[index.clamp(0, recipes.length - 1)];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: const Text('Local & Seasonal'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  _iconFor(recipe.icon),
                  color: AppTheme.primaryGreen,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              recipe.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              recipe.subtitle,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              recipe.description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.55,
                color: AppTheme.textBody,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ingredients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: recipe.ingredients
                    .map((ingredient) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.checkCircle,
                                  color: AppTheme.primaryGreen, size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  ingredient,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    height: 1.4,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(LucideIcons.sparkles,
                    color: AppTheme.gold, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Klia\'s tip: enjoy this meal mindfully — no phone, '
                    'small bites, savour every flavour.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'salad':
        return LucideIcons.salad;
      case 'egg':
        return LucideIcons.egg;
      default:
        return LucideIcons.apple;
    }
  }
}
