import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/data_service.dart';

class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({super.key});

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _scaleController.forward();
    _confettiController.repeat();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = DataService.ktcBalance;
    final bestStreak = DataService.bestStreak;

    return Scaffold(
      backgroundColor: AppTheme.warmBrown,
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti particles
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: ConfettiPainter(progress: _confettiController.value),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // Trophy
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 96)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    '7-Day Goal Complete!',
                    style: TextStyle(
                      color: AppTheme.backgroundBeige,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You logged meals for 7 days straight.\nThat's a real commitment to yourself.',
                    style: TextStyle(
                      color: AppTheme.backgroundBeige.withOpacity(0.8),
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Stats
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('🔥', '$bestStreak', 'Day Streak'),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                        _buildStat('🪙', '$balance', 'KTC Earned'),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                        _buildStat('🍲', '7', 'Meals Logged'),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Quote
                  Text(
                    '"Health is not restriction.\nHealth is becoming."',
                    style: TextStyle(
                      color: AppTheme.backgroundBeige.withOpacity(0.6),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // CTA
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.warmBrown,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text(
                      'Keep going!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/rewards'),
                    child: Text(
                      'View my rewards',
                      style: TextStyle(
                        color: AppTheme.backgroundBeige.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}



// Simple confetti particle painter
class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles = [];

  ConfettiPainter({required this.progress}) {
    // Generate particles
    for (int i = 0; i < 40; i++) {
      particles.add(_ConfettiParticle(
        x: (i * 37.0) % 1.0,
        speed: 0.3 + (i % 5) * 0.15,
        size: 4 + (i % 3) * 2.0,
        color: [
          const Color(0xFF5A9A6F),
          const Color(0xFFD4A017),
          const Color(0xFFCC6633),
          const Color(0xFFFF6B6B),
          const Color(0xFF4ECDC4),
        ][i % 5],
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color;
      final y = ((progress * p.speed * 2 + p.x) % 1.0) * size.height;
      final x = p.x * size.width;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: p.size, height: p.size * 1.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}

class _ConfettiParticle {
  final double x;
  final double speed;
  final double size;
  final Color color;

  _ConfettiParticle({
    required this.x,
    required this.speed,
    required this.size,
    required this.color,
  });
}
