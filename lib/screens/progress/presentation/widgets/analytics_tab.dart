import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../models/skill.dart';
import '../../loading/shimmer_loader.dart';
import '../../../../core/animations/entrance_animation.dart';


class AnalyticsTab extends StatefulWidget {
  final List<Skill> skills;

  const AnalyticsTab({super.key, required this.skills});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ─── Computed values ──────────────────────────────────────────────────────

  int get _totalSessions => widget.skills.length;

  String get _practiceTime {
    final mins = widget.skills.fold<int>(0, (acc, s) {
      switch (s.difficultyLevel) {
        case 'Beginner': return acc + 5;
        case 'Advanced': return acc + 20;
        default: return acc + 10;
      }
    });
    if (mins >= 60) return '${(mins / 60).toStringAsFixed(1)}h';
    return '${mins}m';
  }

  String get _bestDay {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (widget.skills.isEmpty) return 'N/A';
    final counts = List<int>.filled(7, 0);
    for (final s in widget.skills) {
      counts[s.lastPracticed.weekday % 7]++;
    }
    return days[counts.indexOf(counts.reduce(math.max))];
  }

  double get _avgMastery {
    if (widget.skills.isEmpty) return 0;
    return widget.skills.fold<double>(0, (a, s) => a + s.mastery) /
        widget.skills.length;
  }

  double get _consistencyScore {
    if (widget.skills.isEmpty) return 0;
    final practiced = widget.skills
        .where((s) =>
            DateTime.now().difference(s.lastPracticed).inDays <= 7)
        .length;
    return (practiced / widget.skills.length).clamp(0.0, 1.0);
  }

  /// Sessions per day of week [0=Sun … 6=Sat]
  List<int> get _sessionsByDay {
    final counts = List<int>.filled(7, 0);
    for (final s in widget.skills) {
      counts[s.lastPracticed.weekday % 7]++;
    }
    return counts;
  }

  /// Skills per category
  Map<String, int> get _categoryDist {
    final map = <String, int>{};
    for (final s in widget.skills) {
      map[s.category] = (map[s.category] ?? 0) + 1;
    }
    return map;
  }

  String get _insightText {
    if (widget.skills.isEmpty) return 'Add skills to see insights.';
    final d = DateTime.now().difference(widget.skills
        .reduce((a, b) => a.lastPracticed.isAfter(b.lastPracticed) ? a : b)
        .lastPracticed).inDays;
    if (d == 0) return 'Great — you practiced today! Your streak is building.';
    if (d <= 2) return 'Based on your activity — keep going, you\'re consistent!';
    return 'It\'s been $d days since last practice. Time to jump back in!';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ── Stats grid ──────────────────────────────────────────────────
          AnimatedEntranceWrapper(
            animationController: _ctrl,
            intervalStart: 0.0,
            intervalEnd: 0.5,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _StatCard(
                  label: 'Total Sessions',
                  value: '$_totalSessions',
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                  controller: _ctrl,
                ),
                _StatCard(
                  label: 'Practice Time',
                  value: _practiceTime,
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  controller: _ctrl,
                ),
                _StatCard(
                  label: 'Best Day',
                  value: _bestDay,
                  icon: Icons.star_rounded,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                  controller: _ctrl,
                ),
                _StatCard(
                  label: 'Avg Mastery',
                  value: _avgMastery.toStringAsFixed(1),
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  controller: _ctrl,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Insight card ────────────────────────────────────────────────
          AnimatedEntranceWrapper(
            animationController: _ctrl,
            intervalStart: 0.15,
            intervalEnd: 0.65,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.12),
                    const Color(0xFF8B5CF6).withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: Color(0xFF6366F1), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _insightText,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF475569),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Consistency score ────────────────────────────────────────────
          AnimatedEntranceWrapper(
            animationController: _ctrl,
            intervalStart: 0.2,
            intervalEnd: 0.7,
            child: _ConsistencyCard(
              score: _consistencyScore,
              isDark: isDark,
              controller: _ctrl,
            ),
          ),

          const SizedBox(height: 20),

          // ── Sessions by day bar chart ────────────────────────────────────
          AnimatedEntranceWrapper(
            animationController: _ctrl,
            intervalStart: 0.3,
            intervalEnd: 0.8,
            child: _BarChartCard(
              sessionsByDay: _sessionsByDay,
              isDark: isDark,
              controller: _ctrl,
            ),
          ),

          const SizedBox(height: 20),

          // ── Category distribution ────────────────────────────────────────
          AnimatedEntranceWrapper(
            animationController: _ctrl,
            intervalStart: 0.4,
            intervalEnd: 0.9,
            child: _CategoryDistCard(
              distribution: _categoryDist,
              isDark: isDark,
              controller: _ctrl,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}



// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final AnimationController controller;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Consistency card ─────────────────────────────────────────────────────────

class _ConsistencyCard extends StatelessWidget {
  final double score;
  final bool isDark;
  final AnimationController controller;

  const _ConsistencyCard({
    required this.score,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).round();
    final color = score >= 0.7
        ? const Color(0xFF10B981)
        : score >= 0.4
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consistency Score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Based on your activity this week',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: score * controller.value,
                minHeight: 8,
                backgroundColor: isDark
                    ? Colors.white12 : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bar chart card ───────────────────────────────────────────────────────────

class _BarChartCard extends StatelessWidget {
  final List<int> sessionsByDay;
  final bool isDark;
  final AnimationController controller;

  const _BarChartCard({
    required this.sessionsByDay,
    required this.isDark,
    required this.controller,
  });

  static const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final maxVal = sessionsByDay.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sessions by Day',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (i) {
                  final count = sessionsByDay[i];
                  final frac = maxVal == 0 ? 0.0 : count / maxVal;
                  final barH =
                      (frac * 110 * controller.value).clamp(4.0, 110.0);
                  final isToday =
                      DateTime.now().weekday % 7 == i;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (count > 0)
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                          ),
                        ),
                      const SizedBox(height: 3),
                      RepaintBoundary(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: barH,
                          width: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isToday
                                  ? [
                                      const Color(0xFF6366F1),
                                      const Color(0xFF8B5CF6),
                                    ]
                                  : count > 0
                                      ? [
                                          const Color(0xFF6366F1)
                                              .withOpacity(0.4),
                                          const Color(0xFF8B5CF6)
                                              .withOpacity(0.4),
                                        ]
                                      : [
                                          isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0),
                                          isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0),
                                        ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dayLabels
                .map((d) => Text(
                      d,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Category distribution card ───────────────────────────────────────────────

class _CategoryDistCard extends StatelessWidget {
  final Map<String, int> distribution;
  final bool isDark;
  final AnimationController controller;

  const _CategoryDistCard({
    required this.distribution,
    required this.isDark,
    required this.controller,
  });

  static const _colors = [
    Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B),
    Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) return const SizedBox.shrink();
    final total = distribution.values.fold(0, (a, b) => a + b);
    final entries = distribution.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill Strength Distribution',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(entries.length, (i) {
            final entry = entries[i];
            final frac = entry.value / total;
            final color = _colors[i % _colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      Text(
                        '${(frac * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  AnimatedBuilder(
                    animation: controller,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: frac * controller.value,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
