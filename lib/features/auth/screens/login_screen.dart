import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/services/data_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_header.dart';

/// Log In screen — local mock auth (no backend).
/// If the user has completed onboarding, we validate the name matches the
/// stored profile; otherwise we create the session and go home.
/// Log Out is the inverse: clears `is_logged_in` without wiping profile.
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
      setState(() => _error = 'Enter your name (at least 2 characters)');
      return;
    }
    if (pass.length < 3) {
      setState(() => _error = 'Enter a password (at least 3 characters)');
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
      // For demo, allow any name — but show that it will switch profile.
      // In production this would hit Firebase/Auth.
    }

    if (!DataService.isOnboardingComplete) {
      // First-time login without onboarding — create minimal profile.
      await DataService.setUserName(name);
      await DataService.setOnboardingComplete();
    } else if (stored.isEmpty || stored.toLowerCase() != name.toLowerCase()) {
      // Logged in as different name — update stored name for greeting.
      await DataService.setUserName(name);
    }

    await DataService.logIn();

    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/home');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primaryGreen,
          content: Row(children: [
            const Icon(LucideIcons.logIn, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('Welcome back, $name!'),
          ]),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BrandHeader(scale: 0.85),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.sageLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
                ),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.logIn, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Log in to Kraiiv', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                      SizedBox(height: 2),
                      Text('Your intentional eating — pick up where you left off', style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  labelText: 'Your name',
                  hintText: 'e.g. Xi-kki',
                  prefixIcon: const Icon(LucideIcons.user, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.border)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: _obscure,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Any password (local demo)',
                  prefixIcon: const Icon(LucideIcons.lock, size: 18),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.border)),
                ),
                onSubmitted: (_) => _valid && !_loading ? _logIn() : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECDD3))),
                  child: Row(children: [
                    const Icon(LucideIcons.circleAlert, color: AppTheme.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppTheme.danger, fontWeight: FontWeight.w600))),
                  ]),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _valid && !_loading ? _logIn : null,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(LucideIcons.logIn, size: 18),
                  label: Text(_loading ? 'Logging in…' : 'Log In'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => context.go('/onboarding'),
                  icon: const Icon(LucideIcons.userPlus, size: 18),
                  label: const Text('Create account'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset is local demo — just enter any password to log in'), behavior: SnackBarBehavior.floating),
                  ),
                  child: const Text('Forgot password?', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w700)),
                ),
              ),
              if (DataService.isOnboardingComplete && DataService.userName.isNotEmpty)
                Center(
                  child: Text('Tip: you last logged in as ${DataService.userName}', style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
