import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/mini_goal.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/nearby_places_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/prototype_widgets.dart';
import '../../../data/repository/recipe_repository.dart';

/// Home dashboard matching the prototype:
/// greeting → progress card → today's goals → local & seasonal ideas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    await launchUrl(url, mode: LaunchMode.externalApplication);
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
    if (already) {
      _showRewardSnackBar('This goal was already completed today', LucideIcons.info, color: AppTheme.mutedForeground);
      return;
    }

    // Edge Case: Goal 0 requires an actual local meal logged today
    if (index == 0 && !DataService.loggedLocalMealToday) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primary,
            content: const Row(
              children: [
                Icon(LucideIcons.camera, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Scan or log a local Nigerian meal (e.g. Jollof, Egusi, Suya) to earn +15 KTC!'),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Scan Meal',
              textColor: Colors.white,
              onPressed: () => context.go('/scanner'),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          ),
        );
      return;
    }

    // Edge Case: Goal 3 requires 3 actual food scans today
    if (index == 3 && DataService.scansToday < 3) {
      final remaining = 3 - DataService.scansToday;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primary,
            content: Row(
              children: [
                const Icon(LucideIcons.scan, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('You scanned ${DataService.scansToday}/3 items today. Scan $remaining more to earn 25 KTC!'),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Scan Now',
              textColor: Colors.white,
              onPressed: () => context.go('/scanner'),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          ),
        );
      return;
    }

    // Intentional Mindful Confirmation for Goal 1 & Goal 2
    if (index == 1 || index == 2) {
      final title = index == 1
          ? 'Did you try a fresh local vegetable today?'
          : 'Did you eat mindfully without screens or distractions?';
      final subtitle = index == 1
          ? 'e.g. Ugu, Waterleaf, Spinach, Garden Egg, or Okra from a local market.'
          : 'Taking time to chew slowly and savor each bite without your phone or TV.';

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
          title: Text(title, style: GoogleFonts.playfairDisplay(color: AppTheme.foreground)),
          content: Text(subtitle, style: GoogleFonts.inter(color: AppTheme.mutedForeground)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Not yet', style: GoogleFonts.inter(color: AppTheme.mutedForeground)),
            ),
            PrototypeButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, I did!'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    final awarded = await DataService.completeGoal(index);
    if (!mounted) return;
    setState(() {});
    if (awarded > 0) {
      _showRewardSnackBar('Goal complete! +$awarded KTC', LucideIcons.coins);
    }
  }

  Future<void> _toggleMiniGoal(String id) async {
    final already = DataService.miniGoalDoneToday(id);
    final awarded = await DataService.completeMiniGoal(id);
    if (!mounted) return;
    setState(() {});
    if (awarded > 0) {
      _showRewardSnackBar('Mini goal complete! +$awarded KTC', LucideIcons.coins);
    } else if (already) {
      _showRewardSnackBar('This mini goal is already done today', LucideIcons.info, color: AppTheme.mutedForeground);
    }
  }

  void _showRewardSnackBar(String message, IconData icon, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color ?? AppTheme.primary,
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showDayDetails(DateTime day) {
    final meals = DataService.mealsOn(day);
    final miniGoals = DataService.miniGoalsDoneOn(day);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.calendarDays, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
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
                const PrototypeEmptyState(
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
                'Mini goals (${miniGoals.length})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 10),
              if (miniGoals.isEmpty)
                const PrototypeEmptyState(
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
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdayNames[day.weekday - 1]} ${day.day} ${months[day.month - 1]}';
  }

  (IconData, Color) _miniGoalStyle(String category) {
    switch (category) {
      case 'hydration':
        return (LucideIcons.droplets, AppTheme.primary);
      case 'movement':
        return (LucideIcons.footprints, AppTheme.orange);
      case 'nutrition':
        return (LucideIcons.carrot, AppTheme.primaryDark);
      case 'mindfulness':
        return (LucideIcons.brain, AppTheme.gold);
      case 'sleep':
        return (LucideIcons.moon, AppTheme.mutedForeground);
      case 'local':
        return (LucideIcons.leaf, AppTheme.primaryDark);
      default:
        return (LucideIcons.sparkles, AppTheme.gold);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = DataService.goalsCompletedToday;
    final balance = DataService.ktcBalance;
    final weekly = DataService.weeklyMealCounts;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: _buildScannerFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeTopBar(balance: balance),
              const SizedBox(height: 16),
              StaggeredEntry(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()}, $_firstName!',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Let\'s make today intentional',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppTheme.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Giant Goal Card
              StaggeredEntry(
                index: 1,
                child: _buildGiantGoalCard(),
              ),
              const SizedBox(height: 20),

              // Progress Card
              StaggeredEntry(
                index: 2,
                child: _buildProgressCard(completed, weekly),
              ),
              const SizedBox(height: 28),

              // Today's Goals Section
              StaggeredEntry(
                index: 3,
                child: _buildSectionTitle(
                  icon: LucideIcons.flame,
                  iconColor: AppTheme.orange,
                  title: "Today's Goals",
                  trailing: '${completed.where((c) => c).length}/${completed.length}',
                ),
              ),
              const SizedBox(height: 14),
              for (int i = 0; i < DataService.dailyGoals.length; i++)
                StaggeredEntry(
                  index: 4 + i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildGoalRow(i, completed[i]),
                  ),
                ),
              const SizedBox(height: 28),

              // Mini Goals Section
              StaggeredEntry(
                index: 10,
                child: _buildMiniGoalSection(),
              ),
              const SizedBox(height: 28),

              // Local & Seasonal Ideas
              StaggeredEntry(
                index: 11,
                child: _buildSectionTitle(
                  icon: LucideIcons.sparkles,
                  iconColor: AppTheme.gold,
                  title: 'Local & Seasonal Ideas',
                ),
              ),
              const SizedBox(height: 16),
              StaggeredEntry(
                index: 12,
                child: _buildRecipeCarousel(),
              ),
              const SizedBox(height: 28),

              // Nearby Section
              if (_nearbyPlaces != null && _nearbyPlaces!.isNotEmpty)
                StaggeredEntry(
                  index: 13,
                  child: _buildNearbySection(),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _HomeTopBar({required int balance}) {
    final initial = _firstName.isNotEmpty && _firstName != 'there'
        ? _firstName[0].toUpperCase()
        : 'K';
    return Row(
      children: [
        Icon(LucideIcons.leaf, color: AppTheme.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          'Kraiiv',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.foreground,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Talk to Klia',
          onPressed: () => context.push('/chat'),
          icon: Icon(LucideIcons.messageCircle, color: AppTheme.foreground, size: 24),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.card,
            foregroundColor: AppTheme.foreground,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => context.push('/rewards'),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.coins, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$balance',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'KTC',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => context.push('/profile'),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.gold,
            child: Text(
              initial,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGiantGoalCard() {
    final goal = DataService.healthGoal;
    final dailyDone = DataService.goalsCompletedToday.where((c) => c).length;
    final plan = DataService.miniGoalPlan;
    final miniDone = plan.where((g) => DataService.miniGoalDoneToday(g.id)).length;
    final done = dailyDone + miniDone;
    final total = DataService.dailyGoals.length + plan.length;
    final progress = total == 0 ? 0.0 : done / total;

    return PrototypeCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: AppTheme.background,
      borderColor: AppTheme.primary.withValues(alpha: 0.25),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.target, color: AppTheme.primaryDark, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Giant Goal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground,
                      ),
                    ),
                    Text(
                      'Daily goals + mini goals chip into this',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '$done/$total today',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            goal,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: PrototypeProgress(
              value: progress,
              height: 10,
              color: AppTheme.primary,
              backgroundColor: AppTheme.border,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(List<bool> completed, List<int> weekly) {
    final done = completed.where((c) => c).length;
    final total = completed.length;
    final progress = total == 0 ? 0.0 : done / total;
    final maxCount = weekly.fold<int>(1, (a, b) => a > b ? a : b);

    return PrototypeCard(
      padding: const EdgeInsets.all(20),
      elevated: true,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PrototypeCircularProgress(
                      value: progress,
                      strokeWidth: 6,
                      size: 60,
                      color: AppTheme.primary,
                      backgroundColor: AppTheme.border,
                    ),
                    Text(
                      '$done/$total',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Progress',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Keep going — small steps count',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/progress'),
                icon: const Icon(LucideIcons.chevronRight, size: 16),
                label: const Text('View Details'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Weekly mini bar chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final count = weekly[i];
              final height = count == 0
                  ? 4.0
                  : 8.0 + (count / maxCount) * 48.0;
              final day = DateTime.now().subtract(Duration(days: 6 - i));
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
                            color: count > 0 ? AppTheme.primary : AppTheme.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _dayLabel(day).split(' ')[0],
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.mutedForeground,
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
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.foreground,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.mutedForeground,
            ),
          ),
      ],
    );
  }

  Widget _buildGoalRow(int index, bool done) {
    final goal = DataService.dailyGoals[index];
    final reward = goal['reward'] as int;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleGoal(index),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: done ? AppTheme.card : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: done ? AppTheme.primary : AppTheme.border,
              width: done ? 2 : 1,
            ),
            boxShadow: done
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: done
                    ? Container(
                        key: const ValueKey('done'),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.check, color: Colors.white, size: 18),
                      )
                    : Container(
                        key: const ValueKey('todo'),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.mutedForeground, width: 2),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  goal['title'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: done ? AppTheme.mutedForeground : AppTheme.foreground,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: AppTheme.mutedForeground,
                    decorationThickness: 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: done
                      ? AppTheme.primary
                      : AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '+$reward',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: done ? Colors.white : AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(LucideIcons.listChecks, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Mini Goals',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                  Text(
                    'Small actions chipped from your goal',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '+$points KTC this week',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...plan.map(
          (g) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildMiniGoalRow(g),
          ),
        ),
        const SizedBox(height: 12),
        PrototypeProgress(
          value: total == 0 ? 0 : done / total,
          height: 8,
          color: AppTheme.primary,
          backgroundColor: AppTheme.border,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$done of $total actions this week',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppTheme.mutedForeground,
              ),
            ),
            Text(
              'Goal: $goal',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.gold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniGoalRow(MiniGoal goal) {
    final doneToday = DataService.miniGoalDoneToday(goal.id);
    final doneWeek = DataService.miniGoalDoneThisWeek(goal.id);
    final (icon, color) = _miniGoalStyle(goal.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleMiniGoal(goal.id),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: doneToday ? AppTheme.card : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: doneToday ? AppTheme.primary : AppTheme.border,
              width: doneToday ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: doneToday ? AppTheme.mutedForeground : AppTheme.foreground,
                        decoration: doneToday ? TextDecoration.lineThrough : null,
                        decorationColor: AppTheme.mutedForeground,
                        decorationThickness: 2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$doneWeek/7 this week',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: doneToday
                      ? AppTheme.primary
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '+${goal.points}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
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

  Widget _buildRecipeCarousel() {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: RecipeRepository.recipes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final recipe = RecipeRepository.recipes[index];
          return _RecipeCard(recipe: recipe, index: index);
        },
      ),
    );
  }

  Widget _buildNearbySection() {
    final places = _nearbyPlaces!;
    final city = DataService.location.trim().isEmpty
        ? 'your city'
        : DataService.location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: LucideIcons.store,
          iconColor: AppTheme.primary,
          title: 'Nearby Local Food',
          trailing: city,
        ),
        const SizedBox(height: 14),
        ...places.map(_buildPlaceRow),
      ],
    );
  }

  Widget _buildPlaceRow(NearbyPlace place) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openMaps(place),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _placeIcon(place.kind),
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_kindLabel(place.kind)} · ${place.distanceKm.toStringAsFixed(1)} km',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 18, color: AppTheme.mutedForeground),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerFAB() {
    return FloatingActionButton(
      onPressed: () => context.push('/scanner'),
      tooltip: 'Scan Food',
      child: const Icon(LucideIcons.camera, size: 26),
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final int index;

  const _RecipeCard({required this.recipe, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/recipe/$index'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food photo
              Stack(
                children: [
                  Image.network(
                    recipe.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      height: 120,
                      color: AppTheme.sageLight,
                      child: Center(
                        child: Icon(_recipeIcon(recipe.icon), color: AppTheme.primary, size: 36),
                      ),
                    ),
                  ),
                  // Gradient overlay for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.foreground,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => context.push('/recipe/$index'),
                        icon: const Icon(LucideIcons.chevronRight, size: 14),
                        label: const Text('View Recipe'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
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