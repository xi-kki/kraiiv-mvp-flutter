import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';

/// My Profile matching the prototype:
/// profile header → health goal / preference / location →
/// weekly progress chart → habit categories → achievements.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> _preferences = [
    'Vegetarian',
    'Vegan',
    'Gluten-free',
    'No restrictions',
  ];
  static const List<String> _goals = [
    'Feel more energized',
    'Eat more mindfully',
    'Improve overall health',
    'Try more local foods',
  ];

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: DataService.userName);
    var goal = DataService.healthGoal;
    var preference = DataService.dietaryPreference;
    final locationController = TextEditingController(text: DataService.location);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _goals.contains(goal) ? goal : null,
                  decoration: const InputDecoration(labelText: 'Health Goal'),
                  items: _goals
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setSheetState(() => goal = v ?? goal),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _preferences.contains(preference)
                      ? preference
                      : 'No restrictions',
                  decoration:
                      const InputDecoration(labelText: 'Dietary Preference'),
                  items: _preferences
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) =>
                      setSheetState(() => preference = v ?? preference),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved == true && mounted) {
      await DataService.setUserName(nameController.text.trim());
      await DataService.setHealthGoal(goal);
      await DataService.setDietaryPreference(preference);
      await DataService.setLocation(locationController.text.trim());
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = DataService.userName.trim();
    final firstName = name.isEmpty ? 'Kraiiv' : name.split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'K';
    final weekly = DataService.weeklyMealCounts;
    final completion = (DataService.weeklyCompletionRate * 100).round();

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(LucideIcons.arrowLeft),
              )
            : null,
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: _editProfile,
            icon: const Icon(LucideIcons.filePen, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _buildIdentityCard(initial, firstName),
            const SizedBox(height: 16),
            _buildProfileRows(),
            const SizedBox(height: 24),
            _buildWeeklyProgress(weekly, completion),
            const SizedBox(height: 24),
            _buildHabitCategories(),
            const SizedBox(height: 24),
            _buildAchievements(),
            const SizedBox(height: 8),
            _buildNudgeToggle(),
            const SizedBox(height: 24),
            _buildStartOverButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard(String initial, String firstName) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppTheme.gold,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(LucideIcons.coins,
                      color: AppTheme.primaryGreen, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${DataService.ktcBalance} KTC',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreenDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileRows() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _row(
            icon: LucideIcons.zap,
            label: 'Health Goal',
            value: DataService.healthGoal,
          ),
          const Divider(height: 1),
          _row(
            icon: LucideIcons.utensils,
            label: 'Preferred',
            value: DataService.dietaryPreference,
          ),
          const Divider(height: 1),
          _row(
            icon: LucideIcons.mapPin,
            label: 'Location',
            value: DataService.location.isEmpty
                ? 'Not set'
                : DataService.location,
          ),
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.gold, size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress(List<int> weekly, int completion) {
    final labels = List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    });
    final maxCount = weekly.fold<int>(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.trendingUp,
                color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Weekly Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const Spacer(),
            Text(
              'completion rate: $completion%',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final count = weekly[i];
                    final height = count == 0
                        ? 6.0
                        : 10.0 + (count / maxCount) * 90.0;
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
      ],
    );
  }

  Widget _buildHabitCategories() {
    final categories = [
      ('Food', DataService.totalMealsLogged, LucideIcons.utensils),
      ('Mindful', DataService.mindfulMeals, LucideIcons.heartPulse),
      ('Local', DataService.localMeals, LucideIcons.mapPin),
      ('Streak', DataService.currentStreak, LucideIcons.flame),
    ];
    final maxCount =
        categories.fold<int>(1, (a, c) => a > c.$2 ? a : c.$2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Habit Categories',
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
            children: categories.map((c) {
              final (label, count, icon) = c;
              final fraction = count / maxCount;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: () => _showCategoryDetails(label, count, icon),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(icon, color: AppTheme.gold, size: 17),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 66,
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 10,
                              backgroundColor: AppTheme.border,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 34,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryGreenDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showCategoryDetails(String label, int count, IconData icon) {
    final (description, tip, value) = switch (label) {
      'Food' => (
          'Meals logged in Kraiiv — the more you log, the better Klia can guide you.',
          'Log at least one local meal today to keep your streak alive.',
          '$count meals logged',
        ),
      'Mindful' => (
          'Meals scored 8/10 or higher — your healthiest, most balanced choices.',
          'Aim for one mindful meal: no distractions, slow bites, vegetables first.',
          '$count healthy meals',
        ),
      'Local' => (
          'Local and seasonal meals support Nigerian farmers and cut food miles.',
          'Try a farmer\'s market vegetable you have never cooked before.',
          '$count local meals',
        ),
      _ => (
          'Consecutive days with at least one action logged in Kraiiv.',
          'Do one small thing today — a mini goal or a meal log — to keep it going.',
          '${DataService.miniGoalStreak} day mini-goal streak',
        ),
    };
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
                  Icon(icon, color: AppTheme.gold, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreenDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tip: $tip',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    final badges = [
      (
        count: DataService.currentStreak,
        label: 'Streak Days',
        icon: LucideIcons.flame,
        color: AppTheme.orange,
      ),
      (
        count: DataService.mindfulMeals,
        label: 'Mindful Meals',
        icon: LucideIcons.heartPulse,
        color: AppTheme.primaryGreen,
      ),
      (
        count: DataService.localMeals,
        label: 'Local Meals',
        icon: LucideIcons.mapPin,
        color: AppTheme.blue,
      ),
      (
        count: DataService.totalMealsLogged,
        label: 'Meals Scanned',
        icon: LucideIcons.award,
        color: AppTheme.gold,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: badges
              .map((b) => Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(b.icon, color: b.color, size: 18),
                            const Spacer(),
                            Text(
                              '${b.count}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: b.color,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          b.label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildNudgeToggle() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: SwitchListTile(
        value: DataService.notificationsEnabled,
        activeTrackColor: AppTheme.primaryGreen,
        secondary: const Icon(LucideIcons.bell, color: AppTheme.gold),
        title: const Text(
          'Daily nudges',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: const Text(
          'Quick reminders to stay on track',
          style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
        ),
        onChanged: (enabled) async {
          setState(() {});
          await DataService.setNotificationsEnabled(enabled);
          if (enabled) {
            await NotificationService.enableDailyNudges();
          } else {
            await NotificationService.cancelAll();
          }
        },
      ),
    );
  }

  Widget _buildStartOverButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _confirmStartOver,
        icon: const Icon(
          LucideIcons.rotateCcw,
          size: 16,
          color: AppTheme.textMuted,
        ),
        label: const Text(
          'Start over from the beginning',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
      ),
    );
  }

  /// Wipes all local data (profile, meals, streaks, KTC, mini goals) and
  /// replays the welcome flow: splash → onboarding questions.
  Future<void> _confirmStartOver() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start over?'),
        content: const Text(
          'This clears your profile, logged meals, streaks, KTC balance and '
          'mini-goal progress, then takes you back to the welcome screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Start over'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DataService.resetAll();
    if (!mounted) return;
    context.go('/splash');
  }
}
