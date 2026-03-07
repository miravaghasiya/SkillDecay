import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/skill_service.dart';
import '../../../../models/skill.dart';
import '../widgets/greeting_header.dart';
import '../widgets/level_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/recommendation_card.dart';
import '../../widgets/profile_avatar_button.dart';
import '../../../profile/profile_screen.dart';
import '../../../../core/animations/page_transition.dart';
import '../../../../core/animations/entrance_animation.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<Skill>? onRecommendedSkillTap;

  const HomeScreen({super.key, this.onRecommendedSkillTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  // ─── Data helpers ───────────────────────────────────────────────────────────

  int _level(List<Skill> skills) {
    final totalMastery = skills.fold(0.0, (sum, s) => sum + s.mastery);
    return (totalMastery / 500).floor() + 1;
  }

  double _currentXp(List<Skill> skills) {
    final totalMastery = skills.fold(0.0, (sum, s) => sum + s.mastery);
    return totalMastery % 500;
  }

  int _streak(List<Skill> skills) {
    // Count skills practiced today
    final today = DateTime.now();
    return skills.where((s) {
      final lp = s.lastPracticed;
      return lp.year == today.year &&
          lp.month == today.month &&
          lp.day == today.day;
    }).length;
  }

  int _bestStreak(List<Skill> skills) {
    // Best streak is approximated as the max streak possible (total practiced days)
    return skills.isEmpty ? 0 : (_streak(skills) > 1 ? _streak(skills) : 1);
  }

  int _todayCount(List<Skill> skills) => _streak(skills);

  /// Sort recommendations: high risk first
  List<Skill> _recommendations(List<Skill> skills) {
    final sorted = List<Skill>.from(skills);
    sorted.sort((a, b) {
      final da = DateTime.now().difference(a.lastPracticed).inDays;
      final db = DateTime.now().difference(b.lastPracticed).inDays;
      return db.compareTo(da); // Most days-ago first
    });
    return sorted.take(5).toList();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Skill>>(
              stream: SkillService().getUserSkills(user.uid),
              builder: (context, snapshot) {
                final skills = snapshot.data ?? [];
                final displayName =
                    user.displayName ?? user.email?.split('@').first ?? '';
                final level = _level(skills);
                final currentXp = _currentXp(skills);
                const maxXp = 500.0;
                final streak = _streak(skills);
                final bestStreak = _bestStreak(skills);
                final recommendations = _recommendations(skills);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── App bar / header ──────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GreetingHeader(
                                displayName: displayName,
                                controller: _staggerController,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedEntranceWrapper(
                              animationController: _staggerController,
                              intervalStart: 0.0,
                              intervalEnd: 0.5,
                              child: ProfileAvatarButton(
                                displayName: displayName,
                                photoUrl: user.photoURL,
                                onTap: () => Navigator.push(
                                  context,
                                  FadeSlidePageRoute(
                                    page: const ProfileScreen(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── Level + Streak row ────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: LevelCardWidget(
                                level: level,
                                currentXp: currentXp,
                                maxXp: maxXp,
                                entranceAnimation: _staggerController,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: StreakCardWidget(
                                streak: streak,
                                bestStreak: bestStreak,
                                entranceAnimation: _staggerController,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // ── Quick Stats Row ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: StatCardWidget(
                                icon: Icons.menu_book_rounded,
                                color: const Color(0xFF6366F1),
                                count: skills.length,
                                label: 'Skills',
                                entranceAnimation: _staggerController,
                                intervalStart: 0.35,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCardWidget(
                                icon: Icons.track_changes_rounded,
                                color: const Color(0xFF0EA5E9),
                                count: skills.length, // total sessions proxy
                                label: 'Sessions',
                                entranceAnimation: _staggerController,
                                intervalStart: 0.42,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCardWidget(
                                icon: Icons.trending_up_rounded,
                                color: const Color(0xFF10B981),
                                count: _todayCount(skills),
                                label: 'Today',
                                entranceAnimation: _staggerController,
                                intervalStart: 0.49,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 28)),

                    // ── Recommended Section Header ─────────────────────────
                    SliverToBoxAdapter(
                      child: AnimatedEntranceWrapper(
                        animationController: _staggerController,
                        intervalStart: 0.5,
                        intervalEnd: 0.85,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recommended for You',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF6366F1),
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'View all',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // ── Recommendation Cards ───────────────────────────────
                    if (recommendations.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 40,
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Add your first skill to get personalised recommendations!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return RecommendationCardWidget(
                              skill: recommendations[index],
                              entranceAnimation: _staggerController,
                              onTapSkill: widget.onRecommendedSkillTap,
                              intervalStart: (0.55 + index * 0.06).clamp(
                                0.0,
                                0.95,
                              ),
                            );
                          }, childCount: recommendations.length),
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
