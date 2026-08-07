import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/services/data_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repository/recipe_repository.dart';

/// Home dashboard matching the prototype:
/// greeting → progress card → today's goals → local & seasonal ideas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _firstName {
    final name = DataService.userName.trim();
    if (name.isEmpty) return 'there';
    return name.split(' ').first;
  }

  Future<void> _toggleGoal(int index) async {
    final already = DataService.goalsCompletedToday[index];
    final awarded = await DataService.completeGoal(index);
    if (!mounted) return;
    setState(() {});
    if (awarded > 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            content: Row(
              children: [
                const Icon(LucideIcons.coins, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('Goal complete! +$awarded KTC'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
    } else if (already) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.textMuted,
            content: Text('This goal was already completed today'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = DataService.goalsCompletedToday;
    final balance = DataService.ktcBalance;
    final weekly = DataService.weeklyMealCounts;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _buildTopBar(balance),
            const SizedBox(height: 20),
            Text(
              '${_greeting()}, $_firstName!',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Let\'s make today\'s intentional',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            _buildProgressCard(completed, weekly),
            const SizedBox(height: 24),
            _buildSectionTitle(
              icon: LucideIcons.flame,
              iconColor: AppTheme.orange,
              title: "Today's Goals",
              trailing: '${completed.where((c) => c).length}/${completed.length}',
            ),
            const SizedBox(height: 10),
            ...List.generate(DataService.dailyGoals.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildGoalRow(i, completed[i]),
              );
            }),
            const SizedBox(height: 14),
            _buildSectionTitle(
              icon: LucideIcons.sparkles,
              iconColor: AppTheme.gold,
              title: 'Local & Seasonal Ideas',
            ),
            const SizedBox(height: 12),
            _buildRecipeCarousel(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int balance) {
    final initial = _firstName.isNotEmpty && _firstName != 'there'
        ? _firstName[0].toUpperCase()
        : 'K';
    return Row(
      children: [
        const Icon(LucideIcons.leaf, color: AppTheme.primaryGreen, size: 22),
        const SizedBox(width: 6),
        const Text(
          'Kraiiv',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Talk to Klia',
          onPressed: () => context.push('/chat'),
          icon: const Icon(LucideIcons.messageCircle,
              color: AppTheme.textDark, size: 22),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () => context.push('/rewards'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.coins, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$balance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'KTC',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => context.push('/profile'),
          borderRadius: BorderRadius.circular(20),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: AppTheme.gold,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(
      List<bool> completed, List<int> weekly) {
    final done = completed.where((c) => c).length;
    final total = completed.length;
    final progress = total == 0 ? 0.0 : done / total;
    final maxCount = weekly.fold<int>(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: AppTheme.border,
                      color: AppTheme.primaryGreen,
                    ),
                    Text(
                      '$done/$total',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Keep going — small steps count',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/progress'),
                icon: const Icon(LucideIcons.chevronRight, size: 16),
                label: const Text('View Details'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Weekly mini bar chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final count = weekly[i];
              final height = count == 0
                  ? 4.0
                  : 6.0 + (count / maxCount) * 34.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      if (count > 0)
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      const SizedBox(height: 3),
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: count > 0
                              ? AppTheme.primaryGreen
                              : AppTheme.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
            ),
          ),
      ],
    );
  }

  Widget _buildGoalRow(int index, bool done) {
    final goal = DataService.dailyGoals[index];
    final reward = goal['reward'] as int;
    return Material(
      color: done ? AppTheme.surface : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _toggleGoal(index),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: done ? AppTheme.primaryGreen : AppTheme.border,
              width: done ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              done
                  ? const Icon(LucideIcons.checkCircle,
                      color: AppTheme.primaryGreen, size: 24)
                  : const Icon(LucideIcons.circle,
                      color: AppTheme.textMuted, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal['title'] as String,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: done ? AppTheme.textMuted : AppTheme.textDark,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: AppTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: done
                      ? AppTheme.primaryGreen
                      : AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+$reward',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color:
                        done ? Colors.white : AppTheme.primaryGreenDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCarousel() {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: RecipeRepository.recipes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final recipe = RecipeRepository.recipes[index];
          return Container(
            width: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _recipeIcon(recipe.icon),
                    color: AppTheme.primaryGreen,
                    size: 22,
                  ),
                ),
                const Spacer(),
                Text(
                  recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => context.push('/recipe/$index'),
                  icon: const Icon(LucideIcons.chevronRight, size: 15),
                  label: const Text('View Recipe'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        },
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
