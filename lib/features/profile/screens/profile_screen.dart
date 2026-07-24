import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late bool _remindersEnabled;

  @override
  void initState() {
    super.initState();
    _remindersEnabled = DataService.dailyRemindersEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final streak = DataService.currentStreak;
    final bestStreak = DataService.bestStreak;
    final totalMeals = DataService.totalMealsLogged;
    final balance = DataService.ktcBalance;
    final goals = DataService.selectedGoals;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.headingBrown,
            ),
          ),
          const SizedBox(height: 32),

          // ── Stats Row ──
          Row(
            children: [
              Expanded(child: _buildStatCard('🔥', 'Streak', '$streak day${streak == 1 ? '' : 's'}')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('🏆', 'Best', '$bestStreak day${bestStreak == 1 ? '' : 's'}')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('🍲', 'Meals', '$totalMeals total')),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('🪙', 'Tokens', '$balance KTC', onTap: () => context.push('/rewards')),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Your Goals ──
          if (goals.isNotEmpty) ...[
            const Text(
              'Your Goals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.headingBrown,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: goals.map((goal) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.supportiveGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.supportiveGreen.withOpacity(0.2)),
                ),
                child: Text(
                  goal,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.supportiveGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // ── Settings ──
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.warmBrown.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  secondary: const Icon(Icons.notifications_active_rounded, color: AppTheme.warmBrown),
                  title: const Text(
                    'Daily Reminders',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.headingBrown,
                    ),
                  ),
                  subtitle: Text(
                    _remindersEnabled ? 'Klia will remind you to log meals' : 'Reminders off',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textBody.withOpacity(0.6),
                    ),
                  ),
                  value: _remindersEnabled,
                  activeColor: AppTheme.supportiveGreen,
                  onChanged: (value) async {
                    setState(() => _remindersEnabled = value);
                    await DataService.setDailyReminders(value);
                    if (value) {
                      await NotificationService.scheduleStandardReminders();
                    } else {
                      await NotificationService.cancelAll();
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value ? 'Daily reminders enabled 🌿' : 'Reminders turned off'),
                          backgroundColor: AppTheme.supportiveGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                Divider(height: 1, color: AppTheme.warmBrown.withOpacity(0.08)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.star_rounded, color: AppTheme.warmBrown),
                  title: const Text(
                    'Rate Kraiiv',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.headingBrown,
                    ),
                  ),
                  subtitle: Text(
                    'Help us improve with your feedback',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textBody.withOpacity(0.6),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.warmBrown),
                  onTap: () => _showRatingDialog(),
                ),
                Divider(height: 1, color: AppTheme.warmBrown.withOpacity(0.08)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.info_outline_rounded, color: AppTheme.warmBrown),
                  title: const Text(
                    'About Kraiiv',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.headingBrown,
                    ),
                  ),
                  subtitle: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textBody.withOpacity(0.6),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.warmBrown),
                  onTap: () => _showAboutDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Google Sign-In Banner ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.warmBrown.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.warmBrown.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                const Text(
                  'Sign in to save your progress across devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textBody, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showComingSoon('Google Sign-in'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.textBody,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: const Text('Sign in with Google'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.supportiveGreen.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: AppTheme.textBody.withOpacity(0.6)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.headingBrown,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog() {
    int _rating = 0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Rate Kraiiv',
            style: TextStyle(color: AppTheme.headingBrown, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How was your experience with Kraiiv?',
                style: TextStyle(color: AppTheme.textBody),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => GestureDetector(
                  onTap: () => setDialogState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 40,
                      color: index < _rating ? const Color(0xFFD4A017) : AppTheme.warmBrown.withOpacity(0.3),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 16),
              if (_rating > 0)
                Text(
                  _rating >= 4 ? 'Thanks! We love you too 💚' : _rating >= 2 ? 'We\'ll do better! 🙏' : 'Sorry! Tell us how to improve',
                  style: const TextStyle(color: AppTheme.supportiveGreen, fontWeight: FontWeight.w500),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textBody)),
            ),
            ElevatedButton(
              onPressed: _rating == 0 ? null : () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_rating >= 4 ? 'Thanks for the love! 💚' : 'Feedback noted — we\'ll improve!'),
                    backgroundColor: AppTheme.supportiveGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.supportiveGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Kraiiv',
              style: TextStyle(color: AppTheme.headingBrown, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your warm nutrition habit companion.',
              style: TextStyle(color: AppTheme.textBody, fontSize: 15),
            ),
            const SizedBox(height: 16),
            _aboutRow('Version', '1.0.0'),
            _aboutRow('Built with', 'Flutter + Hive'),
            _aboutRow('Foods database', '30 Nigerian meals'),
            _aboutRow('Made for', 'Nigerian busy lives 🇳🇬'),
            const SizedBox(height: 16),
            const Text(
              'Kraiiv helps you build healthy eating habits with simple guidance, streak tracking, and rewards — all offline-first.',
              style: TextStyle(color: AppTheme.textBody, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              '🌿 Be intentional.',
              style: TextStyle(
                color: AppTheme.supportiveGreen,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.warmBrown)),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🚧', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(
              '$feature',
              style: const TextStyle(color: AppTheme.headingBrown, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          '$feature is coming soon! We\'re working hard to bring you cloud sync, family plans, and more. Stay tuned! 🌿',
          style: const TextStyle(color: AppTheme.textBody, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textBody.withOpacity(0.6))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.headingBrown)),
        ],
      ),
    );
  }
}
