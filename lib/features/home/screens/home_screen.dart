import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/mini_goal.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/nearby_places_service.dart';
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
  /// Nearby markets/farms for the user's city; null until the first load
  /// resolves. Empty stays null so the section renders nothing while we
  /// have no data (the service falls back to curated markets itself).
  List<NearbyPlace>? _nearbyPlaces;

  @override
  void initState() {
    super.initState();
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    final places = await NearbyPlacesService.fetchNearby(DataService.location);
    if (!mounted) return;
    setState(() => _nearbyPlaces = places);
  }

  Future<void> _openMaps(NearbyPlace place) async {
    final url = Uri.parse(place.mapsUrl);
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched) debugPrint('Could not open maps for ${place.name}');
  }

  String _kindLabel(String kind) {
    switch (kind) {
      case 'marketplace':
        return 'Local market';
      case 'greengrocer':
        return 'Fresh produce';
      case 'farm':
        return 'Farm shop';
      case 'organic':
        return 'Organic';
      default:
        return 'Local food';
    }
  }

  IconData _placeIcon(String kind) {
    switch (kind) {
      case 'greengrocer':
        return LucideIcons.carrot;
      case 'farm':
        return LucideIcons.shoppingBasket;
      case 'organic':
        return LucideIcons.leaf;
      default:
        return LucideIcons.store;
    }
  }
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

  Future<void> _toggleMiniGoal(String id) async {
    final already = DataService.miniGoalDoneToday(id);
    final awarded = await DataService.completeMiniGoal(id);
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
                Text('Mini goal complete! +$awarded KTC'),
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
            content: Text('This mini goal is already done today'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  /// Drill-down for a weekly bar: shows that day's meals and mini goals.
  void _showDayDetails(DateTime day) {
    final meals = DataService.mealsOn(day);
    final miniGoals = DataService.miniGoalsDoneOn(day);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.calendarDays,
                      color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _dayLabel(day),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Meals (${meals.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              if (meals.isEmpty)
                const Text(
                  'No meals logged this day',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                )
              else
                ...meals.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.utensils,
                            color: AppTheme.primaryGreen, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m['name'] as String,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        Text(
                          '${m['healthScore']}/10',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryGreenDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Mini goals (${miniGoals.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              if (miniGoals.isEmpty)
                const Text(
                  'No mini goals completed this day',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                )
              else
                ...miniGoals.map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.checkCircle,
                            color: AppTheme.primaryGreen, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            g.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        Text(
                          '+${g.points}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.gold,
                          ),
                        ),
                      ],
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
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];
    return '${weekdayNames[day.weekday - 1]} ${day.day} ${_monthName(day.month)}';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  (IconData, Color) _miniGoalStyle(String category) {
    switch (category) {
      case 'hydration':
        return (LucideIcons.droplets, AppTheme.primaryGreen);
      case 'movement':
        return (LucideIcons.footprints, AppTheme.orange);
      case 'nutrition':
        return (LucideIcons.carrot, AppTheme.primaryGreenDark);
      case 'mindfulness':
        return (LucideIcons.brain, AppTheme.gold);
      case 'sleep':
        return (LucideIcons.moon, AppTheme.textMuted);
      case 'local':
        return (LucideIcons.leaf, AppTheme.primaryGreenDark);
      default:
        return (LucideIcons.sparkles, AppTheme.gold);
    }
  }

  Widget _buildMiniGoalSection() {
    final plan = DataService.miniGoalPlan;
    final done = DataService.miniGoalsDoneThisWeek;
    final total = DataService.miniGoalsTotalThisWeek;
    final points = DataService.miniGoalPointsThisWeek;
    final goal = DataService.healthGoal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.listChecks,
                color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Mini Goals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    'Small actions chipped from your goal',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+$points KTC this week',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryGreenDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...plan.map(
          (g) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildMiniGoalRow(g),
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: total == 0 ? 0 : done / total,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          backgroundColor: AppTheme.border,
          color: AppTheme.primaryGreen,
        ),
        const SizedBox(height: 6),
        Text(
          '$done of $total actions this week',
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          'Goal: $goal',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.gold,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniGoalRow(MiniGoal goal) {
    final doneToday = DataService.miniGoalDoneToday(goal.id);
    final doneWeek = DataService.miniGoalDoneThisWeek(goal.id);
    final (icon, color) = _miniGoalStyle(goal.category);
    return Material(
      color: doneToday ? AppTheme.surface : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _toggleMiniGoal(goal.id),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: doneToday ? AppTheme.primaryGreen : AppTheme.border,
              width: doneToday ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color:
                            doneToday ? AppTheme.textMuted : AppTheme.textDark,
                        decoration: doneToday ? TextDecoration.lineThrough : null,
                        decorationColor: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$doneWeek/7 this week',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: doneToday
                      ? AppTheme.primaryGreen
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '+${goal.points}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: doneToday ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            _buildGiantGoalCard(),
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
            const SizedBox(height: 22),
            _buildMiniGoalSection(),
            const SizedBox(height: 14),
            _buildSectionTitle(
              icon: LucideIcons.sparkles,
              iconColor: AppTheme.gold,
              title: 'Local & Seasonal Ideas',
            ),
            const SizedBox(height: 12),
            _buildRecipeCarousel(),
            const SizedBox(height: 22),
            _buildNearbySection(),
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


  /// The user's "giant goal" (from onboarding) with today's progress toward
  /// it — daily goals + mini goals both chip into this one headline.
  Widget _buildGiantGoalCard() {
    final goal = DataService.healthGoal;
    final dailyDone =
        DataService.goalsCompletedToday.where((c) => c).length;
    final plan = DataService.miniGoalPlan;
    final miniDone =
        plan.where((g) => DataService.miniGoalDoneToday(g.id)).length;
    final done = dailyDone + miniDone;
    final total = DataService.dailyGoals.length + plan.length;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.10),
            AppTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.target,
                color: AppTheme.primaryGreenDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Your Giant Goal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '$done/$total today',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            goal,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryGreenDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.border,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
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
              final day = DateTime.now()
                  .subtract(Duration(days: 6 - i));
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => _showDayDetails(day),
                    borderRadius: BorderRadius.circular(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
      height: 228,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: RecipeRepository.recipes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final recipe = RecipeRepository.recipes[index];
          return Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Real food photo — matches prototype video frames 130-180 & preview HTML
                Image.network(
                  recipe.imageUrl,
                  height: 108,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    height: 108,
                    color: AppTheme.sageLight,
                    child: Icon(_recipeIcon(recipe.icon),
                        color: AppTheme.primaryGreen),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recipe.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => context.push('/recipe/$index'),
                          icon: const Icon(LucideIcons.chevronRight, size: 14),
                          label: const Text('View Recipe'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  /// "Nearby Local Food" — markets/farms near the user's city (the
  /// prototype's location-driven recommendation). Renders nothing until
  /// data arrives and nothing at all if the service comes back empty.
  Widget _buildNearbySection() {
    final places = _nearbyPlaces;
    if (places == null || places.isEmpty) return const SizedBox.shrink();
    final city = DataService.location.trim().isEmpty
        ? 'your city'
        : DataService.location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: LucideIcons.store,
          iconColor: AppTheme.primaryGreen,
          title: 'Nearby Local Food',
          trailing: city,
        ),
        const SizedBox(height: 12),
        ...places.map(_buildPlaceRow),
      ],
    );
  }

  Widget _buildPlaceRow(NearbyPlace place) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openMaps(place),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _placeIcon(place.kind),
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_kindLabel(place.kind)} · '
                        '${place.distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
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
