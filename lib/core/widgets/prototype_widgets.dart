import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kraiiv/core/theme/app_theme.dart';
/// Prototype hero gradient background - matches the video prototype exactly
class HeroGradient extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const HeroGradient({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(gradient: AppTheme.heroGradient),
      child: child,
    );
  }
}

/// Prototype texture overlay - subtle noise/grain effect
class TextureOverlay extends StatelessWidget {
  final Widget child;
  final double opacity;

  const TextureOverlay({
    super.key,
    required this.child,
    this.opacity = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.transparent,
                    AppTheme.primary.withValues(alpha: opacity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Prototype glow effect - soft colored shadow
class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final double radius;
  final double spread;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowColor,
    this.radius = 30,
    this.spread = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? AppTheme.primary).withValues(alpha: 0.2),
            blurRadius: radius,
            spreadRadius: spread,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Prototype card with double-bezel (nested architecture)
class PrototypeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? radius;
  final bool elevated;
  final VoidCallback? onTap;

  const PrototypeCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.radius,
    this.elevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppTheme.radiusXl;
    final bg = backgroundColor ?? AppTheme.card;
    final border = borderColor ?? AppTheme.border;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: border, width: 1),
        boxShadow: elevated
            ? [
                AppTheme.cardShadow,
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Prototype pill button - 9999 radius, 52h, elevation like Coinbase/Kraken
class PrototypeButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double height;
  final EdgeInsetsGeometry? padding;
  final bool outlined;
  final bool loading;
  final Widget? icon;
  final bool fullWidth;

  const PrototypeButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.height = 52,
    this.padding,
    this.outlined = false,
    this.loading = false,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? (outlined ? Colors.transparent : AppTheme.primary);
    final fg = foregroundColor ?? (outlined ? AppTheme.foreground : AppTheme.primaryForeground);
    final border = borderColor ?? AppTheme.border;

    final button = SizedBox(
      height: height,
      width: fullWidth ? double.infinity : null,
      child: outlined
          ? OutlinedButton(
              onPressed: loading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: fg,
                backgroundColor: bg,
                side: BorderSide(color: border, width: 1.5),
                padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              child: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[icon!, const SizedBox(width: 8)],
                        child,
                      ],
                    ),
            )
          : ElevatedButton(
              onPressed: loading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return bg.withValues(alpha: 0.8);
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return bg.withValues(alpha: 0.9);
                  }
                  return null;
                }),
              ),
              child: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[icon!, const SizedBox(width: 8)],
                        child,
                      ],
                    ),
            ),
    );

    return button;
  }
}

/// Prototype progress indicator with custom colors
class PrototypeProgress extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const PrototypeProgress({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: backgroundColor ?? AppTheme.border,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppTheme.primary),
      ),
    );
  }
}

/// Prototype circular progress
class PrototypeCircularProgress extends StatelessWidget {
  final double value;
  final double strokeWidth;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final Widget? centerChild;

  const PrototypeCircularProgress({
    super.key,
    required this.value,
    this.strokeWidth = 5,
    this.size = 52,
    this.color,
    this.backgroundColor,
    this.centerChild,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value.clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor ?? AppTheme.border,
            valueColor: AlwaysStoppedAnimation<Color>(color ?? AppTheme.primary),
          ),
          if (centerChild != null) centerChild!,
        ],
      ),
    );
  }
}

/// Staggered animation entry - elements cascade in
class StaggeredEntry extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final double beginOpacity;

  const StaggeredEntry({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 600),
    this.beginOffset = const Offset(0, 20),
    this.beginOpacity = 0.0,
  });

  @override
  State<StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fade = Tween<double>(
      begin: widget.beginOpacity,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: widget.child,
      ),
    );
  }
}

/// Prototype section spacing - massive whitespace
class PrototypeSection extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const PrototypeSection({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: child,
    );
  }
}

/// Prototype badge/tag - pill shaped
class PrototypeBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const PrototypeBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: backgroundColor != null
              ? Colors.transparent
              : AppTheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor ?? AppTheme.primaryDark),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: context.labelLarge.copyWith(
              color: textColor ?? AppTheme.primaryDark,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Prototype skeleton loader matching final layout shape
class PrototypeSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const PrototypeSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.muted,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radius),
      ),
      child: const _SkeletonShimmer(),
    );
  }
}

class _SkeletonShimmer extends StatefulWidget {
  const _SkeletonShimmer();

  @override
  State<_SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<_SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.muted,
                AppTheme.muted.withValues(alpha: 0.5),
                AppTheme.muted,
              ],
              stops: [
                (_shimmer.value - 0.3).clamp(0.0, 1.0),
                _shimmer.value.clamp(0.0, 1.0),
                (_shimmer.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Container(color: Colors.white),
        );
      },
    );
  }
}

/// Prototype empty state
class PrototypeEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const PrototypeEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: context.headlineMedium.copyWith(color: context.fg),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: context.bodyMedium.copyWith(color: context.mutedFg),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Prototype error state
class PrototypeErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const PrototypeErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.triangleAlert,
                color: AppTheme.danger,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: context.headlineMedium.copyWith(color: context.fg),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.bodyMedium.copyWith(color: context.mutedFg),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              PrototypeButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}