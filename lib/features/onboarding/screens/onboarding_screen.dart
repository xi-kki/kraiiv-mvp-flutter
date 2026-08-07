import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_header.dart';

/// Chat-style onboarding matching the prototype:
/// name → dietary preference → health goal → location → daily check-in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _totalSteps = 5;

  int _step = 1;
  final _nameController = TextEditingController();
  final _otherController = TextEditingController();
  final _locationController = TextEditingController();
  String? _preference;
  String? _goal;
  bool _notificationsChosen = false;

  static const List<String> _preferences = [
    'Vegetarian',
    'Vegan',
    'Gluten-free',
    'No restrictions',
  ];
  static const List<String> _goals = [
    'Feel more energized',
    'Eat more mindfully',
    'Improve overall health',
    'Try more local foods',
  ];
  static const List<String> _citySuggestions = [
    'Lagos',
    'Abuja',
    'Ibadan',
    'Port Harcourt',
    'Kano',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _otherController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String get _userName => _nameController.text.trim();

  String _kliaMessage() {
    switch (_step) {
      case 1:
        return 'Hi, I\'m Klia. Let\'s start your intentional eating journey! '
            'What\'s your name?';
      case 2:
        return 'Great to meet you, ${_userName.isEmpty ? 'friend' : _userName.split(' ').first}! '
            'What are your dietary preferences?';
      case 3:
        return 'What\'s your main health goal right now?';
      case 4:
        return 'Where are you located? This helps me suggest local and seasonal foods.';
      default:
        return 'Hey ${_userName.split(' ').first}, can I check in daily to keep you on track?';
    }
  }

  bool get _stepValid {
    switch (_step) {
      case 1:
        return _userName.isNotEmpty;
      case 2:
        return _preference != null;
      case 3:
        return _goal != null;
      case 4:
        return _locationController.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _next() async {
    switch (_step) {
      case 1:
        await DataService.setUserName(_userName);
        setState(() => _step = 2);
        return;
      case 2:
        final pref = _preference == 'Other (specify below:)'
            ? (_otherController.text.trim().isEmpty
                ? 'Other'
                : _otherController.text.trim())
            : _preference!;
        await DataService.setDietaryPreference(pref);
        setState(() => _step = 3);
        return;
      case 3:
        final goal = _goal == 'Other (specify below:)'
            ? (_otherController.text.trim().isEmpty
                ? 'Other'
                : _otherController.text.trim())
            : _goal!;
        await DataService.setHealthGoal(goal);
        setState(() => _step = 4);
        return;
      case 4:
        await DataService.setLocation(_locationController.text.trim());
        setState(() => _step = 5);
        return;
      default:
        await _finish(true);
    }
  }

  Future<void> _finish(bool allowNotifications) async {
    if (_notificationsChosen) return;
    _notificationsChosen = true;

    await DataService.setNotificationsEnabled(allowNotifications);
    if (allowNotifications && !kIsWeb) {
      await NotificationService.scheduleStandardReminders();
    }
    await DataService.setOnboardingComplete();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 8),
              child: BrandHeader(scale: 0.85),
            ),
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKliaBubble(),
                    const SizedBox(height: 16),
                    ..._buildStepInput(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            'Step $_step of $_totalSteps',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (i) {
              final active = i + 1 == _step;
              final done = i + 1 < _step;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: done || active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: done || active
                      ? AppTheme.primaryGreen
                      : AppTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildKliaBubble() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.leaf, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              _kliaMessage(),
              style: const TextStyle(
                fontSize: 15.5,
                height: 1.5,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStepInput() {
    switch (_step) {
      case 1:
        return [
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: Icon(LucideIcons.user, color: AppTheme.textMuted),
            ),
            onSubmitted: (_) => _stepValid ? _next() : null,
          ),
        ];
      case 2:
        return [
          _buildSelectField(
            value: _preference,
            hint: 'Select an option',
            onTap: () => _openPicker(
              options: [..._preferences, 'Other (specify below:)'],
              selected: _preference,
              onSelect: (v) => setState(() => _preference = v),
            ),
          ),
          if (_preference == 'Other (specify below:)') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otherController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Specify below'),
            ),
          ],
        ];
      case 3:
        return [
          _buildSelectField(
            value: _goal,
            hint: 'Select an option',
            onTap: () => _openPicker(
              options: [..._goals, 'Other (specify below:)'],
              selected: _goal,
              onSelect: (v) => setState(() => _goal = v),
            ),
          ),
          if (_goal == 'Other (specify below:)') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otherController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Specify below'),
            ),
          ],
        ];
      case 4:
        return [
          TextField(
            controller: _locationController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Enter your city',
              prefixIcon: Icon(LucideIcons.mapPin, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _citySuggestions.map((city) {
              final selected = _locationController.text == city;
              return ChoiceChip(
                label: Text(city),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppTheme.primaryGreen,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
                side: const BorderSide(color: AppTheme.border),
                onSelected: (_) {
                  setState(() => _locationController.text = city);
                },
              );
            }).toList(),
          ),
        ];
      default:
        return [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.bell, color: AppTheme.gold),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enable notifications for quick nudges that will help '
                    'maintain your intentional eating habits.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppTheme.textBody,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
    }
  }

  Widget _buildSelectField({
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.chevronDown,
                color: AppTheme.textMuted, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      value != null ? FontWeight.w600 : FontWeight.w400,
                  color:
                      value != null ? AppTheme.textDark : AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker({
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Select an option',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            ...options.map((option) {
              final isSelected = option == selected;
              return ListTile(
                title: Text(
                  option,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: isSelected
                    ? const Icon(LucideIcons.checkCircle,
                        color: AppTheme.primaryGreen)
                    : null,
                onTap: () {
                  onSelect(option);
                  Navigator.pop(sheetContext);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: _step == _totalSteps
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _finish(false),
                    child: const Text('Maybe Later'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _finish(true),
                    icon: const Icon(LucideIcons.bell, size: 18),
                    label: const Text('Allow'),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                if (_step > 1)
                  IconButton(
                    onPressed: () => setState(() => _step -= 1),
                    icon: const Icon(LucideIcons.arrowLeft),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _stepValid ? _next : null,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(LucideIcons.chevronRight, size: 18),
                    label: const Text('Next'),
                  ),
                ),
              ],
            ),
    );
  }
}
