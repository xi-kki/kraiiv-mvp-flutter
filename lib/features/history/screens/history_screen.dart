import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/data_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meals = DataService.loggedMeals;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Past Meals',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.headingBrown,
                  ),
                ),
                Text(
                  '${meals.length} total',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textBody.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: meals.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      itemCount: meals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final meal = meals[index];
                        return _buildMealTile(
                          name: meal['name'] ?? 'Unknown',
                          timestamp: meal['timestamp'] ?? '',
                          score: meal['healthScore'] ?? 0,
                          category: meal['category'] ?? 'mixed',
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'No meals logged yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.headingBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging meals to see your history here',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textBody.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/logging'),
            child: const Text('Log your first meal'),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTile({
    required String name,
    required String timestamp,
    required int score,
    required String category,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.warmBrown.withOpacity(0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(category).withOpacity(0.12),
          radius: 22,
          child: Text(
            _getCategoryEmoji(category),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.headingBrown,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          _formatTimestamp(timestamp),
          style: TextStyle(
            color: AppTheme.textBody.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _getScoreColor(score).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$score/10',
            style: TextStyle(
              color: _getScoreColor(score),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'rice_based':
        return '🍚';
      case 'soups_and_swallows':
        return '🥣';
      case 'beans_based':
        return '🫘';
      case 'snacks':
        return '🍿';
      default:
        return '🍽️';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'rice_based':
        return const Color(0xFFD4A017);
      case 'soups_and_swallows':
        return AppTheme.supportiveGreen;
      case 'beans_based':
        return const Color(0xFF8C6A4A);
      case 'snacks':
        return const Color(0xFFCC6633);
      default:
        return AppTheme.warmBrown;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return AppTheme.supportiveGreen;
    if (score >= 5) return const Color(0xFFD4A017);
    return const Color(0xFFCC6633);
  }

  String _formatTimestamp(String isoTimestamp) {
    if (isoTimestamp.isEmpty) return 'Unknown time';
    try {
      final dt = DateTime.parse(isoTimestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';

      // Older than a week — show date
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return 'Unknown time';
    }
  }
}
