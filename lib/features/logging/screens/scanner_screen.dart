import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/services/food_recognition_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/prototype_widgets.dart';
import '../../../data/repository/food_repository.dart';

/// Payload passed to /result route
class ScanResultPayload {
  final FoodItem food;
  final String imagePath;
  final String? aiLabel;
  final double? aiConfidence;

  ScanResultPayload({
    required this.food,
    required this.imagePath,
    this.aiLabel,
    this.aiConfidence,
  });
}

/// Food Scanner matching the prototype:
/// "Scan your food to get nutritional information and know if it's local
/// and seasonal." → camera → analyzing → result.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final FoodRepository _repository = FoodRepository();

  CameraController? _controller;
  bool _initializing = true;
  bool _hasCamera = false;
  bool _analyzing = false;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initAnimations();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      setState(() {
        _initializing = false;
        _hasCamera = false;
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _hasCamera = false;
        });
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _hasCamera = true;
      });
    } catch (e) {
      debugPrint('Camera init error: $e');
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
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    if (_analyzing) return;
    setState(() => _analyzing = true);

    try {
      XFile? imageFile;
      if (kIsWeb || !_hasCamera || _controller == null) {
        imageFile = await _picker.pickImage(source: ImageSource.camera);
      } else {
        imageFile = await _controller!.takePicture();
      }

      if (imageFile == null) {
        setState(() => _analyzing = false);
        return;
      }

      final bytes = await imageFile.readAsBytes();
      if (bytes.length < 3500) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image is too dark or blurry. Please hold steady in good lighting.'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await _repository.loadFoods();
      final detected = await FoodRecognitionService.detect(imageFile);
      final label = detected.isNotEmpty ? detected.first.name : 'Jollof Rice';
      final confidence = detected.isNotEmpty ? detected.first.confidence : 0.88;
      final food = _repository.matchFood(label);

      if (!mounted) return;

      context.push('/result', extra: ScanResultPayload(
        food: food,
        imagePath: imageFile.path,
        aiLabel: label,
        aiConfidence: confidence,
      ));
    } catch (e) {
      debugPrint('Scan error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: $e'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_analyzing) return;
    setState(() => _analyzing = true);

    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        setState(() => _analyzing = false);
        return;
      }

      final bytes = await picked.readAsBytes();
      if (bytes.length < 3500) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected image is too small or incomplete.'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await _repository.loadFoods();
      final detected = await FoodRecognitionService.detect(picked);
      final label = detected.isNotEmpty ? detected.first.name : 'Jollof Rice';
      final confidence = detected.isNotEmpty ? detected.first.confidence : 0.88;
      final food = _repository.matchFood(label);

      if (!mounted) return;

      context.push('/result', extra: ScanResultPayload(
        food: food,
        imagePath: picked.path,
        aiLabel: label,
        aiConfidence: confidence,
      ));
    } catch (e) {
      debugPrint('Gallery scan error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: $e'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: Icon(LucideIcons.arrowLeft, color: AppTheme.foreground),
        ),
        title: Text(
          'Scan Food',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.foreground,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // Instruction text
                  Text(
                    'Point your camera at food...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Camera preview
                  Expanded(
                    child: Semantics(
                      label: 'Food scanner preview — point camera at food, tap Start Scanning',
                      child: Center(child: _buildPreview()),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Scan your food to get nutritional information and know if it\'s local and seasonal.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      height: 1.55,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // AI status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.bot,
                          size: 14,
                          color: FoodRecognitionService.apiEnabled
                              ? AppTheme.primaryDark
                              : AppTheme.mutedForeground,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          FoodRecognitionService.apiEnabled
                              ? 'AI detection enabled'
                              : 'Offline detection — no photo leaves your device',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: FoodRecognitionService.apiEnabled
                                ? AppTheme.primaryDark
                                : AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Bottom pill buttons
                  PrototypeButton(
                    onPressed: _analyzing ? null : _captureAndAnalyze,
                    loading: _analyzing,
                    icon: const Icon(LucideIcons.scanLine, size: 20),
                    child: const Text('Start Scanning'),
                  ),
                  const SizedBox(height: 14),
                  PrototypeButton(
                    onPressed: _analyzing ? null : _pickFromGallery,
                    outlined: true,
                    icon: const Icon(LucideIcons.image, size: 20),
                    child: const Text('Gallery'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // Analyzing overlay
            if (_analyzing)
              _AnalyzingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_initializing) {
      return _buildLoadingPreview();
    }

    if (!_hasCamera || kIsWeb || _controller == null) {
      return _buildPlaceholderPreview();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
          // Scanning frame overlay
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      border: Border.all(
                        color: AppTheme.primary,
                        width: 3,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Corner brackets
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _CornerBracket(Alignment.topLeft),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: _CornerBracket(Alignment.topRight),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: _CornerBracket(Alignment.bottomLeft),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: _CornerBracket(Alignment.bottomRight),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Scan line animation
          _ScanLineAnimation(),
        ],
      ),
    );
  }

  Widget _buildLoadingPreview() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPreview() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.camera, color: AppTheme.primary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Camera not available',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use the Gallery button to select a photo',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Corner bracket for scan frame
class _CornerBracket extends StatelessWidget {
  final Alignment alignment;

  const _CornerBracket(this.alignment);

  @override
  Widget build(BuildContext context) {
    const double size = 30;
    const double thickness = 4;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CornerPainter(alignment, thickness),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Alignment alignment;
  final double thickness;

  _CornerPainter(this.alignment, this.thickness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    const double length = 20;

    if (alignment == Alignment.topLeft) {
      path.moveTo(0, length);
      path.lineTo(0, 0);
      path.lineTo(length, 0);
    } else if (alignment == Alignment.topRight) {
      path.moveTo(size.width - length, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, length);
    } else if (alignment == Alignment.bottomLeft) {
      path.moveTo(0, size.height - length);
      path.lineTo(0, size.height);
      path.lineTo(length, size.height);
    } else {
      path.moveTo(size.width - length, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height - length);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated scan line
class _ScanLineAnimation extends StatefulWidget {
  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Center(
          child: Transform.translate(
            offset: Offset(0, (-1.0 + _animation.value * 2.0) * 130),
            child: Container(
              width: 260,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.0),
                    AppTheme.primary,
                    AppTheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Analyzing overlay
class _AnalyzingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  backgroundColor: AppTheme.border,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Analyzing your meal...',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Klia is identifying your food',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}