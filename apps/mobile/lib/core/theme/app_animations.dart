import 'package:flutter/material.dart';

/// Centralized Motion Tokens & Curves for Tiga Angkatan / AIsistenku.
///
/// Designed to follow UI/UX Pro Max Motion & Animation Standards:
/// 1. Durations:
///    - quick: 180ms (micro-interactions, icon scale, chips)
///    - tabSwitch: 220ms (smooth crossfade between tabs)
///    - normal: 280ms (card expansion, list reordering)
///    - modalEnter: 380ms (bottom sheets, dialogs)
///    - modalExit: 240ms (exit faster than enter)
///    - aiPortalEnter: 440ms (hero AI portal expansion)
///    - aiPortalExit: 280ms (hero AI portal dismissal)
/// 2. Curves:
///    - springEnter: Curves.easeOutCubic
///    - springExit: Curves.easeInQuad
///    - elasticEnter: Curves.easeOutBack
///    - fluidDecel: Cubic(0.16, 1.0, 0.3, 1.0)
class AppAnimations {
  AppAnimations._();

  // Durations
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration tabSwitch = Duration(milliseconds: 220);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration modalEnter = Duration(milliseconds: 380);
  static const Duration modalExit = Duration(milliseconds: 240);
  static const Duration aiPortalEnter = Duration(milliseconds: 440);
  static const Duration aiPortalExit = Duration(milliseconds: 280);

  // Easing Curves
  static const Curve springEnter = Curves.easeOutCubic;
  static const Curve springExit = Curves.easeInQuad;
  static const Curve elasticEnter = Curves.easeOutBack;
  static const Curve fluidDecel = Cubic(0.16, 1.0, 0.3, 1.0);
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
}

/// Custom [PageTransitionsBuilder] providing silky smooth slide-and-crossfade
/// motion with subtle scale deceleration for all standard route pushes.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Forward curve (enter)
    final primaryCurve = CurvedAnimation(
      parent: animation,
      curve: AppAnimations.springEnter,
      reverseCurve: AppAnimations.springExit,
    );

    // Slide in slightly from right (8% translation) instead of jarring full 100%
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.08, 0.0),
      end: Offset.zero,
    ).animate(primaryCurve);

    // Fade transition
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(primaryCurve);

    // Subtle scale
    final scaleAnimation = Tween<double>(
      begin: 0.985,
      end: 1.0,
    ).animate(primaryCurve);

    // Secondary route animation (when another screen is pushed on top of this one)
    final secondaryCurve = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInQuad,
      reverseCurve: Curves.easeOutCubic,
    );
    final secondaryFade = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(secondaryCurve);
    final secondaryScale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(secondaryCurve);

    return FadeTransition(
      opacity: secondaryFade,
      child: ScaleTransition(
        scale: secondaryScale,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
