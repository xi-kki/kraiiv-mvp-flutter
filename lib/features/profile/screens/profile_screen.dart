import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/services/data_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/prototype_widgets.dart';

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
    'No preference',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Halal',
    'Keto / Low-carb',
    'Gluten-free',
  ];

  static const List<String> _goals = [
    'Eat more vegetables',
    'Reduce sugar intake',
    'Cook at home more',
    'Lose weight',
    'Gain muscle',
    'Improve digestion',
    'Boost energy',
    'Eat more local food',
  ];

  @override
  Widget build(BuildContext context) {
    final name = DataService.userName;
    final firstName = name.split(' ').first;
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    final weekly = DataService.weeklyMealCounts;
    final completion = (DataService.weeklyCompletionRate * 100).round();
    final totalMeals = weekly.fold<int>(0, (a, b) => a + b);
    final streak = DataService.currentStreak;
    final totalKTC = DataService.ktcBalance;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'My Profile',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.push('/settings'),
                      icon: Icon(LucideIcons.settings, color: AppTheme.mutedForeground),
                    ),
                  ],
                ),
              ),
            ),

            // Profile Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _buildIdentityCard(initial, firstName),
              ),
            ),

            // Profile Info Rows
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildProfileRows(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Weekly Progress
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildWeeklyProgress(weekly, completion),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Habit Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildHabitCategories(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Achievements
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildAchievements(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Notification Toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildNudgeToggle(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Logout & Start Over
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildLogoutButton(),
                  const SizedBox(height: 12),
                  _buildStartOverButton(),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard(String initial, String firstName) {
    final totalKTC = DataService.totalKTC;
    final streak = DataService.streak;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.95),
            AppTheme.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl + 4),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              initial,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 32,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $firstName!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(LucideIcons.coins, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$totalKTC KTC · $streak day streak',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRows() {
    final goal = DataService.healthGoal;
    final preference = DataService.dietaryPreference;
    final location = DataService.location;

    return Column(
      children: [
        _ProfileRow(
          icon: LucideIcons.target,
          iconColor: AppTheme.primary,
          label: 'Health Goal',
          value: goal,
          onTap: _editProfile,
        ),
        _ProfileRow(
          icon: LucideIcons.salad,
          iconColor: AppTheme.gold,
          label: 'Dietary Preference',
          value: preference,
          onTap: _editProfile,
        ),
        _ProfileRow(
          icon: LucideIcons.mapPin,
          iconColor: AppTheme.orange,
          label: 'Location',
          value: location.isEmpty ? 'Not set' : location,
          onTap: _editProfile,
        ),
        _ProfileRow(
          icon: LucideIcons.calendar,
          iconColor: AppTheme.blue,
          label: 'Member Since',
          value: _formatJoinDate(DataService.joinDate),
          onTap: null,
        ),
        _ProfileRow(
          icon: LucideIcons.shieldCheck,
          iconColor: DataService.isLoggedInWithGoogle ? AppTheme.primary : AppTheme.gold,
          label: 'Google Account',
          value: DataService.isLoggedInWithGoogle
              ? (DataService.userEmail.isNotEmpty ? DataService.userEmail : 'Connected')
              : 'Connect to sync KTC',
          onTap: DataService.isLoggedInWithGoogle ? null : _connectGoogle,
        ),
      ],
    );
  }

  Future<void> _connectGoogle() async {
    final name = DataService.userName;
    final email = '${name.toLowerCase().replaceAll(' ', '')}@gmail.com';
    await DataService.signInWithGoogle(email: email, name: name);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connected with Google ($email). KTC balance synced!'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatJoinDate(dynamic date) {
    if (date is DateTime) {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return '${months[date.month - 1]} ${date.year}';
    }
    return date.toString();
  }

  Widget _buildWeeklyProgress(List<int> weekly, int completion) {
    final labels = List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return names[day.weekday - 1];
    });
    final maxCount = weekly.fold<int>(1, (a, b) => a > b ? a : b);
    final totalMeals = DataService.totalMeals;

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
                child: Icon(LucideIcons.barChart2, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Progress',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground,
                      ),
                    ),
                    Text(
                      'Completion rate: $completion% of days',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$totalMeals meals',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final count = weekly[i];
              final height = count == 0
                  ? 6.0
                  : 10.0 + (count / maxCount) * 50.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
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
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: AppTheme.mutedForeground,
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

  Widget _buildHabitCategories() {
    final categories = [
      {'label': 'Hydration', 'icon': LucideIcons.droplets, 'color': AppTheme.primary, 'count': DataService.hydrationCount},
      {'label': 'Movement', 'icon': LucideIcons.footprints, 'color': AppTheme.orange, 'count': DataService.movementCount},
      {'label': 'Nutrition', 'icon': LucideIcons.carrot, 'color': AppTheme.primaryDark, 'count': DataService.nutritionCount},
      {'label': 'Mindfulness', 'icon': LucideIcons.brain, 'color': AppTheme.gold, 'count': DataService.mindfulnessCount},
      {'label': 'Sleep', 'icon': LucideIcons.moon, 'color': AppTheme.mutedForeground, 'count': DataService.sleepCount},
      {'label': 'Local Food', 'icon': LucideIcons.leaf, 'color': AppTheme.primary, 'count': DataService.localCount},
    ];

    return Column(
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
              child: Icon(LucideIcons.listChecks, color: AppTheme.gold, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Habit Categories',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.foreground,
              ),
            ),
            const Spacer(),
            Text(
              '${DataService.totalMiniGoalsDone} completed',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return _HabitCategoryCard(
              label: cat['label'] as String,
              icon: cat['icon'] as IconData,
              color: cat['color'] as Color,
              count: cat['count'] as int,
              onTap: () => _showCategoryDetails(
                cat['label'] as String,
                cat['count'] as int,
                cat['icon'] as IconData,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    final achievements = [
      {'title': 'First Steps', 'desc': 'Logged your first meal', 'icon': LucideIcons.star, 'unlocked': DataService.totalMealsLogged >= 1},
      {'title': 'Week Warrior', 'desc': '7-day streak', 'icon': LucideIcons.flame, 'unlocked': DataService.currentStreak >= 7},
      {'title': 'Month Master', 'desc': '30-day streak', 'icon': LucideIcons.trophy, 'unlocked': DataService.currentStreak >= 30},
      {'title': 'Local Legend', 'desc': '10 local meals', 'icon': LucideIcons.leaf, 'unlocked': DataService.localMealsCount >= 10},
      {'title': 'Hydration Hero', 'desc': '50 water goals', 'icon': LucideIcons.droplets, 'unlocked': DataService.hydrationCount >= 50},
      {'title': 'KTC Collector', 'desc': 'Earned 1,000 KTC', 'icon': LucideIcons.coins, 'unlocked': DataService.lifetimeKTC >= 1000},
    ];

    return Column(
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
              child: Icon(LucideIcons.award, color: AppTheme.gold, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Achievements',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.foreground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...achievements.map((a) => _AchievementTile(
          title: a['title'] as String,
          desc: a['desc'] as String,
          icon: a['icon'] as IconData,
          unlocked: a['unlocked'] as bool,
        )),
      ],
    );
  }

  Widget _buildNudgeToggle() {
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.bell, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Check-in Reminder',
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Get a gentle nudge each evening to log your meals',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          _PrototypeSwitch(
            value: DataService.notificationsEnabled,
            onChanged: (v) async {
              await NotificationService.setEnabled(v);
              await DataService.setNotificationsEnabled(v);
              if (v) {
                await NotificationService.scheduleDailyCheckIn();
              } else {
                await NotificationService.cancelAll();
              }
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return PrototypeButton(
      onPressed: _confirmLogout,
      outlined: true,
      foregroundColor: AppTheme.danger,
      borderColor: AppTheme.danger,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.logOut, size: 18),
          const SizedBox(width: 8),
          const Text('Log Out'),
        ],
      ),
    );
  }

  Widget _buildStartOverButton() {
    return PrototypeButton(
      onPressed: _confirmStartOver,
      outlined: true,
      foregroundColor: AppTheme.mutedForeground,
      borderColor: AppTheme.border,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.refreshCw, size: 18),
          const SizedBox(width: 8),
          const Text('Start Over'),
        ],
      ),
    );
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: DataService.userName);
    String? preference = DataService.dietaryPreference;
    String? goal = DataService.healthGoal;
    final locationController = TextEditingController(text: DataService.location);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl + 4)),
          title: Text('Edit Profile', style: GoogleFonts.playfairDisplay(color: AppTheme.foreground)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: preference,
                  decoration: InputDecoration(
                    labelText: 'Dietary Preference',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                  ),
                  items: _preferences.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => preference = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: goal,
                  decoration: InputDecoration(
                    labelText: 'Health Goal',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                  ),
                  items: _goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => goal = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.mutedForeground)),
            ),
            PrototypeButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                await DataService.updateProfile(
                  name: nameController.text.trim(),
                  dietaryPreference: preference ?? 'No preference',
                  healthGoal: goal ?? 'Eat more vegetables',
                  location: locationController.text.trim(),
                );
                if (mounted) {
                  nav.pop();
                  setState(() {});
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl + 4)),
        title: Text('Log Out?', style: GoogleFonts.playfairDisplay(color: AppTheme.foreground)),
        content: Text(
          'You\'ll need to log in again to continue. Your data will stay saved.',
          style: GoogleFonts.inter(color: AppTheme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.mutedForeground)),
          ),
          PrototypeButton(
            onPressed: () => Navigator.pop(context, true),
            foregroundColor: AppTheme.danger,
            backgroundColor: AppTheme.danger.withValues(alpha: 0.1),
            borderColor: AppTheme.danger,
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DataService.logOut();
      if (mounted) context.go('/login');
    }
  }

  Future<void> _confirmStartOver() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl + 4)),
        title: Text('Start Over?', style: GoogleFonts.playfairDisplay(color: AppTheme.danger)),
        content: Text(
          'This will delete ALL your data: meals, streaks, KTC, mini goals, and profile. This cannot be undone.',
          style: GoogleFonts.inter(color: AppTheme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.mutedForeground)),
          ),
          PrototypeButton(
            onPressed: () => Navigator.pop(context, true),
            foregroundColor: Colors.white,
            backgroundColor: AppTheme.danger,
            child: const Text('Yes, Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DataService.wipeAllData();
      if (mounted) context.go('/splash');
    }
  }

  void _showCategoryDetails(String label, int count, IconData icon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
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
                  child: Icon(icon, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.foreground,
                        ),
                      ),
                      Text(
                        '$count completions this week',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrototypeEmptyState(
              icon: icon,
              title: 'Details coming soon',
              subtitle: 'We\'re working on detailed history for each habit category',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ProfileRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(LucideIcons.chevronRight, color: AppTheme.mutedForeground, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitCategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _HabitCategoryCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.foreground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final bool unlocked;

  const _AchievementTile({
    required this.title,
    required this.desc,
    required this.icon,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: unlocked ? AppTheme.card : AppTheme.muted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: unlocked ? AppTheme.gold.withValues(alpha: 0.3) : AppTheme.border,
                width: unlocked ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? AppTheme.gold.withValues(alpha: 0.15)
                        : AppTheme.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                    border: unlocked
                        ? Border.all(color: AppTheme.gold, width: 2)
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: unlocked ? AppTheme.gold : AppTheme.mutedForeground,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: unlocked ? AppTheme.foreground : AppTheme.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: unlocked ? AppTheme.mutedForeground : AppTheme.mutedForeground.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (unlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.check, color: AppTheme.gold, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Unlocked',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrototypeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrototypeSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? AppTheme.primary : AppTheme.border,
          boxShadow: value
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: value ? 22 : 2,
              top: 2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
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
}