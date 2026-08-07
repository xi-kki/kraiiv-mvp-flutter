import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/services/data_service.dart';
import '../../../core/theme/app_theme.dart';

/// "Your Progress" detail — reached from the home progress card.
class ProgressDetailScreen extends StatefulWidget {
  const ProgressDetailScreen({super.key});

  @override
  State<ProgressDetailScreen> createState() => _ProgressDetailScreenState();
}

class _ProgressDetailScreenState extends State<ProgressDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final completed = DataService.goalsCompletedToday;
    final done = completed.where((c) => c).length;
    final total = completed.length;
    final weekly = DataService.weeklyMealCounts;
    final completion = (DataService.weeklyCompletionRate * 100).round();
    final labels = List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    });
    final maxCount = weekly.fold<int>(1, (a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: const Text('Your Progress'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Today ring
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: total == 0 ? 0 : done / total,
                          strokeWidth: 8,
                          backgroundColor: AppTheme.border,
                          color: AppTheme.primaryGreen,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$done/$total',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const Text(
                              'goals',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's progress",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          done == total
                              ? 'All goals complete — amazing!'
                              : '$done of $total daily goals done. '
                                  'Keep the momentum going!',
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Weekly Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'completion rate: $completion% of days',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 140,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (i) {
                        final count = weekly[i];
                        final height = count == 0
                            ? 6.0
                            : 10.0 + (count / maxCount) * 110.0;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (count > 0)
                                  Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryGreenDark,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Container(
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: count > 0
                                        ? AppTheme.primaryGreen
                                        : AppTheme.border,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: labels
                        .map((l) => Expanded(
                              child: Center(
                                child: Text(
                                  l,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(LucideIcons.flame, color: AppTheme.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  "Today's Goals",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(DataService.dailyGoals.length, (i) {
              final goal = DataService.dailyGoals[i];
              final isDone = completed[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isDone ? AppTheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isDone ? AppTheme.primaryGreen : AppTheme.border,
                    width: isDone ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    isDone
                        ? const Icon(LucideIcons.checkCircle,
                            color: AppTheme.primaryGreen, size: 22)
                        : const Icon(LucideIcons.circle,
                            color: AppTheme.textMuted, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        goal['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? AppTheme.textMuted
                              : AppTheme.textDark,
                        ),
                      ),
                    ),
                    Text(
                      '+${goal['reward']}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDone
                            ? AppTheme.primaryGreen
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
