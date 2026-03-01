import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../models/skill.dart';
import '../../../skill_details/skill_details_screen.dart';
import '../../../../services/skill_service.dart';
import '../../../../core/animations/entrance_animation.dart';
import '../../../../core/animations/press_animation.dart';
import '../../../../core/animations/page_transition.dart';

class PracticeCard extends StatefulWidget {
  final Skill skill;
  final Animation<double> entranceAnimation;
  final double intervalStart;

  const PracticeCard({
    super.key,
    required this.skill,
    required this.entranceAnimation,
    this.intervalStart = 0.0,
  });

  @override
  State<PracticeCard> createState() => _PracticeCardState();
}

class _PracticeCardState extends State<PracticeCard>
    with TickerProviderStateMixin {
  late final AnimationController _tapController;
  late final AnimationController _ringController;
  late final Animation<double> _ringAnimation;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeInOut,
    );
    Future.delayed(
      Duration(milliseconds: (300 + widget.intervalStart * 600).toInt()),
      () {
        if (mounted) _ringController.forward();
      },
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  int _daysSince() =>
      DateTime.now().difference(widget.skill.lastPracticed).inDays;

  String _status() {
    final d = _daysSince();
    if (d >= 10) return 'high';
    if (d >= 5) return 'moderate';
    return 'stable';
  }

  Color _priorityColor(String status) {
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

  String _statusMessage() {
    final d = _daysSince();
    if (d == 0) return 'Practiced today · On track';
    if (d == 1) return 'Due tomorrow · Stay consistent';
    if (d < 5) return 'Not practiced for $d days';
    if (d < 10) return 'Needs attention · $d days gap';
    return 'High decay risk · $d days ago';
  }

  String _reasonText() {
    final d = _daysSince();
    if (d == 0) return 'Great job keeping it up!';
    if (d == 1) return "Don't wait — practice now!";
    if (d < 5) return "You haven't practiced in $d days.";
    return "Recommended — $d days without practice!";
  }

  String _difficultyLabel() => widget.skill.difficultyLevel;

  int _estimatedMinutes() {
    switch (widget.skill.difficultyLevel) {
      case 'Beginner':
        return 5;
      case 'Advanced':
        return 20;
      default:
        return 10;
    }
  }

  Future<void> _markPracticed() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);
    try {
      final updated = widget.skill.copyWith(
        lastPracticed: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await SkillService().updateSkill(widget.skill.id!, updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${widget.skill.name}" marked as practiced! 🎉'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final status = _status();
    final priorityColor = _priorityColor(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mastery = widget.skill.mastery.clamp(0.0, 100.0);

    return AnimatedEntranceWrapper(
      animationController: widget.entranceAnimation as AnimationController,
      intervalStart: widget.intervalStart.clamp(0.0, 0.9),
      intervalEnd: (widget.intervalStart + 0.45).clamp(0.0, 1.0),
      child: AnimatedPressWrapper(
        onTap: () {
          Navigator.push(
            context,
            FadeSlidePageRoute(
              page: SkillDetailsScreen(skill: widget.skill),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(color: priorityColor, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: priorityColor.withOpacity(isDark ? 0.1 : 0.07),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Main row ──────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Progress ring
                    AnimatedBuilder(
                      animation: _ringAnimation,
                      builder: (_, __) => _SkillRing(
                        progress: (mastery / 100.0) * _ringAnimation.value,
                        value: mastery.toInt(),
                        color: priorityColor,
                        isDark: isDark,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _statusMessage(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _difficultyLabel(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_estimatedMinutes()} min',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Badge + Start button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _RiskBadge(
                          color: priorityColor,
                          label: _badgeLabel(status),
                        ),
                        const SizedBox(height: 8),
                        _StartButton(
                          isLoading: _isStarting,
                          onPressed: _markPracticed,
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Reason text (only when not practiced today) ────────
                if (_daysSince() > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '💡 ${_reasonText()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF475569),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Private sub-widgets ──────────────────────────────────────────────────────

class _SkillRing extends StatelessWidget {
  final double progress;
  final int value;
  final Color color;
  final bool isDark;

  const _SkillRing({
    required this.progress,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(60, 60),
      painter: _RingPainter(progress: progress, color: color, isDark: isDark),
      child: SizedBox(
        width: 60,
        height: 60,
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 15,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
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

class _StartButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _StartButton({required this.isLoading, required this.onPressed});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _btnCtrl;

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
  }

  @override
  void dispose() {
    _btnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPressWrapper(
      onTap: widget.onPressed,
      pressedScale: 0.91,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: widget.isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 17),
                  SizedBox(width: 4),
                  Text(
                    'Start',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
