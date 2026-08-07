import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/services/data_service.dart';
import '../../../core/theme/app_theme.dart';

/// Rewards Hub matching the prototype:
/// balance + Connect Wallet, then available rewards to redeem.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  static const _rewards = [
    {
      'icon': 'spa',
      'title': 'Spa Treatment Voucher',
      'price': '\$25',
      'description':
          'A relaxing treatment redeemable at participating locations.',
    },
    {
      'icon': 'dessert',
      'title': 'Gourmet Dessert Box',
      'price': '\$15',
      'description': 'Premium chocolate truffles and sweet treats, delivered.',
    },
    {
      'icon': 'market',
      'title': 'Local Market Voucher',
      'price': '\$10',
      'description': 'Towards fresh produce at your local market.',
    },
    {
      'icon': 'cash',
      'title': 'Convert KTC to Cash',
      'price': 'KTC',
      'description': 'Convert your KTC balance directly to cash anytime.',
    },
  ];

  IconData _iconFor(String name) {
    switch (name) {
      case 'spa':
        return LucideIcons.sparkles;
      case 'dessert':
        return LucideIcons.cake;
      case 'market':
        return LucideIcons.shoppingBasket;
      default:
        return LucideIcons.repeat;
    }
  }

  void _connectWallet() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Connect Wallet'),
        content: const Text(
          'Wallet connection is coming soon. Your KTC balance stays safe '
          'in the meantime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _redeem(String title) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(LucideIcons.gift,
            color: AppTheme.primaryGreen, size: 32),
        title: const Text('Redeem'),
        content: Text(
          'Redemption for "$title" is coming soon. Keep earning KTC!',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = DataService.ktcBalance;
    final history = DataService.tokenHistory;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: const Text('Rewards Hub'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'Earn KTC tokens and redeem them anytime',
              style: TextStyle(fontSize: 14.5, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            _buildBalanceCard(balance),
            const SizedBox(height: 24),
            const Text(
              'Available Rewards',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ..._rewards.map((reward) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRewardCard(reward),
                )),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Earning History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ...history.take(8).map((entry) => _buildHistoryRow(entry)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(int balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(LucideIcons.coins, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your balance',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '$balance KTC',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _connectWallet,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.5),
              ),
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.wallet, size: 15),
                SizedBox(width: 6),
                Text('Connect Wallet'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(Map<String, String> reward) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _iconFor(reward['icon']!),
              color: AppTheme.primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward['title']!,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reward['description']!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                reward['price']!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryGreenDark,
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => _redeem(reward['title']!),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: const Text('Redeem'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(Map<String, dynamic> entry) {
    final amount = entry['amount'] as int? ?? 0;
    final reason = entry['reason'] as String? ?? 'KTC earned';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.coins,
              color: AppTheme.primaryGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '+$amount KTC',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryGreenDark,
            ),
          ),
        ],
      ),
    );
  }
}
