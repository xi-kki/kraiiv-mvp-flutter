import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/services/data_service.dart';
import '../../../core/theme/app_theme.dart';
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
    )..forward();
    _fadeSlide = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logMeal() async {
    if (_saving) return;
    setState(() => _saving = true);

    await DataService.addMeal(
      name: widget.food.name,
      category: widget.food.category,
      healthScore: widget.food.healthScore,
      feedback: widget.food.feedbackTemplate,
      calories: widget.food.calories,
      protein: widget.food.protein,
      isLocal: widget.food.isLocal,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primaryGreen,
          content: Row(
            children: [
              const Icon(LucideIcons.coins, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('${widget.food.name} logged! +10 KTC'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    // Small pause so the user sees the confirmation before landing home.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final score = food.healthScore;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.arrowLeft),
                ),
                const Spacer(),
                const Text(
                  'Scan Result',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _fadeSlide,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(_fadeSlide),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhoto(food),
                    const SizedBox(height: 20),
                    Text(
                      food.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(LucideIcons.flame,
                            color: AppTheme.orange, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          food.isLocal
                              ? 'Local & seasonal'
                              : 'Health score $score/10',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if (widget.aiLabel != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.bot,
                                color: AppTheme.primaryGreenDark, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              widget.aiConfidence != null
                                  ? 'Detected by Klia AI '
                                      '(${(widget.aiConfidence! * 100).round()}%)'
                                  : 'Detected by Klia AI',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryGreenDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildNutritionCard(food),
                    const SizedBox(height: 16),
                    _buildInsightCard(food),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _logMeal,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.checkCircle, size: 20),
                      label: Text(_saving ? 'Saving...' : 'Log Meal'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/scanner'),
                      icon: const Icon(LucideIcons.scanLine, size: 18),
                      label: const Text('Scan Another'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(FoodItem food) {
    final path = widget.imagePath;
    final hasImage = path != null && path.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: hasImage
            ? FutureBuilder<Uint8List>(
                future: XFile(path).readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  }
                  return _photoFallback(food);
                },
              )
            : _photoFallback(food),
      ),
    );
  }

  Widget _photoFallback(FoodItem food) {
    return Container(
      color: AppTheme.surface,
      child: Center(
        child: Icon(
          LucideIcons.utensils,
          color: AppTheme.primaryGreen.withValues(alpha: 0.5),
          size: 56,
        ),
      ),
    );
  }

  Widget _buildNutritionCard(FoodItem food) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          _nutrient(
            icon: LucideIcons.flame,
            label: 'Calories',
            value: '${food.calories}',
            unit: 'kcal',
          ),
          _divider(),
          _nutrient(
            icon: LucideIcons.dumbbell,
            label: 'Protein',
            value: food.protein.toStringAsFixed(food.protein % 1 == 0 ? 0 : 1),
            unit: 'g',
          ),
          _divider(),
          _nutrient(
            icon: LucideIcons.leaf,
            label: 'Health',
            value: '${food.healthScore}',
            unit: '/10',
          ),
        ],
      ),
    );
  }

  Widget _nutrient({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(height: 6),
          Text(
            '$value $unit',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 44, color: AppTheme.border);
  }

  Widget _buildInsightCard(FoodItem food) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.leaf, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Klia's insight",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreenDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  food.insight.isEmpty
                      ? food.feedbackTemplate
                      : food.insight,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
