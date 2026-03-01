import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/skill.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/skill_service.dart';
import '../widgets/skill_card.dart';
import '../widgets/skill_modal.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all'; // all | high | moderate | stable

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _riskStatus(Skill s) {
    final d = DateTime.now().difference(s.lastPracticed).inDays;
    if (d >= 10) return 'high';
    if (d >= 5) return 'moderate';
    return 'stable';
  }

  List<Skill> _filtered(List<Skill> skills) {
    var list = skills;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((s) =>
              s.name.toLowerCase().contains(_searchQuery) ||
              s.category.toLowerCase().contains(_searchQuery))
          .toList();
    }
    if (_filterStatus != 'all') {
      list = list.where((s) => _riskStatus(s) == _filterStatus).toList();
    }
    // Sort: highest risk first
    list.sort((a, b) {
      final da = DateTime.now().difference(a.lastPracticed).inDays;
      final db = DateTime.now().difference(b.lastPracticed).inDays;
      return db.compareTo(da);
    });
    return list;
  }

  void _openAddModal() {
    _staggerCtrl.reset();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SkillModal(),
    ).then((_) {
      if (mounted) _staggerCtrl.forward();
    });
  }

  void _openEditModal(Skill skill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SkillModal(skill: skill),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, Skill skill) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Skill',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Remove "${skill.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && skill.id != null) {
      await SkillService().deleteSkill(skill.id!);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('"${skill.name}" deleted'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user =
        Provider.of<AuthService>(context, listen: false).currentUser;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Skill>>(
              stream: SkillService().getUserSkills(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF6366F1)),
                  );
                }

                final allSkills = snapshot.data ?? [];
                final filtered = _filtered(allSkills);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Header ────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 56, 20, 0),
                        child: _SkillsHeader(
                          count: allSkills.length,
                          isDark: isDark,
                          controller: _staggerCtrl,
                          onAddTap: _openAddModal,
                        ),
                      ),
                    ),

                    // ── Search bar ────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: _SearchBar(
                          controller: _searchCtrl,
                          isDark: isDark,
                        ),
                      ),
                    ),

                    // ── Filter chips ──────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: _FilterRow(
                          selected: _filterStatus,
                          isDark: isDark,
                          onChanged: (v) =>
                              setState(() => _filterStatus = v),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // ── Empty state ───────────────────────────────────────
                    if (filtered.isEmpty)
                      SliverFillRemaining(
                        child: _EmptyState(
                          hasSearch: _searchQuery.isNotEmpty ||
                              _filterStatus != 'all',
                          isDark: isDark,
                          onAddTap: _openAddModal,
                        ),
                      )
                    else
                      // ── Skill cards ─────────────────────────────────────
                      SliverPadding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final skill = filtered[index];
                              return SkillCardWidget(
                                skill: skill,
                                entranceAnimation: _staggerCtrl,
                                intervalStart:
                                    (0.1 + index * 0.08).clamp(0.0, 0.9),
                                onEdit: () => _openEditModal(skill),
                                onDelete: () =>
                                    _confirmDelete(context, skill),
                              );
                            },
                            childCount: filtered.length,
                          ),
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SkillsHeader extends StatelessWidget {
  final int count;
  final bool isDark;
  final AnimationController controller;
  final VoidCallback onAddTap;

  const _SkillsHeader({
    required this.count,
    required this.isDark,
    required this.controller,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Skills',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '$count skill${count != 1 ? 's' : ''} tracked',
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
          _AddButton(onTap: onAddTap),
        ],
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.93).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 20),
              SizedBox(width: 4),
              Text(
                'Add Skill',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const _SearchBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1E293B),
          fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search skills…',
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
          fontSize: 14,
        ),
        prefixIcon: Icon(Icons.search_rounded,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            size: 22),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close_rounded,
                    color:
                        isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                onPressed: () => controller.clear(),
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String selected;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _FilterRow({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  static const _filters = [
    ('all', 'All', Color(0xFF6366F1)),
    ('high', 'High Risk', Color(0xFFEF4444)),
    ('moderate', 'Moderate', Color(0xFFF59E0B)),
    ('stable', 'Stable', Color(0xFF10B981)),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final (value, label, color) = f;
          final isSelected = selected == value;
          return GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? color
                      : isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final bool isDark;
  final VoidCallback onAddTap;

  const _EmptyState({
    required this.hasSearch,
    required this.isDark,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch
                    ? Icons.search_off_rounded
                    : Icons.library_books_outlined,
                size: 46,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch ? 'No results found' : 'No skills yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try a different search or filter.'
                  : 'Add your first skill to start learning and tracking progress.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onAddTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add your first skill',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
