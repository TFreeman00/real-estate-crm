import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A reusable Glassmorphism container that renders a frosted-glass effect using
/// [BackdropFilter] with a 15-unit Gaussian blur, a semi-transparent white
/// fill, and a linear-gradient border.
///
/// Usage:
/// ```dart
/// GlassContainer(
///   child: Text('Hello, Glass!'),
/// )
/// ```
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final double blurSigma;
  final double opacity;
  final Gradient? borderGradient;
  final double borderWidth;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.blurSigma = 15.0,
    this.opacity = 0.2,
    this.borderGradient,
    this.borderWidth = 1.2,
  });

  Gradient get _defaultBorderGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x88FFFFFF),
          Color(0x22FFFFFF),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      // Gradient border via a decorated outer container.
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: borderGradient ?? _defaultBorderGradient,
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: ClipRRect(
          borderRadius: borderRadius.subtract(
            BorderRadius.all(Radius.circular(borderWidth)),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: AppColors.glassWhite.withOpacity(opacity),
                borderRadius: borderRadius.subtract(
                  BorderRadius.all(Radius.circular(borderWidth)),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
