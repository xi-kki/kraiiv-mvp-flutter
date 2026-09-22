import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/services/data_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_header.dart';
import '../../../core/widgets/prototype_widgets.dart';

/// Log In screen — local mock auth (no backend).
/// Matches prototype styling with Playfair Display headlines.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.text = DataService.userName;
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _valid {
    return _name.text.trim().length >= 2 && _password.text.trim().length >= 3;
  }

  Future<void> _logIn() async {
    final name = _name.text.trim();
    final pass = _password.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Name must be at least 2 characters');
      return;
    }
    if (pass.length < 3) {
      setState(() => _error = 'Password must be at least 3 characters');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // If onboarding is complete, we treat login as session restore.
    // We allow any matching name (case-insensitive) or create if first login.
    final stored = DataService.userName.trim();
    if (stored.isNotEmpty && stored.toLowerCase() != name.toLowerCase()) {
      setState(() {
        _loading = false;
        _error = 'Name doesn\'t match your profile. Try "${DataService.userName}".';
      });
      return;
    }

    if (!DataService.isOnboardingComplete) {
      // Should not happen (router guards), but handle gracefully.
      await DataService.completeOnboarding(
        name: name,
        dietaryPreference: 'No preference',
        healthGoal: 'Eat more vegetables',
        location: 'Lagos',
      );
    } else if (stored.isEmpty || stored.toLowerCase() != name.toLowerCase()) {
      // First login after onboarding: update stored name.
      await DataService.setUserName(name);
    }

    await DataService.logIn();

    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand header
              const BrandHeader(scale: 0.85),
              const SizedBox(height: 32),

              // Welcome illustration
              _WelcomeIllustration(),
              const SizedBox(height: 32),

              // Title
              Text(
                'Welcome back',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.foreground,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Log in to continue your intentional eating journey',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppTheme.mutedForeground,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Form card
              _LoginForm(
                nameController: _name,
                passwordController: _password,
                obscure: _obscure,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                error: _error,
                loading: _loading,
                onChanged: (_) => setState(() => _error = null),
                onSubmit: _valid && !_loading ? _logIn : null,
              ),
              const SizedBox(height: 20),

              // Create account
              PrototypeButton(
                onPressed: _loading ? null : () => context.go('/onboarding'),
                outlined: true,
                child: const Text('Create account'),
                icon: const Icon(LucideIcons.userPlus, size: 18),
              ),
              const SizedBox(height: 16),

              // Forgot password
              Center(
                child: TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password reset is local demo — just enter any password to log in',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.inter(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // Tip
              if (DataService.isOnboardingComplete && DataService.userName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      'Tip: you last logged in as ${DataService.userName}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Welcome illustration matching prototype
class _WelcomeIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(LucideIcons.leaf, size: 72, color: AppTheme.primary),
    );
  }
}

/// Login form with prototype styling
class _LoginForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? error;
  final bool loading;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;

  const _LoginForm({
    required this.nameController,
    required this.passwordController,
    required this.obscure,
    required this.onToggleObscure,
    this.error,
    this.loading = false,
    required this.onChanged,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name field
          _PrototypeTextField(
            controller: nameController,
            label: 'Your name',
            hint: 'e.g. Xi-kki',
            prefixIcon: LucideIcons.user,
            textCapitalization: TextCapitalization.words,
            onChanged: onChanged,
            onSubmitted: (_) => onSubmit?.call(),
          ),
          const SizedBox(height: 16),

          // Password field
          _PrototypeTextField(
            controller: passwordController,
            label: 'Password',
            hint: 'Any password (local demo)',
            prefixIcon: LucideIcons.lock,
            obscureText: obscure,
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 18,
                color: AppTheme.mutedForeground,
              ),
            ),
            onChanged: onChanged,
            onSubmitted: (_) => onSubmit?.call(),
          ),

          // Error
          if (error != null) ...[
            const SizedBox(height: 12),
            _PrototypeErrorBanner(message: error!),
          ],

          const SizedBox(height: 20),

          // Submit button
          PrototypeButton(
            onPressed: onSubmit,
            loading: loading,
            child: const Text('Log In'),
            icon: const Icon(LucideIcons.logIn, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Prototype text field
class _PrototypeTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  const _PrototypeTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
    required this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppTheme.foreground,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(
          color: AppTheme.mutedForeground,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppTheme.mutedForeground.withValues(alpha: 0.7),
          fontSize: 16,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: AppTheme.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(prefixIcon, size: 20, color: AppTheme.mutedForeground),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide(color: AppTheme.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide(color: AppTheme.danger, width: 1.5),
        ),
      ),
    );
  }
}

/// Prototype error banner
class _PrototypeErrorBanner extends StatelessWidget {
  final String message;

  const _PrototypeErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.circleAlert, color: AppTheme.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}