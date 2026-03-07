import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/skill_service.dart';
import '../../../../models/skill.dart';
import '../widgets/practice_header.dart';
import '../widgets/practice_card.dart';
import '../widgets/empty_state.dart';
import '../../../../core/animations/entrance_animation.dart';

class PracticeScreen extends StatefulWidget {
  final VoidCallback? onAddSkill;
  final String? highlightSkillId;
  const PracticeScreen({super.key, this.onAddSkill, this.highlightSkillId});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _staggerCtrl.forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  /// Sort skills: highest risk (most days since practice) first.
  /// If a highlightSkillId is provided, it floats to the very top.
  List<Skill> _sortByUrgency(List<Skill> skills) {
    final sorted = List<Skill>.from(skills);
    sorted.sort((a, b) {
      if (widget.highlightSkillId != null) {
        if (a.id == widget.highlightSkillId && b.id != widget.highlightSkillId)
          return -1;
        if (b.id == widget.highlightSkillId && a.id != widget.highlightSkillId)
          return 1;
      }
      final da = DateTime.now().difference(a.lastPracticed).inDays;
      final db = DateTime.now().difference(b.lastPracticed).inDays;
      return db.compareTo(da);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Skill>>(
              stream: SkillService().getUserSkills(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint(
                    'PracticeScreen Firestore Error: ${snapshot.error}',
                  );
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 56,
                            color: Colors.red.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Access Denied or Connection Error',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We could not load your practice data. Please verify your permissions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allSkills = snapshot.data ?? [];
                final sortedSkills = _sortByUrgency(allSkills);

                if (sortedSkills.isEmpty) {
                  return Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                        child: PracticeHeader(controller: _staggerCtrl),
                      ),
                      Expanded(
                        child: PracticeEmptyState(
                          onAddSkill: widget.onAddSkill ?? () {},
                        ),
                      ),
                    ],
                  );
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Header ───────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                        child: PracticeHeader(controller: _staggerCtrl),
                      ),
                    ),

                    // ── Priority summary chips ────────────────────────────
                    SliverToBoxAdapter(
                      child: AnimatedEntranceWrapper(
                        animationController: _staggerCtrl,
                        intervalStart: 0.1,
                        intervalEnd: 0.5,
                        child: _PrioritySummaryChips(skills: sortedSkills),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // ── Practice cards ────────────────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return PracticeCard(
                            skill: sortedSkills[index],
                            entranceAnimation: _staggerCtrl,
                            isHighlighted:
                                sortedSkills[index].id ==
                                widget.highlightSkillId,
                            intervalStart: (0.2 + index * 0.07).clamp(0.0, 0.9),
                          );
                        }, childCount: sortedSkills.length),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                );
              },
            ),
    );
  }
}

// ─── Priority summary row ─────────────────────────────────────────────────────

class _PrioritySummaryChips extends StatelessWidget {
  final List<Skill> skills;

  const _PrioritySummaryChips({required this.skills});

  int _countByStatus(String status) {
    return skills.where((s) {
      final d = DateTime.now().difference(s.lastPracticed).inDays;
      if (status == 'high') return d >= 10;
      if (status == 'moderate') return d >= 5 && d < 10;
      return d < 5;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final highCount = _countByStatus('high');
    final modCount = _countByStatus('moderate');
    final stableCount = _countByStatus('stable');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (highCount > 0)
            _Chip(
              label: '$highCount High Risk',
              color: const Color(0xFFEF4444),
            ),
          if (highCount > 0 && modCount > 0) const SizedBox(width: 8),
          if (modCount > 0)
            _Chip(label: '$modCount Moderate', color: const Color(0xFFF59E0B)),
          if ((highCount > 0 || modCount > 0) && stableCount > 0)
            const SizedBox(width: 8),
          if (stableCount > 0)
            _Chip(label: '$stableCount Stable', color: const Color(0xFF10B981)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
