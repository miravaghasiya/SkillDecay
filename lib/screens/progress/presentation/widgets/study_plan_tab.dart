import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../models/skill.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/animations/entrance_animation.dart';

final _db = FirebaseFirestore.instance;

class StudyPlanTab extends StatefulWidget {
  final List<Skill> skills;

  const StudyPlanTab({super.key, required this.skills});

  @override
  State<StudyPlanTab> createState() => _StudyPlanTabState();
}

class _StudyPlanTabState extends State<StudyPlanTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user =
        Provider.of<AuthService>(context, listen: false).currentUser;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ── Create plan button ──────────────────────────────────────────
          AnimatedEntranceWrapper(
            animationController: _entranceCtrl,
            intervalStart: 0.0,
            intervalEnd: 0.5,
            child: _CreatePlanButton(
              expanded: _showForm,
              onTap: () => setState(() => _showForm = !_showForm),
            ),
          ),

          // ── Collapsible form ────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: _showForm
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _PlanGeneratorForm(
                      skills: widget.skills,
                      isDark: isDark,
                      onClose: () => setState(() => _showForm = false),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 20),

          // ── Plans list ──────────────────────────────────────────────────
          if (user != null)
            StreamBuilder<List<StudyPlan>>(
              stream: _StudyPlanService().getPlans(user.uid),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildPlanSkeleton(isDark);
                }
                final plans = snapshot.data ?? [];
                if (plans.isEmpty) {
                  return _EmptyPlanState(isDark: isDark);
                }
                return AnimatedEntranceWrapper(
                  animationController: _entranceCtrl,
                  intervalStart: 0.2,
                  intervalEnd: 0.8,
                  child: Column(
                    children: plans.asMap().entries.map((e) {
                      return _PlanCard(
                        plan: e.value,
                        isDark: isDark,
                      );
                    }).toList(),
                  ),
                );
              },
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPlanSkeleton(bool isDark) {
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
            children: [
              Expanded(
                  child: _Shimmer(
                      width: double.infinity, height: 14, radius: 8)),
              const SizedBox(width: 60),
            ],
          ),
          const SizedBox(height: 10),
          _Shimmer(width: 180, height: 10, radius: 6),
          const SizedBox(height: 14),
          _Shimmer(width: double.infinity, height: 8, radius: 4),
          const SizedBox(height: 14),
          _Shimmer(width: 100, height: 12, radius: 8),
          const SizedBox(height: 8),
          _Shimmer(width: double.infinity, height: 36, radius: 10),
        ],
      ),
    );
  }
}

// ─── Simple inline shimmer (reuses the concept without import) ────────────────

class _Shimmer extends StatefulWidget {
  final double width, height, radius;
  const _Shimmer({required this.width, required this.height, required this.radius});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1E293B),
                    Color.lerp(const Color(0xFF1E293B),
                        const Color(0xFF334155), _c.value)!,
                    const Color(0xFF1E293B),
                  ]
                : [
                    const Color(0xFFE2E8F0),
                    Color.lerp(const Color(0xFFE2E8F0),
                        const Color(0xFFF1F5F9), _c.value)!,
                    const Color(0xFFE2E8F0),
                  ],
          ),
        ),
      ),
    );
  }
}

// ─── Create Plan Button ───────────────────────────────────────────────────────

class _CreatePlanButton extends StatefulWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _CreatePlanButton({required this.expanded, required this.onTap});

  @override
  State<_CreatePlanButton> createState() => _CreatePlanButtonState();
}

