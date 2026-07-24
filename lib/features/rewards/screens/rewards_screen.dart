import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/data_service.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final balance = DataService.ktcBalance;
    final history = DataService.tokenHistory;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Rewards'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Balance Card ──
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.warmBrown, Color(0xFF6B4F35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warmBrown.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  '$balance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'KTC Tokens',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    '≈ ₦0.00 value',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── How to Earn ──
          const Text(
            'How to earn',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.headingBrown,
            ),
          ),
          const SizedBox(height: 16),
          _buildEarnCard('📸', 'Log a meal', '+10 KTC', 'Snap or type what you ate'),
          _buildEarnCard('🌟', 'Healthy choice', '+5 bonus', 'Score 8/10 or higher'),
          _buildEarnCard('🔥', 'Streak bonus', '+3 bonus', 'Maintain a 3+ day streak'),
          const SizedBox(height: 28),

          // ── Redeem Options ──
          const Text(
            'Coming soon — Redeem',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.headingBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Redeem your KTC for real rewards',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textBody.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          _buildRedeemOption('📱', 'Airtime', '100 KTC', 'All networks'),
          _buildRedeemOption('📶', 'Data', '200 KTC', 'MTN, Airtel, Glo, 9Mobile'),
          _buildRedeemOption('🛒', 'Groceries', '150 KTC', 'Partner stores'),
          _buildRedeemOption('💪', 'Gym Access', '300 KTC', 'Partner gyms'),
          const SizedBox(height: 28),

          // ── History ──
          if (history.isNotEmpty) ...[
            const Text(
              'Earning history',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.headingBrown,
              ),
            ),
            const SizedBox(height: 16),
            ...history.take(10).map((entry) => _buildHistoryTile(
              entry['amount'] ?? 0,
              entry['reason'] ?? '',
              entry['timestamp'] ?? '',
            )),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEarnCard(String emoji, String title, String amount, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warmBrown.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.headingBrown,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textBody.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.supportiveGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              amount,
              style: const TextStyle(
                color: AppTheme.supportiveGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemOption(String emoji, String title, String cost, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warmBrown.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.headingBrown,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textBody.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warmBrown.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              cost,
              style: const TextStyle(
                color: AppTheme.warmBrown,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(int amount, String reason, String timestamp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warmBrown.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.supportiveGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🪙', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.headingBrown,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textBody.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+$amount',
            style: const TextStyle(
              color: AppTheme.supportiveGreen,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String isoTimestamp) {
    if (isoTimestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoTimestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays} days ago';
    } catch (_) {
      return '';
    }
  }
}
