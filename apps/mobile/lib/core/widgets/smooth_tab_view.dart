import 'package:flutter/material.dart';

/// Seamless animated tab view that preserves state for all tabs while providing
/// buttery smooth cross-fade and micro-scale transition when switching.
class SmoothTabTransitionView extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;
  final Duration duration;

  const SmoothTabTransitionView({
    super.key,
    required this.currentIndex,
    required this.children,
    this.duration = const Duration(milliseconds: 220),
  });

  @override
  State<SmoothTabTransitionView> createState() =>
      _SmoothTabTransitionViewState();
}

class _SmoothTabTransitionViewState extends State<SmoothTabTransitionView>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<double>> _scaleAnimations;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        vsync: this,
        duration: widget.duration,
        value: index == widget.currentIndex ? 1.0 : 0.0,
      ),
    );

    _fadeAnimations = _controllers
        .map((c) => CurvedAnimation(
              parent: c,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInQuad,
            ))
        .toList();

    _scaleAnimations = _controllers
        .map((c) => Tween<double>(begin: 0.985, end: 1.0).animate(
              CurvedAnimation(
                parent: c,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInQuad,
              ),
            ))
        .toList();
  }

  @override
  void didUpdateWidget(SmoothTabTransitionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      final prev = _previousIndex;
      final next = widget.currentIndex;

      if (prev >= 0 && prev < _controllers.length) {
        _controllers[prev].reverse();
      }
      if (next >= 0 && next < _controllers.length) {
        _controllers[next].forward();
      }

      _previousIndex = next;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (index) {
        final isActive = index == widget.currentIndex;
        final isAnimating = _controllers[index].isAnimating ||
            _controllers[index].value > 0.0;

        return Offstage(
          offstage: !isActive && !isAnimating,
          child: IgnorePointer(
            ignoring: !isActive,
            child: TickerMode(
              enabled: isActive || isAnimating,
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: ScaleTransition(
                  scale: _scaleAnimations[index],
                  alignment: Alignment.center,
                  child: widget.children[index],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
