import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Special Hero Transition Route for AISistenku.
///
/// Designed to feel distinct, premium, and alive:
/// 1. Originates directly from the bottom-center AI hero button.
/// 2. Deep forest emerald vignette backdrop with animated Gaussian blur.
/// 3. Elastic bottom-to-top morphing sheet with corner radius interpolation.
/// 4. Luminous ambient AI aura bar on top.
/// 5. Exit-faster-than-enter timing (420ms in, 260ms out) for zero-lag responsiveness.
class AiAssistantPortalRoute extends PageRouteBuilder<void> {
  final WidgetBuilder builder;

  AiAssistantPortalRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          opaque: false,
          barrierDismissible: true,
          barrierLabel: 'Tutup AISistenku',
          barrierColor: Colors.transparent,
          fullscreenDialog: true,
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final isReversing = animation.status == AnimationStatus.reverse;

            // Deceleration spring curve for entry, swift cubic for exit
            final primaryCurve = CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.14, 1.0, 0.32, 1.0),
              reverseCurve: Curves.easeInCubic,
            );

            // Backdrop blur progress
            final blurVal = (primaryCurve.value * 10.0).clamp(0.0, 10.0);
            final scrimOpacity =
                (primaryCurve.value * 0.65).clamp(0.0, 0.65);

            // Vertical translation from bottom
            final slideAnim = Tween<Offset>(
              begin: const Offset(0.0, 0.40),
              end: Offset.zero,
            ).animate(primaryCurve);

            // Scale expansion from bottom center
            final scaleAnim = Tween<double>(
              begin: 0.86,
              end: 1.0,
            ).animate(primaryCurve);

            // Corner radius interpolation (from pill/card to full sheet)
            final cornerRadius =
                lerpDouble(36.0, 16.0, primaryCurve.value) ?? 24.0;

            // Fade in
            final fadeAnim = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: isReversing
                  ? const Interval(0.2, 1.0, curve: Curves.linear)
                  : const Interval(0.0, 0.5, curve: Curves.easeOut),
            ));

            return Stack(
              children: [
                // ── 1. Animated Emerald Vignette & Frosted Scrim ───
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: blurVal,
                        sigmaY: blurVal,
                      ),
                      child: Container(
                        color: const Color(0xFF022C22)
                            .withValues(alpha: scrimOpacity),
                      ),
                    ),
                  ),
                ),

                // ── 2. Ascending Morphing Portal Sheet ─────────────
                SlideTransition(
                  position: slideAnim,
                  child: ScaleTransition(
                    scale: scaleAnim,
                    alignment: const Alignment(0.0, 0.95),
                    child: FadeTransition(
                      opacity: fadeAnim,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(cornerRadius),
                        ),
                        child: Stack(
                          children: [
                            // The actual AI Assistant Screen
                            child,

                            // Top Luminous AI Aurora Edge (Entry Accent)
                            if (animation.value < 0.98)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 3.5,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0x0014B8A6),
                                        AppColors.mintAccent,
                                        Color(0xFF34D399),
                                        AppColors.mintAccent,
                                        Color(0x0014B8A6),
                                      ],
                                      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
}
