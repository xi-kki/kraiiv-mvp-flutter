import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';

class MealLoggingScreen extends StatefulWidget {
  const MealLoggingScreen({super.key});

  @override
  State<MealLoggingScreen> createState() => _MealLoggingScreenState();
}

class _MealLoggingScreenState extends State<MealLoggingScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isThinking = false;

  void _submitMeal(String mealContext) {
    if (mealContext.trim().isEmpty) return;

    setState(() => _isThinking = true);

    // Simulate thinking/parsing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isThinking = false);
        context.pushReplacement('/feedback', extra: mealContext);
      }
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (photo != null) {
        // For MVP, we simulate recognizing the food from the photo
        // In production, this would send to an AI vision API
        _showQuickOptions();
      }
    } catch (e) {
      // Camera permission denied or error — fall back to quick options
      _showQuickOptions();
    }
  }

  void _showQuickOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.warmBrown.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'What did you eat?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.headingBrown,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Quick pick from recent meals:',
                style: TextStyle(fontSize: 14, color: AppTheme.textBody),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickChip('Jollof rice and chicken'),
                  _quickChip('Eba and egusi soup'),
                  _quickChip('Moi moi and plantain'),
                  _quickChip('Beans and fried plantain'),
                  _quickChip('Ugwu soup and fufu'),
                  _quickChip('Suya'),
                  _quickChip('Pepper soup'),
                  _quickChip('Indomie noodles'),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 14)),
      backgroundColor: AppTheme.surfaceWhite,
      side: BorderSide(color: AppTheme.warmBrown.withOpacity(0.2)),
      onPressed: () {
        Navigator.pop(context);
        _submitMeal(label);
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Log Meal'),
      ),
      body: _isThinking
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: AppTheme.supportiveGreen,
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Analyzing nutrients...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.supportiveGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Klia is figuring out what\'s on your plate',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textBody.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Camera Option
                    InkWell(
                      onTap: _takePhoto,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.warmBrown.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.warmBrown.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.camera_alt_rounded, size: 48, color: AppTheme.warmBrown),
                            SizedBox(height: 12),
                            Text(
                              'Take a photo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.warmBrown,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Snap your plate and Klia will do the rest',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: AppTheme.warmBrown, thickness: 0.5)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR TYPE IT IN',
                              style: TextStyle(
                                color: AppTheme.textBody,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppTheme.warmBrown, thickness: 0.5)),
                        ],
                      ),
                    ),

                    // Text Input Option
                    TextField(
                      controller: _textController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'e.g. Jollof rice and chicken, Eba and egusi...',
                        hintStyle: TextStyle(
                          color: AppTheme.textBody.withOpacity(0.4),
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppTheme.supportiveGreen),
                          onPressed: () => _submitMeal(_textController.text),
                        ),
                      ),
                      onSubmitted: _submitMeal,
                    ),
                    const Spacer(),

                    // Quick suggestions
                    Text(
                      'Popular meals:',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textBody.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _suggestionChip('Jollof rice'),
                        _suggestionChip('Egusi soup'),
                        _suggestionChip('Moi moi'),
                        _suggestionChip('Suya'),
                        _suggestionChip('Pepper soup'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _suggestionChip(String label) {
    return InkWell(
      onTap: () {
        _textController.text = label;
        _submitMeal(label);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.supportiveGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.supportiveGreen.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.supportiveGreen,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
