import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/services/data_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/prototype_widgets.dart';

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
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return names[day.weekday - 1];
    });
    final maxCount = weekly.fold<int>(1, (a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(LucideIcons.arrowLeft, color: AppTheme.foreground),
        ),
        title: Text(
          'Your Progress',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.foreground,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Today ring
            PrototypeCard(
              padding: const EdgeInsets.all(24),
              elevated: true,
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PrototypeCircularProgress(
                          value: total == 0 ? 0.0 : done / total,
                          strokeWidth: 7,
                          size: 72,
                          color: AppTheme.primary,
                          backgroundColor: AppTheme.border,
                        ),
                        Text(
                          '$done/$total',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Progress',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.foreground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keep going — small steps count',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PrototypeProgress(
                    value: total == 0 ? 0.0 : done / total,
                    height: 8,
                    color: AppTheme.primary,
                    backgroundColor: AppTheme.border,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Weekly Progress
            Text(
              'Weekly Progress',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completion rate: $completion% of days',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            PrototypeCard(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              elevated: true,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final count = weekly[i];
                      final height = count == 0
                          ? 6.0
                          : 10.0 + (count / maxCount) * 60.0;
                      final day = DateTime.now().subtract(Duration(days: 6 - i));
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => _showDayDetails(day),
                            borderRadius: BorderRadius.circular(4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (count > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '$count',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                Container(
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: count > 0
                                        ? AppTheme.primary
                                        : AppTheme.border,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  labels[i],
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${day.day}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppTheme.mutedForeground.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Daily Goals History
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.flame, color: AppTheme.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Daily Goals History',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(DataService.dailyGoals.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PrototypeCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(LucideIcons.target, color: AppTheme.orange, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DataService.dailyGoals[i]['title'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.foreground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Daily goal with KTC reward',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${DataService.dailyGoals[i]['reward']}',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(DateTime day) {
    final meals = DataService.mealsOn(day);
    final miniGoals = DataService.miniGoalsDoneOn(day);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.calendarDays, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _dayLabel(day),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Meals (${meals.length})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 10),
              if (meals.isEmpty)
                PrototypeEmptyState(
                  icon: LucideIcons.utensils,
                  title: 'No meals logged',
                  subtitle: 'Tap the scanner to log your first meal',
                )
              else
                ...meals.map(
                  (m) => _DayDetailRow(
                    icon: LucideIcons.utensils,
                    iconColor: AppTheme.primary,
                    title: m['name'] as String,
                    subtitle: '${m['healthScore']}/10 health score',
                    trailing: Text(
                      '${m['healthScore']}/10',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Mini Goals (${miniGoals.length})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 10),
              if (miniGoals.isEmpty)
                PrototypeEmptyState(
                  icon: LucideIcons.listChecks,
                  title: 'No mini goals completed',
                  subtitle: 'Complete small actions to earn KTC',
                )
              else
                ...miniGoals.map(
                  (g) => _DayDetailRow(
                    icon: LucideIcons.checkCircle,
                    iconColor: AppTheme.primary,
                    title: g.title,
                    subtitle: 'Completed',
                    trailing: Text(
                      '+${g.points}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.gold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _dayLabel(DateTime day) {
    const weekdayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${weekdayNames[day.weekday - 1]}, ${day.day} ${months[day.month - 1]}';
  }
}

class _DayDetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _DayDetailRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}