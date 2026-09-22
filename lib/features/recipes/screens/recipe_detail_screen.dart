import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/services/data_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/prototype_widgets.dart';
import '../../../data/repository/recipe_repository.dart';

/// Recipe detail screen matching the prototype.
class RecipeDetailScreen extends StatefulWidget {
  final int index;

  const RecipeDetailScreen({super.key, required this.index});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final recipe = RecipeRepository.recipes[widget.index];
    final isLocal = recipe.isLocal;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Hero image
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: AppTheme.sageLight,
                        child: Center(
                          child: Icon(_recipeIcon(recipe.icon), color: AppTheme.primary, size: 64),
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      ),
                    ),
                  ),
                  // Local badge
                  if (isLocal)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.leaf, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Local & Seasonal',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Title
                  Text(
                    recipe.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppTheme.mutedForeground,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    children: [
                      _RecipeStat(
                        icon: LucideIcons.flame,
                        iconColor: AppTheme.orange,
                        label: 'Calories',
                        value: '${recipe.calories} kcal',
                      ),
                      _RecipeStat(
                        icon: LucideIcons.dumbbell,
                        iconColor: AppTheme.primary,
                        label: 'Protein',
                        value: '${recipe.protein.toStringAsFixed(1)}g',
                      ),
                      _RecipeStat(
                        icon: LucideIcons.wheat,
                        iconColor: AppTheme.gold,
                        label: 'Carbs',
                        value: '${recipe.carbs.toStringAsFixed(1)}g',
                      ),
                      _RecipeStat(
                        icon: LucideIcons.droplet,
                        iconColor: AppTheme.blue,
                        label: 'Fat',
                        value: '${recipe.fat.toStringAsFixed(1)}g',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Health Score
                  PrototypeCard(
                    padding: const EdgeInsets.all(16),
                    borderColor: AppTheme.primary.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(LucideIcons.award, color: AppTheme.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Health Score',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                              Text(
                                '${recipe.healthScore}/10',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLocal)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.leaf, color: AppTheme.primary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Local & Seasonal',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Ingredients
                  Text(
                    'Ingredients',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...recipe.ingredients.map((ingredient) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _IngredientRow(ingredient: ingredient),
                      )),
                  const SizedBox(height: 28),

                  // Instructions
                  Text(
                    'Instructions',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...recipe.instructions.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _InstructionStep(
                          step: entry.key + 1,
                          instruction: entry.value,
                        ),
                      )),
                  const SizedBox(height: 28),

                  // Klia's Tip
                  PrototypeCard(
                    padding: const EdgeInsets.all(20),
                    borderColor: AppTheme.gold.withValues(alpha: 0.3),
                    elevated: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(LucideIcons.brain, color: AppTheme.gold, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Klia's Tip",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.foreground,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recipe.kiaTip,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  height: 1.6,
                                  color: AppTheme.foreground,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Log Meal Button
                  PrototypeButton(
                    onPressed: () async {
                      final result = await DataService.addMeal(
                        name: recipe.title,
                        category: 'Recipe',
                        healthScore: recipe.healthScore,
                        feedback: 'Logged from recipe',
                        calories: recipe.calories,
                        protein: recipe.protein,
                        isLocal: recipe.isLocal,
                      );

                      if (!context.mounted) return;

                      if (!result.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.orange,
                            content: Row(
                              children: [
                                const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                                const SizedBox(width: 10),
                                Expanded(child: Text(result.message, style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.primary,
                          content: Row(
                            children: [
                              const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text('${recipe.title} logged! +${result.ktcEarned} KTC', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                        ),
                      );
                      context.pop();
                    },
                    icon: const Icon(LucideIcons.utensils, size: 20),
                    child: const Text('Log This Meal'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _recipeIcon(String name) {
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

class _RecipeStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _RecipeStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final String ingredient;

  const _IngredientRow({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            ingredient,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              color: AppTheme.foreground,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int step;
  final String instruction;

  const _InstructionStep({required this.step, required this.instruction});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step $step',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                instruction,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: AppTheme.foreground,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}