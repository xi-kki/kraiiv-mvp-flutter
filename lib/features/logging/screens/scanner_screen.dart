import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/services/food_recognition_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repository/food_repository.dart';

/// Food Scanner matching the prototype:
/// "Scan your food to get nutritional information and know if it's local
/// and seasonal." → camera → analyzing → result.
///
/// Detection order:
///   1. Kraiiv Food Recognition API (Nigerian Food Lens model) when running
///   2. Local keyword matcher (offline fallback)
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _picker = ImagePicker();
  final _repository = FoodRepository();
  bool _scanning = false;
  bool _analyzing = false;

  Future<void> _startScanning() async {
    if (_scanning) return;
    setState(() => _scanning = true);

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (!mounted || photo == null) {
        setState(() => _scanning = false);
        return;
      }

      // Analyzing state (matches the prototype's "Analyzing your meal").
      setState(() {
        _scanning = false;
        _analyzing = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));

      await _repository.loadFoods();
      final detected = await FoodRecognitionService.detect(photo);

      if (!mounted) return;

      // Prefer the top AI detection; fall back to filename keyword match.
      final aiHit = detected.isNotEmpty ? detected.first : null;
      final food = aiHit != null
          ? _repository.matchFood(aiHit.name)
          : _repository.matchFood(photo.name);

      setState(() => _analyzing = false);
      context.push(
        '/result',
        extra: ScanResultPayload(
          food,
          photo.path,
          aiLabel: aiHit?.name,
          aiConfidence: aiHit?.confidence,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _analyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the camera. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(LucideIcons.arrowLeft),
              ),
              const Spacer(),
              if (_analyzing)
                const Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(strokeWidth: 5),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Analyzing your meal...',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Klia is identifying your food',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              else
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          color: AppTheme.primaryGreen,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Food Scanner',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Scan your food to get nutritional information '
                        'and know if it\'s local and seasonal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.5,
                          color: AppTheme.textBody,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        FoodRecognitionService.apiEnabled
                            ? 'AI detection enabled'
                            : 'Offline detection — no photo leaves your device',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              _scanning
                  ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 14),
                          Text(
                            'Opening camera...',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    )
                  : _analyzing
                      ? const SizedBox(height: 54)
                      : ElevatedButton.icon(
                          onPressed: _startScanning,
                          icon: const Icon(LucideIcons.scanLine, size: 20),
                          label: const Text('Start Scanning'),
                        ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Payload carried from the scanner to the result screen.
class ScanResultPayload {
  final FoodItem food;
  final String imagePath;
  final String? aiLabel;
  final double? aiConfidence;

  ScanResultPayload(
    this.food,
    this.imagePath, {
    this.aiLabel,
    this.aiConfidence,
  });
}
