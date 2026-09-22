import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/services/data_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_header.dart';
import '../../../core/widgets/prototype_widgets.dart';

/// Chat-style onboarding matching the prototype:
/// name → dietary preference → health goal → location → daily check-in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalSteps = 5;

  int _step = 1;
  final _nameController = TextEditingController();
  final _otherController = TextEditingController();
  final _locationController = TextEditingController();
  String? _preference;
  String? _goal;
  bool _notificationsChosen = false;
  bool _enableNotifications = true;

  // Page controller for smooth transitions
  late final PageController _pageController;

  static const List<String> _preferences = [
    'No preference',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Halal',
    'Keto / Low-carb',
    'Gluten-free',
  ];

  static const List<String> _goals = [
    'Eat more vegetables',
    'Reduce sugar intake',
    'Cook at home more',
    'Lose weight',
    'Gain muscle',
    'Improve digestion',
    'Boost energy',
    'Eat more local food',
  ];

  static const List<String> _citySuggestions = [
    'Lagos',
    'Abuja',
    'Port Harcourt',
    'Kano',
    'Ibadan',
    'Enugu',
    'Benin City',
    'Kaduna',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _otherController.dispose();
    _locationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String get _userName => _nameController.text.trim();

  String _kliaMessage() {
    switch (_step) {
      case 1:
        return 'Hi! I\'m Klia, your nutrition coach. What should I call you?';
      case 2:
        return 'Nice to meet you, $_userName! Any dietary preferences?';
      case 3:
        return 'Great! What\'s your main health goal right now?';
      case 4:
        return 'Almost there! Which city are you in? This helps me find local markets.';
      case 5:
        return 'Perfect! Want a gentle daily check-in reminder?';
      default:
        return '';
    }
  }

  bool get _stepValid {
    switch (_step) {
      case 1:
        return _userName.length >= 2;
      case 2:
        return _preference != null;
      case 3:
        return _goal != null;
      case 4:
        return _locationController.text.trim().isNotEmpty;
      case 5:
        return _notificationsChosen;
      default:
        return false;
    }
  }

  Future<void> _next() async {
    if (!_stepValid) return;

    if (_step < _totalSteps) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      setState(() => _step++);
    } else {
      await _showAuthPromptAndFinish();
    }
  }

  Future<void> _showAuthPromptAndFinish() async {
    // Show conversational Web 2.5 Google Sign-in sheet from Klia
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildKliaAuthSheet(),
    );
    await _finish(_enableNotifications);
  }

  Widget _buildKliaAuthSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl + 4),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.sparkles,
                color: AppTheme.primary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Save Your Progress',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Hi $_userName! Connect with Google to automatically back up your nutrition plan and KTC rewards across devices.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.mutedForeground,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                final email = '${_userName.toLowerCase().replaceAll(' ', '')}@gmail.com';
                await DataService.signInWithGoogle(email: email, name: _userName);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.foreground,
                elevation: 0,
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4285F4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'G',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue as Guest',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.shieldCheck, size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                'No seed phrases or passwords needed',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _finish(bool allowNotifications) async {
    await DataService.completeOnboarding(
      name: _userName,
      dietaryPreference: _preference!,
      healthGoal: _goal!,
      location: _locationController.text.trim(),
    );

    if (allowNotifications) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleDailyCheckIn();
    }

    await DataService.logIn();

    if (!mounted) return;
    context.go('/home');
  }

  void _selectPreference(String value) {
    setState(() => _preference = value);
  }

  void _selectGoal(String value) {
    setState(() => _goal = value);
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _enableNotifications = value;
      _notificationsChosen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top: Brand header + progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                children: [
                  BrandHeader(scale: 0.85),
                  const SizedBox(height: 20),
                  _PrototypeStepIndicator(
                    currentStep: _step,
                    totalSteps: _totalSteps,
                  ),
                ],
              ),
            ),

            // Middle: Chat bubbles + input
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                  _buildStep5(),
                ],
              ),
            ),

            // Bottom: Action button
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() => _OnboardingStep(
        index: 1,
        icon: LucideIcons.user,
        title: 'Your Name',
        child: TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.foreground,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Xi-kki',
            hintStyle: GoogleFonts.inter(
              color: AppTheme.mutedForeground,
              fontSize: 18,
            ),
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _next(),
        ),
      );

  Widget _buildStep2() => _OnboardingStep(
        index: 2,
        icon: LucideIcons.salad,
        title: 'Dietary Preference',
        child: _PreferenceChips(
          options: _preferences,
          selected: _preference,
          onSelect: _selectPreference,
          allowCustom: true,
          customController: _otherController,
        ),
      );

  Widget _buildStep3() => _OnboardingStep(
        index: 3,
        icon: LucideIcons.target,
        title: 'Health Goal',
        child: _GoalChips(
          options: _goals,
          selected: _goal,
          onSelect: _selectGoal,
        ),
      );

  Widget _buildStep4() => _OnboardingStep(
        index: 4,
        icon: LucideIcons.mapPin,
        title: 'Your City',
        child: _LocationInput(
          controller: _locationController,
          suggestions: _citySuggestions,
        ),
      );

  Widget _buildStep5() => _OnboardingStep(
        index: 5,
        icon: LucideIcons.bell,
        title: 'Daily Check-in',
        child: _NotificationToggle(
          enabled: _enableNotifications,
          onChanged: _toggleNotifications,
        ),
      );

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: PrototypeButton(
        onPressed: _stepValid ? _next : null,
        child: Text(_step == _totalSteps ? 'Get Started' : 'Continue'),
        icon: Icon(
          _step == _totalSteps ? LucideIcons.checkCircle : LucideIcons.arrowRight,
          size: 18,
        ),
      ),
    );
  }
}

