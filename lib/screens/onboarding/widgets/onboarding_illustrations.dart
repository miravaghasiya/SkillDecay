import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── Page 1: Pulsing logo with orbiting skill icons ────────────────────────

class Screen1Illustration extends StatefulWidget {
  const Screen1Illustration({super.key});

  @override
  State<Screen1Illustration> createState() => _Screen1IllustrationState();
}

class _Screen1IllustrationState extends State<Screen1Illustration>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _orbit;
  late final AnimationController _float;

  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseGlow;
  late final Animation<double> _floatY;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _orbit = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    _float = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.94, end: 1.06).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    _pulseGlow = Tween<double>(begin: 0.4, end: 0.9).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    _floatY = Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: _float, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    _orbit.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _orbit, _float]),
      builder: (context, _) {
        return SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow ring
              Container(
                width: 160 + 20 * _pulseGlow.value,
                height: 160 + 20 * _pulseGlow.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1)
                          .withOpacity(0.18 * _pulseGlow.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Centre logo
              Transform.translate(
                offset: Offset(0, _floatY.value),
                child: ScaleTransition(
                  scale: _pulseScale,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1)
                              .withOpacity(0.5 * _pulseGlow.value),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        size: 52, color: Colors.white),
                  ),
                ),
              ),
              // Orbiting icons
              ..._orbitingIcons(),
            ],
          ),
        );
      },
    );
  }

  final _orbitData = const [
    (icon: Icons.menu_book_rounded, color: Color(0xFF10B981), offset: 0.0),
    (icon: Icons.code_rounded, color: Color(0xFFF59E0B), offset: 0.33),
    (icon: Icons.music_note_rounded, color: Color(0xFF0EA5E9), offset: 0.66),
  ];

  List<Widget> _orbitingIcons() {
    const radius = 110.0;
    return _orbitData.map((d) {
      final angle =
          (_orbit.value + d.offset) * 2 * math.pi;
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);
      return Transform.translate(
        offset: Offset(x, y),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: d.color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: d.color.withOpacity(0.4), width: 1.5),
          ),
          child: Icon(d.icon, color: d.color, size: 18),
        ),
      );
    }).toList();
  }
}

// ─── Page 2: Rising animated chart bars ────────────────────────────────────

class Screen2Illustration extends StatefulWidget {
  const Screen2Illustration({super.key});

  @override
  State<Screen2Illustration> createState() => _Screen2IllustrationState();
}

class _Screen2IllustrationState extends State<Screen2Illustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bars = [
      (fraction: 0.40, color: Color(0xFF10B981), delay: 0.0),
      (fraction: 0.65, color: Color(0xFF6366F1), delay: 0.1),
      (fraction: 0.55, color: Color(0xFFF59E0B), delay: 0.2),
      (fraction: 0.80, color: Color(0xFF8B5CF6), delay: 0.15),
      (fraction: 0.95, color: Color(0xFF0EA5E9), delay: 0.05),
    ];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return SizedBox(
          width: 260,
          height: 200,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('AI Tracking',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Bars
                SizedBox(
                  height: 130,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: bars.map((b) {
                      final t = math.max(
                          0.0,
                          math.min(
                              1.0, (_ctrl.value - b.delay) / (1.0 - b.delay)));
                      final eased = Curves.easeOutCubic.transform(t);
                      final height = 130 * b.fraction * (0.6 + 0.4 * eased);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 38,
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  b.color.withOpacity(0.5),
                                  b.color,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // X-axis labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('M',
                        style: TextStyle(fontSize: 10, color: Colors.white54)),
                    Text('T',
                        style: TextStyle(fontSize: 10, color: Colors.white54)),
                    Text('W',
                        style: TextStyle(fontSize: 10, color: Colors.white54)),
                    Text('T',
                        style: TextStyle(fontSize: 10, color: Colors.white54)),
                    Text('F',
                        style: TextStyle(fontSize: 10, color: Colors.white54)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Page 3: Streak fire + checklist ──────────────────────────────────────

class Screen3Illustration extends StatefulWidget {
  const Screen3Illustration({super.key});

  @override
  State<Screen3Illustration> createState() => _Screen3IllustrationState();
}

class _Screen3IllustrationState extends State<Screen3Illustration>
    with TickerProviderStateMixin {
  late final AnimationController _flame;
  late final AnimationController _check;
  late final AnimationController _float;

  late final Animation<double> _flameScale;
  late final Animation<double> _floatY;

  // staggered check animations
  late List<Animation<double>> _checkAnims;

  @override
  void initState() {
    super.initState();

    _flame = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);

    _check = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _check.repeat(period: const Duration(seconds: 3));

    _float = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    _flameScale = Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _flame, curve: Curves.easeInOut));

    _floatY = Tween<double>(begin: -6, end: 6).animate(
        CurvedAnimation(parent: _float, curve: Curves.easeInOut));

    _checkAnims = List.generate(3, (i) {
      final start = i * 0.28;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _check,
          curve: Interval(start, start + 0.25, curve: Curves.elasticOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _flame.dispose();
    _check.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      'Practice Flutter daily',
      'Review Spanish vocab',
      'Piano scales – 15 min',
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([_flame, _check, _float]),
      builder: (context, _) {
        return SizedBox(
          width: 260,
          height: 240,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Flame streak counter
              Transform.translate(
                offset: Offset(0, _floatY.value),
                child: ScaleTransition(
                  scale: _flameScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withOpacity(0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.local_fire_department_rounded,
                            size: 42, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text('7 day streak',
                          style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Checklist
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(items.length, (i) {
                    final v = _checkAnims[i].value;
                    return Opacity(
                      opacity: v.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(20 * (1 - v), 0),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF6366F1).withOpacity(0.25),
                                width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 13),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  items[i],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
