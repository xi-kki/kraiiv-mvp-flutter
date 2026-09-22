import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/services/data_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/prototype_widgets.dart';
import '../../../data/repository/food_repository.dart';
/// Scan result screen matching the prototype:
/// food name → calories/protein → Klia insight → log meal.
class ScanResultScreen extends StatefulWidget {
  final FoodItem food;
  final String? imagePath;
  final String? aiLabel;
  final double? aiConfidence;

  const ScanResultScreen({
    super.key,
    required this.food,
    this.imagePath,
    this.aiLabel,
    this.aiConfidence,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeSlide;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logMeal() async {
    setState(() => _saving = true);

    final result = await DataService.addMeal(
      name: widget.food.name,
      category: 'Scanned',
      healthScore: widget.food.healthScore,
      feedback: 'Logged from scan',
      calories: widget.food.calories,
      protein: widget.food.protein,
      isLocal: widget.food.isLocal,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.orange,
          content: Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final goalText = result.completedGoals.isNotEmpty
        ? ' · Auto-completed: ${result.completedGoals.join(', ')}'
        : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primary,
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Meal logged! +${result.ktcEarned} KTC$goalText',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        duration: const Duration(seconds: 3),
      ),
    );

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final score = food.healthScore;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeSlide,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(_fadeSlide),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                // Top bar
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(LucideIcons.arrowLeft, color: AppTheme.foreground),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.card,
                        foregroundColor: AppTheme.foreground,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Scan Result',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 20),

                // Photo
                _buildPhoto(food),
                const SizedBox(height: 24),

                // Food name
                Text(
                  food.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),

                // Local/seasonal badge
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: food.isLocal
                            ? AppTheme.primary.withValues(alpha: 0.12)
                            : AppTheme.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        food.isLocal ? LucideIcons.leaf : LucideIcons.flame,
                        color: food.isLocal ? AppTheme.primary : AppTheme.orange,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      food.isLocal ? 'Local & seasonal' : 'Health score $score/10',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: food.isLocal ? AppTheme.primaryDark : AppTheme.orange,
                      ),
                    ),
                  ],
                ),

                // AI detection badge
                if (widget.aiLabel != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.bot, color: AppTheme.primaryDark, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          widget.aiConfidence != null
                              ? 'Detected by Klia AI (${(widget.aiConfidence! * 100).round()}%)'
                              : 'Detected by Klia AI',
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

                const SizedBox(height: 28),

                // Nutrition Card
                _buildNutritionCard(food),
                const SizedBox(height: 20),

                // Klia Insight Card
                _buildInsightCard(food),
                const SizedBox(height: 32),

                // Log Meal button
                PrototypeButton(
                  onPressed: _saving ? null : _logMeal,
                  loading: _saving,
                  icon: const Icon(LucideIcons.checkCircle, size: 20),
                  child: const Text('Log Meal'),
                ),
                const SizedBox(height: 14),

                // Scan Another button
                PrototypeButton(
                  onPressed: () => context.go('/scanner'),
                  outlined: true,
                  icon: const Icon(LucideIcons.scanLine, size: 18),
                  child: const Text('Scan Another'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(FoodItem food) {
    final path = widget.imagePath;

    if (path != null && !kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => _photoFallback(food),
          ),
        ),
      );
    }

    // Use network image or fallback
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.network(
          food.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _photoFallback(food),
        ),
      ),
    );
  }

  Widget _photoFallback(FoodItem food) {
    return Container(
      color: AppTheme.sageLight,
      child: Center(
        child: Icon(
          _recipeIcon(food.icon),
          color: AppTheme.primary,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildNutritionCard(FoodItem food) {
    return PrototypeCard(
      padding: const EdgeInsets.all(20),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.leaf, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Nutrition per serving',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _NutrientItem(
                icon: LucideIcons.flame,
                iconColor: AppTheme.orange,
                label: 'Calories',
                value: '${food.calories}',
                unit: 'kcal',
              )),
              _verticalDivider(),
              Expanded(child: _NutrientItem(
                icon: LucideIcons.dumbbell,
                iconColor: AppTheme.primary,
                label: 'Protein',
                value: '${food.protein.toStringAsFixed(1)}',
                unit: 'g',
              )),
              _verticalDivider(),
              Expanded(child: _NutrientItem(
                icon: LucideIcons.wheat,
                iconColor: AppTheme.gold,
                label: 'Carbs',
                value: '${food.carbs.toStringAsFixed(1)}',
                unit: 'g',
              )),
              _verticalDivider(),
              Expanded(child: _NutrientItem(
                icon: LucideIcons.droplet,
                iconColor: AppTheme.blue,
                label: 'Fat',
                value: '${food.fat.toStringAsFixed(1)}',
                unit: 'g',
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 50,
      color: AppTheme.border,
    );
  }

  Widget _buildInsightCard(FoodItem food) {
    return PrototypeCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppTheme.gold.withValues(alpha: 0.3),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.brain, color: AppTheme.gold, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Klia\'s Insight',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.lightbulb, color: AppTheme.gold, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    food.kiaInsight,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      height: 1.6,
                      color: AppTheme.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (food.isLocal) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.leaf, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Locally Sourced',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'This ingredient is in season and available at nearby markets. Eating local supports farmers and reduces carbon footprint.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            height: 1.5,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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

/// Nutrient item for nutrition card
class _NutrientItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _NutrientItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.foreground,
            ),
            children: [
              TextSpan(text: value),
              TextSpan(
                text: unit,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}