import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/data_service.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final Set<String> _selectedOptions = {};

  final List<Map<String, dynamic>> _options = [
    {'label': 'Eat healthier', 'icon': Icons.favorite_rounded},
    {'label': 'Be more consistent', 'icon': Icons.bolt_rounded},
    {'label': 'Improve energy', 'icon': Icons.battery_charging_full_rounded},
  ];

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
              Text(
                'What do you want most right now?',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Pick all that apply',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: AppTheme.textBody.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              ..._options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (_selectedOptions.contains(option['label'])) {
                        _selectedOptions.remove(option['label']);
                      } else {
                        _selectedOptions.add(option['label']);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _selectedOptions.contains(option['label'])
                          ? AppTheme.supportiveGreen.withOpacity(0.1)
                          : AppTheme.surfaceWhite,
                      border: Border.all(
                        color: _selectedOptions.contains(option['label'])
                            ? AppTheme.supportiveGreen
                            : AppTheme.warmBrown.withOpacity(0.2),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _selectedOptions.contains(option['label'])
                                ? AppTheme.supportiveGreen.withOpacity(0.15)
                                : AppTheme.warmBrown.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            option['icon'] as IconData,
                            color: _selectedOptions.contains(option['label'])
                                ? AppTheme.supportiveGreen
                                : AppTheme.warmBrown,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option['label'] as String,
                            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                              color: AppTheme.headingBrown,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (_selectedOptions.contains(option['label']))
                          const Icon(Icons.check_circle, color: AppTheme.supportiveGreen, size: 24)
                        else
                          Icon(Icons.circle_outlined, color: AppTheme.warmBrown.withOpacity(0.3), size: 24),
                      ],
                    ),
                  ),
                ),
              )),
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedOptions.isEmpty
                    ? null
                    : () async {
                        await DataService.setSelectedGoals(_selectedOptions.toList());
                        if (mounted) context.push('/commitment');
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Continue'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
