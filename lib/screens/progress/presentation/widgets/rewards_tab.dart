import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../models/skill.dart';
import '../../../../core/animations/entrance_animation.dart';

class RewardsTab extends StatefulWidget {
  final List<Skill> skills;

  const RewardsTab({super.key, required this.skills});

  @override
  State<RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<RewardsTab> with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _xpCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _xpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _ringCtrl.forward();
        _xpCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _ringCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  // ─── XP / Level logic ────────────────────────────────────────────────────

  int get _totalXP {
    return widget.skills.fold<int>(0, (acc, s) {
      int base = 10;
      if (DateTime.now().difference(s.lastPracticed).inDays == 0) base += 5;
      return acc + base + (s.mastery / 10).round();
    });
  }

  int get _level {
    int xp = _totalXP;
    int level = 1;
    int threshold = 500;
    while (xp >= threshold) {
      xp -= threshold;
      level++;
      threshold += 200;
    }
    return level;
  }

  int get _xpCurrentLevel {
    int xp = _totalXP;
    int threshold = 500;
    while (xp >= threshold) {
      xp -= threshold;
      threshold += 200;
    }
    return xp;
  }

  int get _xpNextLevel {
    int level = 1;
    int threshold = 500;
    int xp = _totalXP;
    while (xp >= threshold) {
      xp -= threshold;
      threshold += 200;
      level++;
    }
    return threshold;
  }

  int get _currentStreak {
    if (widget.skills.isEmpty) return 0;
    final sorted = [...widget.skills]
      ..sort((a, b) => b.lastPracticed.compareTo(a.lastPracticed));
    int streak = 0;
    DateTime check = DateTime.now();
    for (final s in sorted) {
      final diff = check.difference(s.lastPracticed).inDays;
      if (diff <= 1) {
        streak++;
        check = s.lastPracticed;
      } else {
        break;
      }
    }
    return streak;
  }

  // ─── Badges ───────────────────────────────────────────────────────────────

  List<_Badge> get _badges => [
    _Badge(
      name: 'First Step',
      desc: 'Complete your first practice session',
      icon: '🎯',
      unlocked: widget.skills.isNotEmpty,
    ),
    _Badge(
      name: 'On Fire',
      desc: 'Maintain a 3-day streak',
      icon: '🔥',
      unlocked: _currentStreak >= 3,
    ),
    _Badge(
      name: 'Polymath',
      desc: 'Track 5+ different skills',
      icon: '🧠',
      unlocked: widget.skills.length >= 5,
    ),
    _Badge(
      name: 'Expert',
      desc: 'Reach 80%+ mastery in any skill',
      icon: '⭐',
      unlocked: widget.skills.any((s) => s.mastery >= 80),
    ),
    _Badge(
      name: 'Consistent',
      desc: 'Practice every day for a week',
      icon: '📅',
      unlocked: _currentStreak >= 7,
    ),
    _Badge(
      name: 'Deep Diver',
      desc: 'Add an Advanced difficulty skill',
      icon: '🏆',
      unlocked: widget.skills.any((s) => s.difficultyLevel == 'Advanced'),
    ),
  ];

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badges = _badges;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final badgeExtent = textScale > 1.0 ? 198.0 : 186.0;
    final xpFrac = _xpNextLevel > 0
        ? (_xpCurrentLevel / _xpNextLevel).clamp(0.0, 1.0)
        : 0.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ── Level card ──────────────────────────────────────────────────
          AnimatedEntranceWrapper(
            animationController: _entranceCtrl,
            intervalStart: 0.0,
            intervalEnd: 0.6,
            child: _LevelCard(
              level: _level,
              xpCurrent: _xpCurrentLevel,
              xpNext: _xpNextLevel,
              totalXP: _totalXP,
              xpFrac: xpFrac,
              ringCtrl: _ringCtrl,
              isDark: isDark,
            ),
          ),

          const SizedBox(height: 16),

          // ── Streak / XP mini stats ───────────────────────────────────────
          AnimatedEntranceWrapper(
            animationController: _entranceCtrl,
            intervalStart: 0.15,
            intervalEnd: 0.7,
            child: Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Current Streak',
                    value: '$_currentStreak',
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: 'Total XP',
                    value: '$_totalXP',
                    icon: Icons.star_rounded,
                    color: const Color(0xFF6366F1),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: 'Skills',
                    value: '${widget.skills.length}',
                    icon: Icons.school_outlined,
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Badges ───────────────────────────────────────────────────────
          AnimatedEntranceWrapper(
            animationController: _entranceCtrl,
            intervalStart: 0.25,
            intervalEnd: 0.8,
            child: Text(
              'Badges',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Badge grid
          AnimatedEntranceWrapper(
            animationController: _entranceCtrl,
            intervalStart: 0.3,
            intervalEnd: 0.9,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: badgeExtent,
              ),
              itemCount: badges.length,
              itemBuilder: (ctx, i) => _BadgeCard(
                badge: badges[i],
                isDark: isDark,
                delay: Duration(milliseconds: 100 * i),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Level card ───────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final int level;
  final int xpCurrent;
  final int xpNext;
  final int totalXP;
  final double xpFrac;
  final AnimationController ringCtrl;
  final bool isDark;

  const _LevelCard({
    required this.level,
    required this.xpCurrent,
    required this.xpNext,
    required this.totalXP,
    required this.xpFrac,
    required this.ringCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ring
          AnimatedBuilder(
            animation: ringCtrl,
            builder: (_, __) => _XPRing(
              level: level,
              progress:
                  xpFrac *
                  CurvedAnimation(
                    parent: ringCtrl,
                    curve: Curves.easeInOut,
                  ).value,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$xpCurrent / $xpNext XP to next level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: $totalXP XP earned',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _XPRing extends StatelessWidget {
  final int level;
  final double progress;

  const _XPRing({required this.level, required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(110, 110),
      painter: _RingPainter(progress: progress),
      child: SizedBox(
        width: 110,
        height: 110,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$level',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const Text(
                'Level',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - sw) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.2)
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
          ..color = Colors.white
          ..strokeWidth = sw
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Mini stat ────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Badge model ──────────────────────────────────────────────────────────────

class _Badge {
  final String name;
  final String desc;
  final String icon;
  final bool unlocked;

  const _Badge({
    required this.name,
    required this.desc,
    required this.icon,
    required this.unlocked,
  });
}

// ─── Badge card ───────────────────────────────────────────────────────────────

class _BadgeCard extends StatefulWidget {
  final _Badge badge;
  final bool isDark;
  final Duration delay;

  const _BadgeCard({
    required this.badge,
    required this.isDark,
    required this.delay,
  });

  @override
  State<_BadgeCard> createState() => _BadgeCardState();
}

class _BadgeCardState extends State<_BadgeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.badge.unlocked;
    final isDark = widget.isDark;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: unlocked
              ? Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  width: 1.5,
                )
              : null,
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  widget.badge.icon,
                  style: TextStyle(
                    fontSize: 32,
                    color: unlocked ? null : Colors.black.withOpacity(0),
                  ),
                ),
                if (!unlocked)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black45
                          : Colors.grey.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                // Text behind for sizing
                Opacity(
                  opacity: unlocked ? 1.0 : 0.0,
                  child: Text(
                    widget.badge.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.badge.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: unlocked
                    ? (isDark ? Colors.white : const Color(0xFF1E293B))
                    : (isDark ? Colors.white30 : const Color(0xFFCBD5E1)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.badge.desc,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.8,
                color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
