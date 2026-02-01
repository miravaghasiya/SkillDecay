import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/skill_service.dart';
import '../../models/skill.dart';
import '../profile/profile_screen.dart';
import '../add_skill/add_skill_screen.dart';
import '../edit_skill/edit_skill_screen.dart';
import '../skill_details/skill_details_screen.dart';
import '../stats/stats_screen.dart';
import '../alerts/alerts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNavIndex = 0;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'urgent', 'decaying', 'safe'

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildSkillsScreen(),
      const StatsScreen(),
      const AlertsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: screens[_selectedNavIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSkillsScreen() {
    final user = Provider.of<AuthService>(context).currentUser;
    final skillService = SkillService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<List<Skill>>(
              stream: skillService.getUserSkills(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
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
        backgroundColor: const Color(0xFF1E293B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      title: StreamBuilder<List<Skill>>(
        stream: SkillService().getUserSkills(
          Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '',
        ),
        builder: (context, snapshot) {
          final skills = snapshot.data ?? [];
          final urgentCount = skills.where((s) => _getSkillStatus(s) == 'urgent').length;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Skills',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$urgentCount skills need practice today',
                style: const TextStyle(
                  color: Color(0xFF64748B),
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
          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B)),
          onPressed: () {
            // Navigate to alerts
            setState(() {
              _selectedNavIndex = 2;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF1E293B),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onPressed: () {
              setState(() {
                _selectedNavIndex = 3;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search skills...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Color(0xFF94A3B8)),
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips(List<Skill> allSkills) {
    final urgentCount = allSkills.where((s) => _getSkillStatus(s) == 'urgent').length;
    final decayingCount = allSkills.where((s) => _getSkillStatus(s) == 'decaying').length;
    final safeCount = allSkills.where((s) => _getSkillStatus(s) == 'safe').length;

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('All', 'all', null, allSkills.length),
          const SizedBox(width: 8),
          _buildFilterChip('Urgent', 'urgent', Colors.red, urgentCount),
          const SizedBox(width: 8),
          _buildFilterChip('Decaying', 'decaying', Colors.orange, decayingCount),
          const SizedBox(width: 8),
          _buildFilterChip('Safe', 'safe', Colors.green, safeCount),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color? dotColor, int count) {
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
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF1E293B),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1E293B),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title, Category Badge, Status Indicator
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        skill.category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
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
          
          // Last practiced text
          Text(
            'Last practiced: $daysSince days ago',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          
          // Progress bar with percentage
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF1F5F9),
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
          
          // Action button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isUrgent
                ? ElevatedButton.icon(
                    onPressed: () {
                      // Practice action
                      _showPracticeDialog(context, skill);
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
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  )
                : OutlinedButton(
                    onPressed: () {
                      _showSkillDetails(context, skill);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
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
          Icon(
            Icons.lightbulb_outline,
            size: 80,
            color: Colors.grey[400],
          ),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1E293B),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  // Helper methods
  int _calculateDaysSinceLastPractice(Skill skill) {
    final now = DateTime.now();
    final difference = now.difference(skill.lastPracticed);
    return difference.inDays;
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
        return const Color(0xFFEF4444); // Red
      case 'decaying':
        return const Color(0xFFF59E0B); // Orange/Yellow
      case 'safe':
        return const Color(0xFF10B981); // Green
      default:
        return Colors.grey;
    }
  }

  double _calculateProgress(int days) {
    // Inverse calculation: fewer days = higher progress
    if (days >= 14) return 25;
    if (days >= 10) return 25;
    if (days >= 7) return 55;
    if (days >= 5) return 55;
    if (days >= 3) return 90;
    return 90;
  }

  List<Skill> _filterSkills(List<Skill> skills) {
    var filtered = skills;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((skill) => skill.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered
          .where((skill) => _getSkillStatus(skill) == _selectedFilter)
          .toList();
    }

    return filtered;
  }

  void _showPracticeDialog(BuildContext context, Skill skill) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Practice Skill'),
          content: Text('Mark "${skill.name}" as practiced today?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final updatedSkill = skill.copyWith(
                    lastPracticed: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await SkillService().updateSkill(updatedSkill.id!, updatedSkill);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Skill marked as practiced!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
              ),
              child: const Text('Mark as Practiced'),
            ),
          ],
        );
      },
    );
  }

  void _showSkillDetails(BuildContext context, Skill skill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SkillDetailsScreen(skill: skill),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Skill skill) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Skill'),
          content: Text('Are you sure you want to delete "${skill.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await SkillService().deleteSkill(skill.id!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Skill deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting skill: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