class _CreatePlanButtonState extends State<_CreatePlanButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapCtrl.forward(),
      onTapUp: (_) {
        _tapCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapCtrl.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.97).animate(
            CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut)),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedRotation(
                turns: widget.expanded ? 0.125 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                'Create Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Plan generator form ──────────────────────────────────────────────────────

class _PlanGeneratorForm extends StatefulWidget {
  final List<Skill> skills;
  final bool isDark;
  final VoidCallback onClose;

  const _PlanGeneratorForm({
    required this.skills,
    required this.isDark,
    required this.onClose,
  });

  @override
  State<_PlanGeneratorForm> createState() => _PlanGeneratorFormState();
}

class _PlanGeneratorFormState extends State<_PlanGeneratorForm> {
  final _goalCtrl = TextEditingController();
  DateTime? _deadline;
  double _dailyMins = 30;
  bool _isGenerating = false;

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _deadline = picked);
  }

  Future<void> _generate() async {
    if (_goalCtrl.text.trim().isEmpty || _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a goal and deadline'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 800));

    // Generate tasks from skills
    final tasks = widget.skills
        .take(9)
        .map((s) => StudyTask(
              skillName: s.name,
              durationMins: _dailyMins.round(),
              done: false,
            ))
        .toList();

    // Save the plan
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null && mounted) {
      try {
        final plan = StudyPlan(
          userId: user.uid,
          goal: _goalCtrl.text.trim(),
          deadline: _deadline!,
          dailyMins: _dailyMins.round(),
          tasks: tasks,
          createdAt: DateTime.now(),
        );
        await _StudyPlanService().savePlan(plan);
      } catch (e) {
        String errorMessage = 'Failed to create plan.';
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Permission denied. Please log in again.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() => _isGenerating = false);
      widget.onClose();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Study plan created! 🎉'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final dl = _deadline;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal
          TextField(
            controller: _goalCtrl,
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B)),
            decoration: _inputDeco('Goal (e.g. Master React)', isDark,
                const Icon(Icons.flag_outlined,
                    color: Color(0xFF6366F1), size: 18)),
          ),
          const SizedBox(height: 12),

          // Deadline picker
          GestureDetector(
            onTap: _pickDeadline,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(
                    color: isDark
                        ? Colors.white12
                        : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(14),
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: Color(0xFF6366F1), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    dl == null
                        ? 'Pick deadline'
                        : '${dl.day.toString().padLeft(2, '0')}-${dl.month.toString().padLeft(2, '0')}-${dl.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: dl == null
                          ? (isDark
                              ? Colors.white30
                              : const Color(0xFF94A3B8))
                          : (isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Daily time slider
          Text(
            'Daily time: ${_dailyMins.round()} minutes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6366F1),
              inactiveTrackColor:
                  isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              thumbColor: const Color(0xFF6366F1),
              overlayColor: const Color(0xFF6366F1).withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _dailyMins,
              min: 10,
              max: 120,
              divisions: 11,
              onChanged: (v) => setState(() => _dailyMins = v),
            ),
          ),
          const SizedBox(height: 16),

          // Generate button
          _GenerateButton(
            isLoading: _isGenerating,
            onPressed: _isGenerating ? null : _generate,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint, bool isDark, Widget? prefix) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: prefix,
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
          fontSize: 14,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      );
}

