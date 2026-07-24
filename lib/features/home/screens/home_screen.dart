import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/data_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = DataService.currentStreak;
    final day = DataService.currentDay;
    final hasLogged = DataService.hasLoggedToday;
    final balance = DataService.ktcBalance;
    final totalMeals = DataService.totalMealsLogged;
    final progress = (day / 7.0).clamp(0.0, 1.0);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          children: [
            // ── Top Greeting ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textBody.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Day $day of 7',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.headingBrown,
                      ),
                    ),
                  ],
                ),
                // KTC Balance badge
                InkWell(
                  onTap: () => context.push('/rewards'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.warmBrown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.warmBrown.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          '$balance KTC',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warmBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Progress Ring ──
            Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.supportiveGreen.withOpacity(0.15),
                      color: AppTheme.supportiveGreen,
                      strokeWidth: 8,
                    ),
                    Center(
                      child: Text(
                        '$day/7',
                        style: const TextStyle(
                          color: AppTheme.supportiveGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                hasLogged ? '✅ Logged today' : 'Tap below to log your meal',
                style: TextStyle(
                  fontSize: 14,
                  color: hasLogged ? AppTheme.supportiveGreen : AppTheme.textBody.withOpacity(0.6),
                  fontWeight: hasLogged ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Central CTA ──
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: hasLogged ? 1.0 : _pulseAnimation.value,
                    child: child,
                  );
                },
                child: InkWell(
                  onTap: () => context.push('/logging'),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppTheme.warmBrown,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.warmBrown.withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasLogged ? Icons.check_rounded : Icons.camera_alt_rounded,
                          size: 56,
                          color: AppTheme.backgroundBeige,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasLogged ? 'Logged! ✨' : 'Log your\nmeal',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.backgroundBeige,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Stats Row ──
            Row(
              children: [
                Expanded(child: _buildStatCard('🔥', 'Streak', '$streak day${streak == 1 ? '' : 's'}')),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('🍲', 'Meals', '$totalMeals total')),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '🪙',
                    'Tokens',
                    '$balance',
                    onTap: () => context.push('/rewards'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Weekly Streak Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.supportiveGreen.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Weekly Streak',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.headingBrown,
                        ),
                      ),
                      Text(
                        '🔥 Day $day',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.supportiveGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.supportiveGreen.withOpacity(0.15),
                    color: AppTheme.supportiveGreen,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    day >= 7
                        ? '🎉 7-day goal complete! You're amazing!'
                        : '${7 - day} more day${7 - day == 1 ? '' : 's'} to complete your goal',
                    style: TextStyle(
                      fontSize: 13,
                      color: day >= 7 ? AppTheme.supportiveGreen : AppTheme.textBody.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Klia Tip ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.supportiveGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.supportiveGreen.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.supportiveGreen,
                    child: Text('🌿', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Klia says',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.supportiveGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getKliaTip(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textBody,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.warmBrown.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textBody.withOpacity(0.6))),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.headingBrown)),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅 Good morning';
    if (hour < 17) return '☀️ Good afternoon';
    return '🌆 Good evening';
  }

  String _getKliaTip() {
    final tips = [
      'Drink a glass of water before your next meal — it helps with digestion and keeps you hydrated. 💧',
      'Adding just a handful of vegetables to any meal boosts its nutrition. Try it today! 🥬',
      'Your body loves routine. Try eating at roughly the same times each day. ⏰',
      'Protein at breakfast keeps you full longer. Try eggs, moi moi, or akara! 🥚',
      'Colourful plates = colourful nutrients. Mix your colours! 🌈',
    ];
    return tips[DateTime.now().day % tips.length];
  }
}


