import 'package:flutter/material.dart';

/// Wraps elements to provide a staggered fade-in and slide-up entrance animation.
/// Uses a parent controller and an [intervalStart] bounded by [intervalEnd]
/// to time its appearance perfectly.
class AnimatedEntranceWrapper extends StatelessWidget {
  final Widget child;
  final AnimationController animationController;
  final double intervalStart;
  final double intervalEnd;
  final double yOffset;

  const AnimatedEntranceWrapper({
    super.key,
    required this.child,
    required this.animationController,
    this.intervalStart = 0.0,
    this.intervalEnd = 1.0,
    this.yOffset = 20.0, // Default slight slide-up distance
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        // Build the specific curved animation subset for this widget
        final curvedAnimation = CurvedAnimation(
          parent: animationController,
          curve: Interval(
            intervalStart,
            intervalEnd,
            curve: Curves.easeOutCubic,
          ),
        );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);

        final slideAnimation = Tween<Offset>(
          begin: Offset(0, yOffset / MediaQuery.of(context).size.height), // Relative proportional y
          end: Offset.zero,
        ).animate(curvedAnimation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
