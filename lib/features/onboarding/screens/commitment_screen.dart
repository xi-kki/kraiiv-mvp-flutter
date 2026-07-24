import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/data_service.dart';

class CommitmentScreen extends StatefulWidget {
  const CommitmentScreen({super.key});

  @override
  State<CommitmentScreen> createState() => _CommitmentScreenState();
}

class _CommitmentScreenState extends State<CommitmentScreen> {
  String? _subtitleMessage;
  bool _isLoading = false;

  void _handleDecision(bool accepted) async {
    setState(() => _isLoading = true);

    if (accepted) {
      await DataService.setCommitmentAccepted();
    }
    await DataService.setOnboardingComplete();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Emoji
              const Center(
                child: Text('🤝', style: TextStyle(fontSize: 64)),
              ),
              const SizedBox(height: 24),
              Text(
                'Can you commit to logging your meals daily for the next 7 days?',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_subtitleMessage != null)
                Text(
                  _subtitleMessage!,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: AppTheme.supportiveGreen,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                const SizedBox(height: 24),
              const Spacer(),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: AppTheme.supportiveGreen),
                )
              else ...[
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _subtitleMessage = "Great choice! Let's start with your next meal 🎉";
                    });
                    _handleDecision(true);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text("Yes, I'm in!"),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _subtitleMessage = "No pressure — start small and see how it feels 🌱";
                    });
                    _handleDecision(false);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text('Not sure yet'),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