/// Step indicator with prototype styling
class _PrototypeStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _PrototypeStepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Step $currentStep of $totalSteps',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (i) {
            final active = i + 1 == currentStep;
            final done = i + 1 < currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: done || active ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: done || active
                    ? AppTheme.primary
                    : AppTheme.border,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Base step widget with Klia bubble and input area
class _OnboardingStep extends StatelessWidget {
  final int index;
  final IconData icon;
  final String title;
  final Widget child;

  const _OnboardingStep({
    required this.index,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step artwork
          _StepArt(icon: icon),
          const SizedBox(height: 24),

          // Klia chat bubble
          _KliaBubble(
            message: _getKliaMessage(index),
          ),
          const SizedBox(height: 24),

          // Section title
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),

          // Input
          child,
        ],
      ),
    );
  }

  String _getKliaMessage(int step) {
    switch (step) {
      case 1:
        return 'Hi! I\'m Klia, your nutrition coach. What should I call you?';
      case 2:
        return 'Nice to meet you! Any dietary preferences?';
      case 3:
        return 'Great! What\'s your main health goal right now?';
      case 4:
        return 'Almost there! Which city are you in? This helps me find local markets.';
      case 5:
        return 'Perfect! Want a gentle daily check-in reminder?';
      default:
        return '';
    }
  }
}

/// Step artwork - prototype style circular emblem
class _StepArt extends StatelessWidget {
  final IconData icon;

  const _StepArt({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withValues(alpha: 0.15),
              AppTheme.primary.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.25),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(icon, size: 56, color: AppTheme.primary),
      ),
    );
  }
}

/// Klia chat bubble matching prototype
class _KliaBubble extends StatelessWidget {
  final String message;

  const _KliaBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.leaf, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 15.5,
                height: 1.55,
                color: AppTheme.foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Preference selection chips
class _PreferenceChips extends StatefulWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final bool allowCustom;
  final TextEditingController? customController;

  const _PreferenceChips({
    required this.options,
    required this.selected,
    required this.onSelect,
    this.allowCustom = false,
    this.customController,
  });

  @override
  State<_PreferenceChips> createState() => _PreferenceChipsState();
}

class _PreferenceChipsState extends State<_PreferenceChips> {
  bool _showCustom = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: widget.options.map((option) {
            final isSelected = widget.selected == option;
            return _PrototypeChip(
              label: option,
              selected: isSelected,
              onTap: () => widget.onSelect(option),
            );
          }).toList(),
        ),
        if (widget.allowCustom) ...[
          const SizedBox(height: 12),
          if (!_showCustom)
            OutlinedButton.icon(
              onPressed: () => setState(() => _showCustom = true),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add custom'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
            )
          else
            TextField(
              controller: widget.customController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter custom preference',
                prefixIcon: const Icon(LucideIcons.edit2, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.check, size: 18),
                  onPressed: () {
                    final value = widget.customController!.text.trim();
                    if (value.isNotEmpty) {
                      widget.onSelect(value);
                    }
                  },
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  widget.onSelect(value.trim());
                }
              },
            ),
        ],
      ],
    );
  }
}

/// Goal selection chips
class _GoalChips extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _GoalChips({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selected == option;
        return _PrototypeChip(
          label: option,
          selected: isSelected,
          onTap: () => onSelect(option),
        );
      }).toList(),
    );
  }
}

/// Prototype chip for selection
class _PrototypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PrototypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary
                : AppTheme.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: selected
                  ? AppTheme.primary
                  : AppTheme.border,
              width: selected ? 2 : 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected
                  ? AppTheme.primaryForeground
                  : AppTheme.foreground,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

/// Location input with suggestions
class _LocationInput extends StatefulWidget {
  final TextEditingController controller;
  final List<String> suggestions;

  const _LocationInput({
    required this.controller,
    required this.suggestions,
  });

  @override
  State<_LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<_LocationInput> {
  bool _showSuggestions = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.foreground,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Lagos',
            hintStyle: GoogleFonts.inter(
              color: AppTheme.mutedForeground,
              fontSize: 18,
            ),
            prefixIcon: const Icon(LucideIcons.mapPin, size: 20),
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => setState(() => _showSuggestions = true),
          onChanged: (_) => setState(() {}),
        ),
        if (_showSuggestions && widget.controller.text.length < 2) ...[
          const SizedBox(height: 16),
          Text(
            'Popular cities',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.suggestions.map((city) {
              return _PrototypeChip(
                label: city,
                selected: false,
                onTap: () {
                  widget.controller.text = city;
                  setState(() => _showSuggestions = false);
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// Notification toggle
class _NotificationToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PrototypeToggleTile(
          icon: LucideIcons.bell,
          iconColor: AppTheme.primary,
          title: 'Daily check-in reminder',
          subtitle: 'Get a gentle nudge to log your meals each evening',
          value: enabled,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.shield, color: AppTheme.primary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your data stays on your device. We never share it.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.mutedForeground,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Prototype toggle tile
class _PrototypeToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrototypeToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: value ? AppTheme.primary : AppTheme.border,
              width: value ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              _PrototypeSwitch(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Prototype switch
class _PrototypeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrototypeSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? AppTheme.primary : AppTheme.border,
          boxShadow: value
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: value ? 22 : 2,
              top: 2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}