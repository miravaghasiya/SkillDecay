import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../models/skill.dart';
import '../../../practice/presentation/screens/practice_screen.dart';
import '../../../../core/animations/entrance_animation.dart';
import '../../../../core/animations/press_animation.dart';

class RecommendationCardWidget extends StatefulWidget {
  final Skill skill;
  final Animation<double> entranceAnimation;
  final double intervalStart;
  final ValueChanged<Skill>? onTapSkill;

  const RecommendationCardWidget({
    super.key,
    required this.skill,
    required this.entranceAnimation,
    this.intervalStart = 0.55,
    this.onTapSkill,
  });

  @override
  State<RecommendationCardWidget> createState() =>
      _RecommendationCardWidgetState();
}

class _RecommendationCardWidgetState extends State<RecommendationCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  int _daysSince() {
    return DateTime.now().difference(widget.skill.lastPracticed).inDays;
  }

  String _status() {
    final d = _daysSince();
    if (d >= 10) return 'high';
    if (d >= 5) return 'moderate';
    return 'stable';
  }

  String _reasonText() {
    final d = _daysSince();
    if (d == 0) return 'Practiced today — keep it up!';
    if (d == 1) return 'Practiced yesterday — great streak!';
    if (d < 5) return 'Practiced $d days ago — stay consistent!';
    if (d < 10) return '$d days without practice — needs attention!';
    return '$d days inactive — high decay risk!';
  }

  Color _badgeColor(String status) {
    switch (status) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'moderate':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _badgeLabel(String status) {
    switch (status) {
      case 'high':
        return 'High Risk';
      case 'moderate':
        return 'Moderate';
      default:
        return 'Stable';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _status();
    final badgeColor = _badgeColor(status);
    final mastery = widget.skill.mastery.clamp(0.0, 100.0);

    return AnimatedEntranceWrapper(
      animationController: widget.entranceAnimation as AnimationController,
      intervalStart: widget.intervalStart,
      intervalEnd: (widget.intervalStart + 0.45).clamp(0.0, 1.0),
      child: AnimatedPressWrapper(
        onTap: () {
          if (widget.onTapSkill != null) {
            widget.onTapSkill!(widget.skill);
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PracticeScreen(highlightSkillId: widget.skill.id),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.055),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Skill strength ring
              CustomPaint(
                size: const Size(56, 56),
                painter: _SkillRingPainter(
                  progress: mastery / 100.0,
                  color: badgeColor,
                  isDark: isDark,
                ),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: Text(
                      '${mastery.toInt()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Skill info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.skill.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _reasonText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Risk badge + arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: badgeColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _badgeLabel(status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? Colors.white38 : const Color(0xFFCBD5E1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _SkillRingPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.08)
          : const Color(0xFFE2E8F0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SkillRingPainter old) =>
      old.progress != progress || old.color != color;
}
