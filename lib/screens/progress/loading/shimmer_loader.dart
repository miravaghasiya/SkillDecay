import 'package:flutter/material.dart';

/// A single pulsing shimmer placeholder rectangle used for loading states.
class ShimmerLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 10,
  });

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1E293B),
                    Color.lerp(
                      const Color(0xFF1E293B),
                      const Color(0xFF334155),
                      _anim.value,
                    )!,
                    const Color(0xFF1E293B),
                  ]
                : [
                    const Color(0xFFE2E8F0),
                    Color.lerp(
                      const Color(0xFFE2E8F0),
                      const Color(0xFFF1F5F9),
                      _anim.value,
                    )!,
                    const Color(0xFFE2E8F0),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Reusable skeleton card — a rounded container with shimmer lines inside.
class ShimmerCard extends StatelessWidget {
  final double height;

  const ShimmerCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTiny = constraints.maxHeight <= 52;
          final isCompact = constraints.maxHeight <= 74;

          if (isTiny) {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoader(width: 84, height: 10),
                SizedBox(height: 6),
                ShimmerLoader(height: 8),
              ],
            );
          }

          if (isCompact) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoader(width: 80, height: 11),
                ShimmerLoader(
                  height: 18,
                  width: MediaQuery.of(context).size.width * 0.35,
                ),
                const ShimmerLoader(height: 9),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const ShimmerLoader(width: 80, height: 12),
              const SizedBox(height: 8),
              ShimmerLoader(
                height: 24,
                width: MediaQuery.of(context).size.width * 0.4,
              ),
              const SizedBox(height: 8),
              const ShimmerLoader(height: 10),
            ],
          );
        },
      ),
    );
  }
}

/// Grid of shimmer cards (2 columns).
class ShimmerGrid extends StatelessWidget {
  final int count;

  const ShimmerGrid({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: count,
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            ShimmerLoader(width: 60, height: 10),
            ShimmerLoader(height: 28, width: 40),
            ShimmerLoader(height: 9),
          ],
        ),
      ),
    );
  }
}

/// Bar chart skeleton
class ShimmerChart extends StatelessWidget {
  const ShimmerChart({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heights = [80.0, 40.0, 60.0, 110.0, 30.0, 70.0, 50.0];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoader(width: 120, height: 14),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: heights
                  .map(
                    (h) => ShimmerLoader(width: 28, height: h, borderRadius: 6),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              7,
              (_) => const ShimmerLoader(width: 24, height: 8),
            ),
          ),
        ],
      ),
    );
  }
}
