import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/skill_service.dart';
import '../../models/skill.dart';
import '../add_skill/add_skill_screen.dart';
import '../skill_details/skill_details_screen.dart';
import '../home/presentation/screens/home_screen.dart';
import '../practice/presentation/screens/practice_screen.dart';
import '../skills/presentation/screens/skills_screen.dart';
import '../progress/presentation/screens/progress_screen.dart';
import '../coach/presentation/screens/coach_screen.dart';
import '../quiz/quiz_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _selectedNavIndex = 0;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'urgent', 'decaying', 'safe'
  bool _shouldOpenAddModal = false;
  String? _practiceHighlightSkillId;

  void setTab(
    int index, {
    bool openAddModal = false,
    String? highlightSkillId,
  }) {
    setState(() {
      _selectedNavIndex = index;
      _shouldOpenAddModal = openAddModal;
      if (index == 1) {
        _practiceHighlightSkillId =
            highlightSkillId ?? _practiceHighlightSkillId;
      }
    });
  }

  void _openRecommendedSkillInPractice(Skill skill) {
    setState(() {
      _selectedNavIndex = 1;
      _practiceHighlightSkillId = skill.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      HomeScreen(
        onRecommendedSkillTap: _openRecommendedSkillInPractice,
      ), // 0 – Home
      PracticeScreen(
        key: ValueKey<String>(
          'practice-${_practiceHighlightSkillId ?? 'none'}',
        ),
        onAddSkill: () => setTab(2, openAddModal: true),
        highlightSkillId: _practiceHighlightSkillId,
      ), // 1 – Practice
      SkillsScreen(openAddModal: _shouldOpenAddModal), // 2 – Skills
      const ProgressScreen(), // 3 – Progress
      const CoachScreen(), // 4 – AI Coach
    ];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      body: IndexedStack(index: _selectedNavIndex, children: screens),
      bottomNavigationBar: _buildBottomNavBar(isDark),
    );
  }

  // ─── Skills tab ─────────────────────────────────────────────────────────────

  Widget _buildSkillsScreen() {
    final user = Provider.of<AuthService>(context).currentUser;
    final skillService = SkillService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildSkillsAppBar(),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<List<Skill>>(
              stream: skillService.getUserSkills(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allSkills = snapshot.data ?? [];
                final filteredSkills = _filterSkills(allSkills);

                return Column(
                  children: [
                    _buildSearchBar(),
                    _buildFilterChips(allSkills),
                    Expanded(
                      child: filteredSkills.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredSkills.length,
                              itemBuilder: (context, index) {
                                final skill = filteredSkills[index];
                                return _buildSkillCard(context, skill);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSkillScreen()),
          );
        },
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildSkillsAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      title: StreamBuilder<List<Skill>>(
        stream: SkillService().getUserSkills(
          Provider.of<AuthService>(context, listen: false).currentUser?.uid ??
              '',
        ),
        builder: (context, snapshot) {
          final skills = snapshot.data ?? [];
          final urgentCount = skills
              .where((s) => _getSkillStatus(s) == 'urgent')
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Skills',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$urgentCount skills need practice today',
                style: TextStyle(
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () => setState(() => _selectedNavIndex = 3),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
              child: const Icon(
                Icons.person,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            onPressed: () => setState(() => _selectedNavIndex = 4),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Search skills...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          icon: Icon(
            Icons.search,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips(List<Skill> allSkills) {
    final urgentCount = allSkills
        .where((s) => _getSkillStatus(s) == 'urgent')
        .length;
    final decayingCount = allSkills
        .where((s) => _getSkillStatus(s) == 'decaying')
        .length;
    final safeCount = allSkills
        .where((s) => _getSkillStatus(s) == 'safe')
        .length;

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('All', 'all', null, allSkills.length),
          const SizedBox(width: 8),
          _buildFilterChip('Urgent', 'urgent', Colors.red, urgentCount),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Decaying',
            'decaying',
            Colors.orange,
            decayingCount,
          ),
          const SizedBox(width: 8),
          _buildFilterChip('Safe', 'safe', Colors.green, safeCount),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    Color? dotColor,
    int count,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedFilter = value),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      selectedColor: const Color(0xFF6366F1),
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : isDark
            ? Colors.white70
            : const Color(0xFF1E293B),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF6366F1)
              : isDark
              ? Colors.white12
              : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildSkillCard(BuildContext context, Skill skill) {
    final daysSince = _calculateDaysSinceLastPractice(skill);
    final status = _getSkillStatus(skill);
    final statusColor = _getStatusColor(status);
    final progress = _calculateProgress(daysSince);
    final isUrgent = status == 'urgent';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        skill.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Last practiced: $daysSince days ago',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${progress.toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isUrgent
                ? ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(skill: skill),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bolt, size: 20),
                    label: const Text(
                      'Practice Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  )
                : OutlinedButton(
                    onPressed: () => _showSkillDetails(context, skill),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No skills found'
                : 'No skills in this category',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Add skills to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ─── Bottom nav ─────────────────────────────────────────────────────────────

  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => setState(() => _selectedNavIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on_outlined),
            activeIcon: Icon(Icons.flash_on_rounded),
            label: 'Practice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book_rounded),
            label: 'Skills',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_outlined),
            activeIcon: Icon(Icons.trending_up_rounded),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Coach',
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  int _calculateDaysSinceLastPractice(Skill skill) {
    return DateTime.now().difference(skill.lastPracticed).inDays;
  }

  String _getSkillStatus(Skill skill) {
    final days = _calculateDaysSinceLastPractice(skill);
    if (days >= 10) return 'urgent';
    if (days >= 5) return 'decaying';
    return 'safe';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'decaying':
        return const Color(0xFFF59E0B);
      case 'safe':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  double _calculateProgress(int days) {
    if (days >= 10) return 25;
    if (days >= 7) return 55;
    if (days >= 5) return 55;
    if (days >= 3) return 90;
    return 90;
  }

  List<Skill> _filterSkills(List<Skill> skills) {
    var filtered = skills;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) => s.name.toLowerCase().contains(_searchQuery))
          .toList();
    }
    if (_selectedFilter != 'all') {
      filtered = filtered
          .where((s) => _getSkillStatus(s) == _selectedFilter)
          .toList();
    }
    return filtered;
  }

  void _showSkillDetails(BuildContext context, Skill skill) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SkillDetailsScreen(skill: skill)),
    );
  }
}
