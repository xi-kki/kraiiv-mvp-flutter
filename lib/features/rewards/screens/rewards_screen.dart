import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/services/airtime_service.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/stablesats_service.dart';
import '../../../core/services/zebedee_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/prototype_widgets.dart';

/// Rewards Hub matching the prototype:
/// balance + available rewards to redeem (powered by Bitcoin Sats, Stablesats & automated Airtime).
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  static final _rewards = [
    {
      'name': 'Withdraw Sats (ZBD)',
      'cost': 100,
      'icon': LucideIcons.zap,
      'desc': 'Instant payout to any Lightning address',
      'color': AppTheme.gold,
    },
    {
      'name': '₦500 Airtime',
      'cost': 500,
      'icon': LucideIcons.smartphone,
      'desc': 'Instant top-up for any Nigerian network',
      'color': AppTheme.primary,
    },
    {
      'name': '₦1,000 Data Bundle',
      'cost': 1000,
      'icon': LucideIcons.wifi,
      'desc': '1GB valid for 30 days on any network',
      'color': AppTheme.gold,
    },
    {
      'name': 'Local Market Voucher',
      'cost': 800,
      'icon': LucideIcons.shoppingBag,
      'desc': '₦1,000 off at partner markets',
      'color': AppTheme.primaryDark,
    },
    {
      'name': 'Health Check-up',
      'cost': 2000,
      'icon': LucideIcons.heartPulse,
      'desc': 'Basic vitals check at partner clinic',
      'color': AppTheme.orange,
    },
    {
      'name': 'Recipe E-book',
      'cost': 300,
      'icon': LucideIcons.bookOpen,
      'desc': '50+ Nigerian healthy recipes',
      'color': AppTheme.blue,
    },
    {
      'name': 'Farm Tour Pass',
      'cost': 1500,
      'icon': LucideIcons.tractor,
      'desc': 'Visit a local organic farm',
      'color': AppTheme.primary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final balance = DataService.ktcBalance;
    final weekly = DataService.weeklyMealCounts;
    final totalMeals = weekly.fold<int>(0, (a, b) => a + b);
    final streak = DataService.currentStreak;

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
                      'Rewards Hub',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Balance Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _buildBalanceCard(balance),
              ),
            ),

            // Stats Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildMiniGoalStats(totalMeals, streak),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Available Rewards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(LucideIcons.gift, color: AppTheme.gold, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Available Rewards',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Rewards Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildRewardCard(_rewards[index], balance),
                  childCount: _rewards.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Redemption History
            if (DataService.redemptionHistory.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(LucideIcons.history, color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Redemption History',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildRedemptionRow(
                        DataService.redemptionHistory[index]),
                    childCount: DataService.redemptionHistory.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(int balance) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.coins, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'KTC Balance',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '1 KTC = 1 Sat',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$balance KTC',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($balance Sats ≈ ₦${ZebedeeService.satsToNaira(balance)})',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PrototypeButton(
                  onPressed: () => context.go('/home'),
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  child: const Text('Earn KTC'),
                  icon: const Icon(LucideIcons.sparkles, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrototypeButton(
                  onPressed: _copyCode,
                  outlined: true,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  borderColor: Colors.white.withValues(alpha: 0.5),
                  child: const Text('Member Code'),
                  icon: const Icon(LucideIcons.copy, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGoalStats(int totalMeals, int streak) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '$balance',
            label: 'KTC Balance',
            icon: LucideIcons.coins,
            iconColor: AppTheme.gold,
          ),
        ),
        Expanded(
          child: _StatTile(
            value: '$totalMeals',
            label: 'Meals Logged',
            icon: LucideIcons.utensils,
            iconColor: AppTheme.primary,
          ),
        ),
        Expanded(
          child: _StatTile(
            value: '$streak',
            label: 'Day Streak',
            icon: LucideIcons.flame,
            iconColor: AppTheme.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCard(Map<String, Object> reward, int balance) {
    final cost = reward['cost'] as int;
    final name = reward['name'] as String;
    final desc = reward['desc'] as String;
    final icon = reward['icon'] as IconData;
    final color = reward['color'] as Color;
    final canAfford = balance >= cost;

    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppTheme.mutedForeground,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.coins, color: AppTheme.gold, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$cost KTC',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrototypeButton(
                onPressed: canAfford ? () => _redeem(reward) : null,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                child: Text(canAfford ? 'Redeem' : 'Locked'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionRow(Map<String, dynamic> entry) {
    final date = entry['date'] as DateTime;
    final rewardName = entry['reward'] as String;
    final cost = entry['cost'] as int;
    final code = entry['code'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PrototypeCard(
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
              child: Icon(LucideIcons.gift, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rewardName,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_dayLabel(date)} · ${cost > 0 ? '-$cost KTC' : '$cost KTC'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            if (code != null)
              TextButton(
                onPressed: () => _copyToClipboard(code),
                child: Text(
                  'Code: $code',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _dayLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }


  void _copyCode() {
    // Generate a demo code
    final code = 'KRAIIV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _copyToClipboard(code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code copied: $code'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _redeem(Map<String, Object> reward) async {
    final cost = reward['cost'] as int;
    final name = reward['name'] as String;

    if (name.contains('Airtime')) {
      await _redeemAirtime(cost);
      return;
    }

    if (name.contains('Withdraw Sats')) {
      await _redeemSatsToLightning(cost);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        title: Text('Redeem $name?', style: GoogleFonts.playfairDisplay(color: AppTheme.foreground)),
        content: Text(
          'This will cost $cost KTC ($cost Sats). Are you sure?',
          style: GoogleFonts.inter(color: AppTheme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.mutedForeground)),
          ),
          PrototypeButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final code = 'KRAIIV-${name.replaceAll(' ', '').toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    await DataService.redeemReward(name, cost, code);

    if (!mounted) return;
    setState(() {});

    _showVoucherDialog(name, code, cost);
  }

  Future<void> _redeemAirtime(int cost) async {
    final phoneController = TextEditingController();
    String selectedNetwork = 'MTN';
    const networks = ['MTN', 'Airtel', 'Glo', '9mobile'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
          title: Text('Redeem ₦500 Airtime', style: GoogleFonts.playfairDisplay(color: AppTheme.foreground)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cost: $cost KTC ($cost Sats). Select your Nigerian network and phone number:',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedForeground),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: networks.map((net) {
                  final isSelected = selectedNetwork == net;
                  return ChoiceChip(
                    label: Text(net),
                    selected: isSelected,
                    selectedColor: AppTheme.primary,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.foreground,
                    ),
                    onSelected: (_) => setModalState(() => selectedNetwork = net),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                onChanged: (val) {
                  final detected = AirtimeService.detectNetwork(val);
                  setModalState(() => selectedNetwork = detected);
                },
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g. 0803 123 4567',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.mutedForeground)),
            ),
            PrototypeButton(
              onPressed: () {
                if (phoneController.text.trim().length >= 10) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Send Airtime'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final phone = phoneController.text.trim();
      final airtimeRes = await AirtimeService.purchaseAirtime(
        phone: phone,
        amountNaira: 500,
        preferredNetwork: selectedNetwork,
      );

      await DataService.redeemReward('₦500 Airtime ($selectedNetwork)', cost, airtimeRes.reference);
      if (!mounted) return;
      setState(() {});

      _showVoucherDialog(
        '₦500 Airtime Sent ($selectedNetwork)',
        airtimeRes.reference,
        cost,
        customSubtitle: airtimeRes.message,
      );
    }
  }

  Future<void> _redeemSatsToLightning(int cost) async {
    final lnController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        title: Text('Withdraw to Lightning', style: GoogleFonts.playfairDisplay(color: AppTheme.foreground)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Withdraw $cost Sats to any Lightning Address (Blink/Stablesats, ZBD, Bitnob):',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.mutedForeground),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lnController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Lightning Address',
                hintText: 'e.g. name@blink.sv, name@zbd.gg or name@bitnob.io',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.mutedForeground)),
          ),
          PrototypeButton(
            onPressed: () {
              if (lnController.text.contains('@')) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (result == true) {
      final address = lnController.text.trim();
      // Supports Stablesats/Blink if configured, else Zebedee
      final paySuccess = StablesatsService.isConfigured
          ? (await StablesatsService.sendLightningPayment(lnAddress: address, amountSats: cost)).success
          : (await ZebedeeService.sendToLightningAddress(lnAddress: address, sats: cost)).success;

      if (paySuccess) {
        final txId = 'LN-${DateTime.now().millisecondsSinceEpoch}';
        await DataService.redeemReward('Lightning Sats Payout', cost, txId);
        if (!mounted) return;
        setState(() {});

        _showVoucherDialog(
          '$cost Sats Sent!',
          txId,
          cost,
          customSubtitle: 'Instant settlement to $address via Lightning Network!',
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed. Please verify the Lightning Address.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  void _showVoucherDialog(String rewardName, String code, int cost, {String? customSubtitle}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl + 4)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.checkCircle, color: AppTheme.primary, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'Reward Redeemed!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                customSubtitle ?? rewardName,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppTheme.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Text(
                      'Voucher Code',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      code,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _copyToClipboard(code),
                      icon: const Icon(LucideIcons.copy, size: 16),
                      label: const Text('Copy Code'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrototypeButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppTheme.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}