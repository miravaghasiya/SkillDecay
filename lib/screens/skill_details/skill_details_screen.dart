import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/skill.dart';
import '../../services/skill_service.dart';
import '../../services/auth_service.dart';
import '../../services/quiz_service.dart';
import '../edit_skill/edit_skill_screen.dart';
import '../quiz/quiz_screen.dart';

class SkillDetailsScreen extends StatefulWidget {
  final Skill skill;

  const SkillDetailsScreen({super.key, required this.skill});

  @override
  State<SkillDetailsScreen> createState() => _SkillDetailsScreenState();
}

class _SkillDetailsScreenState extends State<SkillDetailsScreen> {
  late Stream<DocumentSnapshot> _skillStream;
  late Stream<QuerySnapshot> _historyStream;
  final QuizService _quizService = QuizService();
  bool _isStartingPractice = false;

  @override
  void initState() {
    super.initState();

    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid ??
        'unknown';

    _skillStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('skills')
        .doc(widget.skill.id)
        .snapshots();

    _historyStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('practice_sessions')
        .where('skillId', isEqualTo: widget.skill.id)
        // Removed orderBy to prevent missing index errors. Client sorting or timestamp field checks can be used instead.
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _skillStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final skillDoc = snapshot.data!;
        if (!skillDoc.exists) {
          return const Scaffold(body: Center(child: Text('Skill not found')));
        }

        final skill = Skill.fromFirestore(skillDoc);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context, skill),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(skill),
                const SizedBox(height: 24),
                _buildMasteryCard(skill), // Renamed from CriticalStatusCard
                const SizedBox(height: 24),
                _buildStatsGrid(skill),
                const SizedBox(height: 24),
                const Text(
                  'Practice History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPracticeHistoryList(),
                const SizedBox(height: 80),
              ],
            ),
          ),
          bottomSheet: _buildBottomActions(context, skill),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Skill skill) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back,
            size: 20,
            color: Color(0xFF1E293B),
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit, size: 20, color: Color(0xFF1E293B)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditSkillScreen(skill: skill)),
            );
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.red.withOpacity(0.05),
            ),
            child: const Icon(Icons.delete, size: 20, color: Colors.red),
          ),
          onPressed: () => _showDeleteDialog(context, skill),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildHeader(Skill skill) {
    // Determine color based on mastery
    Color statusColor;
    if (skill.mastery >= 80)
      statusColor = const Color(0xFF10B981); // Green
    else if (skill.mastery >= 50)
      statusColor = const Color(0xFFF59E0B); // Amber
    else
      statusColor = const Color(0xFFEF4444); // Red

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                skill.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  skill.category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMasteryCard(Skill skill) {
    // Logic: Mastery %
    final mastery = skill.mastery;

    Color color;
    String title;
    String subtitle;

    if (mastery >= 80) {
      color = const Color(0xFF10B981);
      title = "Expert Mastery";
      subtitle = "Excellent retention!";
    } else if (mastery >= 50) {
      color = const Color(0xFFF59E0B);
      title = "Developing Skill";
      subtitle = "Keep practicing to improve.";
    } else {
      color = const Color(0xFFEF4444);
      title = "Needs Attention";
      subtitle = "Skill is decaying or new.";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: color, size: 24), // Changed icon
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: mastery / 100,
                    minHeight: 12,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${mastery.toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Skill skill) {
    final now = DateTime.now();
    final difference = now.difference(skill.lastPracticed);
    final daysSince = difference.inDays;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Last Practiced', '$daysSince days ago'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _historyStream,
                builder: (context, snapshot) {
                  int count = 0;
                  if (snapshot.hasData) count = snapshot.data!.docs.length;
                  return _buildStatCard('Total Sessions', '$count times');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Difficulty',
                skill.difficultyLevel,
                valueBold: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _historyStream,
                builder: (context, snapshot) {
                  String avgDisplay = "N/A";
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    double totalScore = 0;
                    for (var doc in snapshot.data!.docs) {
                      totalScore +=
                          (doc.data() as Map<String, dynamic>)['score'] ?? 0;
                    }
                    avgDisplay =
                        "${(totalScore / snapshot.data!.docs.length).toInt()}%";
                  }

                  return _buildStatCard('Avg. Score', avgDisplay);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, {bool valueBold = true}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _historyStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            "No practice history yet.",
            style: TextStyle(color: Colors.grey),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final score = (data['score'] ?? 0).toInt();
            // Fallback for timestamp mapping.
            final date =
                (data['date'] as Timestamp?)?.toDate() ??
                (data['timestamp'] as Timestamp?)?.toDate() ??
                DateTime.now();
            final dateStr = DateFormat.yMMMd().format(date);
            final totalQ = data['totalQuestions'] ?? 0;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$score%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalQ questions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomActions(BuildContext context, Skill skill) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isStartingPractice
                  ? null
                  : () async {
                      setState(() {
                        _isStartingPractice = true;
                      });

                      try {
                        final questions = await _quizService.generateQuizBatch(
                          skillId: skill.id ?? '',
                          skillTitle: skill.name,
                          category: skill.category,
                          userLevel: skill.difficultyLevel,
                          mastery: skill.mastery,
                        );

                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              skill: skill,
                              initialQuestions: questions,
                            ),
                          ),
                        );
                      } catch (_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Unable to generate quiz right now. Please try again.',
                            ),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isStartingPractice = false;
                          });
                        }
                      }
                    },
              icon: _isStartingPractice
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bolt, color: Colors.white),
              label: Text(
                _isStartingPractice
                    ? 'Generating Quiz...'
                    : 'Start Practice Session',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
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
                final user = Provider.of<AuthService>(
                  context,
                  listen: false,
                ).currentUser;
                if (user == null) return;

                try {
                  await SkillService().deleteSkill(user.uid, skill.id!);
                  if (context.mounted) {
                    Navigator.pop(context); // Pop details screen
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
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
