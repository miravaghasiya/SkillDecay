import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/skill.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/skill_service.dart';
import '../../loading/shimmer_loader.dart';
import '../widgets/analytics_tab.dart';
import '../widgets/rewards_tab.dart';
import '../../../../core/animations/entrance_animation.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  int _selectedTab = 0;

  static const List<({String label, IconData icon})> _tabs = [
    (label: 'Analytics', icon: Icons.bar_chart_rounded),
    (label: 'Rewards', icon: Icons.emoji_events_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                final skills = snapshot.data ?? [];

                return CustomScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  slivers: [
                    // ── Page header ────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                        child: AnimatedEntranceWrapper(
                          animationController: _headerCtrl,
                          intervalStart: 0.0,
                          intervalEnd: 0.6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your analytics and rewards',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Segmented tab bar ──────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: AnimatedEntranceWrapper(
                          animationController: _headerCtrl,
                          intervalStart: 0.1,
                          intervalEnd: 0.7,
                          child: _SegmentedTabBar(
                            tabs: _tabs,
                            selectedIndex: _selectedTab,
                            isDark: isDark,
                            onChanged: (i) => setState(() {
                              _selectedTab = i;
                            }),
                          ),
                        ),
                      ),
                    ),

                    // ── Tab content ────────────────────────────────────────
                    SliverFillRemaining(
                      child: isLoading
                          ? _buildLoadingSkeleton(isDark)
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeInOut,
                              switchOutCurve: Curves.easeInOut,
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.04, 0),
                                        end: Offset.zero,
                                      ).animate(anim),
                                      child: child,
                                    ),
                                  ),
                              child: _buildTab(skills),
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTab(List<Skill> skills) {
    switch (_selectedTab) {
      case 0:
        return AnalyticsTab(key: const ValueKey('analytics'), skills: skills);
      case 1:
        return RewardsTab(key: const ValueKey('rewards'), skills: skills);
      default:
        return AnalyticsTab(
          key: const ValueKey('analytics-default'),
          skills: skills,
        );
    }
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          ShimmerGrid(count: 4),
          const SizedBox(height: 16),
          const ShimmerCard(height: 80),
          const SizedBox(height: 16),
          const ShimmerChart(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Segmented tab bar ────────────────────────────────────────────────────────

class _SegmentedTabBar extends StatelessWidget {
  final List<({String label, IconData icon})> tabs;
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _SegmentedTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final i = e.key;
          final tab = e.value;
          final isSelected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 230),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 14,
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : isDark
                          ? Colors.white38
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF1E293B)
                            : isDark
                            ? Colors.white38
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
