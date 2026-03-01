import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../models/skill.dart';
import '../../../../core/animations/entrance_animation.dart';
import '../../../../core/animations/press_animation.dart';

class SkillCardWidget extends StatefulWidget {
  final Skill skill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Animation<double> entranceAnimation;
  final double intervalStart;

  const SkillCardWidget({
    super.key,
    required this.skill,
    required this.onEdit,
    required this.onDelete,
    required this.entranceAnimation,
    this.intervalStart = 0.0,
  });

  @override
  State<SkillCardWidget> createState() => _SkillCardWidgetState();
}

class _SkillCardWidgetState extends State<SkillCardWidget>
    with TickerProviderStateMixin {
  late final AnimationController _tapCtrl;
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _ringAnim =
        CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut);
    Future.delayed(
      Duration(milliseconds: (250 + widget.intervalStart * 500).toInt()),
      () {
        if (mounted) _ringCtrl.forward();
      },
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  int _daysSince() =>
      DateTime.now().difference(widget.skill.lastPracticed).inDays;

  String _riskStatus() {
    final d = _daysSince();
    if (d >= 10) return 'high';
    if (d >= 5) return 'moderate';
    return 'stable';
  }

  Color _riskColor(String status) {
    switch (status) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'moderate':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _riskLabel(String status) {
    switch (status) {
      case 'high':
        return 'High Risk';
      case 'moderate':
        return 'Moderate';
      default:
        return 'Stable';
    }
  }

  /// Human-friendly "last practiced" line
  String _activityLine() {
    final d = _daysSince();
    if (d == 0) return 'Practiced today';
    if (d == 1) return 'Due tomorrow';
    if (d < 7) return 'Not practiced for $d days';
    if (d < 30) return '${(d / 7).floor()} week${(d / 7).floor() > 1 ? 's' : ''} ago';
    return '${(d / 30).floor()} month${(d / 30).floor() > 1 ? 's' : ''} ago';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final status = _riskStatus();
    final riskColor = _riskColor(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mastery = widget.skill.mastery.clamp(0.0, 100.0);

    final start = widget.intervalStart.clamp(0.0, 0.9);
    final end = (widget.intervalStart + 0.45).clamp(0.0, 1.0);

    return AnimatedEntranceWrapper(
      animationController: widget.entranceAnimation as AnimationController,
      intervalStart: start,
      intervalEnd: end,
      child: AnimatedPressWrapper(
        onTap: () {}, // No default card tap
        child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border(
                  left: BorderSide(color: riskColor, width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: riskColor.withOpacity(isDark ? 0.08 : 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Animated mastery ring ──────────────────────────
                    AnimatedBuilder(
                      animation: _ringAnim,
                      builder: (_, child) => _MasteryRing(
                        progress: (mastery / 100) * _ringAnim.value,
                        value: mastery.toInt(),
                        color: riskColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // ── Center info ────────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.skill.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                widget.skill.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF6366F1)
                                      .withOpacity(0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '  ·  ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white30
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  _activityLine(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          _RiskBadge(
                            color: riskColor,
                            label: _riskLabel(status),
                          ),
                        ],
                      ),
                    ),

                    // ── Action icons ────────────────────────────────────
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionIcon(
                          icon: Icons.edit_outlined,
                          color: const Color(0xFF6366F1),
                          isDark: isDark,
                          onTap: widget.onEdit,
                          tooltip: 'Edit',
                        ),
                        const SizedBox(height: 8),
                        _ActionIcon(
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFEF4444),
                          isDark: isDark,
                          onTap: widget.onDelete,
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _MasteryRing extends StatelessWidget {
  final double progress;
  final int value;
  final Color color;
  final bool isDark;

  const _MasteryRing({
    required this.progress,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(58, 58),
      painter: _RingPainter(progress: progress, color: color, isDark: isDark),
      child: SizedBox(
        width: 58,
        height: 58,
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - sw) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isDark
            ? Colors.white.withOpacity(0.08)
            : const Color(0xFFE2E8F0)
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = sw
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _RiskBadge extends StatelessWidget {
  final Color color;
  final String label;

  const _RiskBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AnimatedPressWrapper(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