class _GenerateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GenerateButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.white12),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: onPressed == null
                ? const LinearGradient(
                    colors: [Color(0xFFCBD5E1), Color(0xFFCBD5E1)])
                : const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Generate Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Plan card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatefulWidget {
  final StudyPlan plan;
  final bool isDark;

  const _PlanCard({required this.plan, required this.isDark});

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _doneCount =>
      widget.plan.tasks.where((t) => t.done).length;

  double get _progress =>
      widget.plan.tasks.isEmpty
          ? 0
          : _doneCount / widget.plan.tasks.length;

  List<StudyTask> get _todayTasks {
    final now = DateTime.now();
    return widget.plan.tasks.where((t) {
      return true; // In a real app, filter by scheduled date
    }).toList();
  }

  String _formatDeadline() {
    final d = widget.plan.deadline;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleTask(int index) async {
    HapticFeedback.selectionClick();
    final updated = List<StudyTask>.from(widget.plan.tasks);
    updated[index] = StudyTask(
        skillName: updated[index].skillName,
        durationMins: updated[index].durationMins,
        done: !updated[index].done);
    await _StudyPlanService().updatePlanTasks(
        widget.plan.id ?? '', updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final tasks = _todayTasks;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.plan.goal,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(_progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Deadline: ${_formatDeadline()} · $_doneCount/${widget.plan.tasks.length} tasks done',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),

          // Progress bar
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress * _ctrl.value,
                minHeight: 6,
                backgroundColor: isDark
                    ? Colors.white12
                    : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF6366F1)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Today's tasks
          Text(
            "Today's Tasks",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          ...tasks.asMap().entries.map((e) {
            final i = e.key;
            final task = e.value;
            return _TaskItem(
              task: task,
              isDark: isDark,
              onToggle: () => _toggleTask(i),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Task item ────────────────────────────────────────────────────────────────

class _TaskItem extends StatefulWidget {
  final StudyTask task;
  final bool isDark;
  final VoidCallback onToggle;

  const _TaskItem({required this.task, required this.isDark, required this.onToggle});

  @override
  State<_TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<_TaskItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    if (widget.task.done) _ctrl.value = 1.0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: GestureDetector(
        onTap: () {
          widget.onToggle();
          if (widget.task.done) {
            _ctrl.reverse();
          } else {
            _ctrl.forward();
          }
        },
        child: Row(
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                  CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.task.done
                      ? const Color(0xFF10B981)
                      : Colors.transparent,
                  border: Border.all(
                    color: widget.task.done
                        ? const Color(0xFF10B981)
                        : isDark ? Colors.white30 : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: widget.task.done
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  decoration: widget.task.done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: widget.task.done
                      ? (isDark ? Colors.white30 : const Color(0xFF94A3B8))
                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                ),
                child: Text(
                    '${widget.task.skillName} · ${widget.task.durationMins}m'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty plan state ─────────────────────────────────────────────────────────

class _EmptyPlanState extends StatelessWidget {
  final bool isDark;

  const _EmptyPlanState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  size: 36, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 16),
            Text(
              'No study plans yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a plan to organize your learning.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

class StudyTask {
  final String skillName;
  final int durationMins;
  final bool done;

  const StudyTask({
    required this.skillName,
    required this.durationMins,
    required this.done,
  });

  Map<String, dynamic> toMap() => {
        'skillName': skillName,
        'durationMins': durationMins,
        'done': done,
      };

  factory StudyTask.fromMap(Map<String, dynamic> m) => StudyTask(
        skillName: m['skillName'] ?? '',
        durationMins: (m['durationMins'] ?? 30) as int,
        done: (m['done'] ?? false) as bool,
      );
}

class StudyPlan {
  final String? id;
  final String userId;
  final String goal;
  final DateTime deadline;
  final int dailyMins;
  final List<StudyTask> tasks;
  final DateTime createdAt;

  const StudyPlan({
    this.id,
    required this.userId,
    required this.goal,
    required this.deadline,
    required this.dailyMins,
    required this.tasks,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'goal': goal,
        'deadline': deadline.toIso8601String(),
        'dailyMins': dailyMins,
        'tasks': tasks.map((t) => t.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}

// ─── Firestore service for study plans ───────────────────────────────────────

class _StudyPlanService {
  Stream<List<StudyPlan>> getPlans(String userId) {
    return _db
        .collection('study_plans')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return StudyPlan(
                id: doc.id,
                userId: data['userId'] ?? userId,
                goal: data['goal'] ?? '',
                deadline: DateTime.parse(
                    data['deadline'] ?? DateTime.now().toIso8601String()),
                dailyMins: (data['dailyMins'] ?? 30) as int,
                tasks: ((data['tasks'] as List?) ?? [])
                    .map((t) =>
                        StudyTask.fromMap(Map<String, dynamic>.from(t as Map)))
                    .toList(),
                createdAt: DateTime.parse(
                    data['createdAt'] ?? DateTime.now().toIso8601String()),
              );
            }).toList());
  }

  Future<void> savePlan(StudyPlan plan) async {
    await _db.collection('study_plans').add(plan.toMap());
  }

  Future<void> updatePlanTasks(String planId, List<StudyTask> tasks) async {
    if (planId.isEmpty) return;
    await _db.collection('study_plans').doc(planId).update({
      'tasks': tasks.map((t) => t.toMap()).toList(),
    });
  }
}
