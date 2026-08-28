import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
///
/// Live preview on mobile via [CameraController] with web fallback.
/// Gallery fallback preserved for all platforms.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final FoodRepository _repository = FoodRepository();

  CameraController? _controller;
  bool _initializing = true;
  bool _hasCamera = false;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _initializing = false;
          _hasCamera = false;
        });
        return;
      }
      final camera = cameras.first;
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
        _hasCamera = true;
      });
    } on CameraException catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _hasCamera = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _hasCamera = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    if (_analyzing) return;
    try {
      XFile? photo;

      if (_controller != null && _controller!.value.isInitialized) {
        try {
          photo = await _controller!.takePicture();
        } on CameraException catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not capture image. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        // No live controller (web without camera, permission denied) — fall
        // back to ImagePicker camera so Start Scanning still works.
        // On web where camera plugin is unavailable this gracefully
        // degrades to the same picker the Gallery button uses.
        if (kIsWeb) {
          photo = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 80,
          );
          if (photo == null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera not available. Try Gallery instead.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (photo == null) return;
        } else {
          photo = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
          );
          if (photo == null) return;
        }
      }

      if (!mounted) return;

      setState(() => _analyzing = true);
      await Future<void>.delayed(const Duration(milliseconds: 900));

      await _repository.loadFoods();
      final detected = await FoodRecognitionService.detect(photo);

      if (!mounted) return;

      final aiHit = detected.isNotEmpty ? detected.first : null;
      final food = aiHit != null
          ? _repository.matchFood(aiHit.name)
          : _repository.matchFood(photo.name);

      setState(() => _analyzing = false);
      if (!mounted) return;
      context.push(
        '/result',
        extra: ScanResultPayload(
          food,
          photo.path,
          aiLabel: aiHit?.name,
          aiConfidence: aiHit?.confidence,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not capture image. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    if (_analyzing) return;
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (photo == null || !mounted) return;

      setState(() => _analyzing = true);
      await Future<void>.delayed(const Duration(milliseconds: 900));

      await _repository.loadFoods();
      final detected = await FoodRecognitionService.detect(photo);

      if (!mounted) return;

      final aiHit = detected.isNotEmpty ? detected.first : null;
      final food = aiHit != null
          ? _repository.matchFood(aiHit.name)
          : _repository.matchFood(photo.name);

      setState(() => _analyzing = false);
      if (!mounted) return;
      context.push(
        '/result',
        extra: ScanResultPayload(
          food,
          photo.path,
          aiLabel: aiHit?.name,
          aiConfidence: aiHit?.confidence,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not pick image. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  const Text(
                    'Point your camera at food...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(child: _buildPreview()),
                  const SizedBox(height: 20),
                  const Text(
                    'Scan your food to get nutritional information '
                    'and know if it\'s local and seasonal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppTheme.textBody,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FoodRecognitionService.apiEnabled
                        ? 'AI detection enabled'
                        : 'Offline detection — no photo leaves your device',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const Spacer(),
                  // Bottom pill buttons — 52h, sage + white, full-width.
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _analyzing ? null : _captureAndAnalyze,
                      icon: const Icon(LucideIcons.scanLine, size: 20),
                      label: const Text('Start Scanning'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _analyzing ? null : _pickFromGallery,
                      icon: const Icon(LucideIcons.image, size: 20),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.textDark,
                        side: const BorderSide(
                          color: AppTheme.border,
                          width: 1.5,
                        ),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Analyzing overlay — covers preview + buttons.
            if (_analyzing)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.72),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Camera / placeholder surface.
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 280,
              height: 280,
              color: Colors.black,
              child: _initializing
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : _hasCamera &&
                          _controller != null &&
                          _controller!.value.isInitialized
                      ? CameraPreview(_controller!)
                      : const Center(
                          child: Icon(
                            LucideIcons.camera,
                            color: AppTheme.primaryGreen,
                            size: 44,
                          ),
                        ),
            ),
          ),
          // Dashed sage overlay — 2px sage #3A5A40, rounded 20.
          const CustomPaint(
            size: Size(280, 280),
            painter: _DashedBorderPainter(
              color: AppTheme.primaryGreen,
              strokeWidth: 2,
              borderRadius: 20,
              dashLength: 10,
              gapLength: 6,
            ),
          ),
          // Inner solid 2px sage border for the "overlay square" spec.
          // Drawn slightly inset so both dashed + solid are visible and
          // match the Figma: outer dashed, inner hairline square.
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.9),
                width: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed rounded-rectangle border — sage #3A5A40, 2px.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double dashLength;
  final double gapLength;

  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);
    final dashed = _dashPath(path, dashLength: dashLength, gapLength: gapLength);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(Path source, {required double dashLength, required double gapLength}) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDash = distance + dashLength;
        dashed.addPath(metric.extractPath(distance, nextDash.clamp(0, metric.length)), Offset.zero);
        distance = nextDash + gapLength;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
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
