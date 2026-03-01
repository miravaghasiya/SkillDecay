import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../models/skill.dart';
import '../../../../services/skill_service.dart';
import '../../../../services/auth_service.dart';

/// A unified bottom-sheet modal for both Add and Edit skill.
/// Pass [skill] to pre-fill fields for editing; omit for adding.
class SkillModal extends StatefulWidget {
  final Skill? skill;

  const SkillModal({super.key, this.skill});

  @override
  State<SkillModal> createState() => _SkillModalState();
}

class _SkillModalState extends State<SkillModal>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  final SkillService _skillService = SkillService();

  late String _category;
  late String _difficulty;
  late DateTime _lastPracticed;
  bool _isLoading = false;

  bool get _isEdit => widget.skill != null;

  static const List<String> _categories = [
    'Programming', 'Design', 'Languages', 'Music',
    'Sports', 'Cooking', 'Writing', 'Other',
  ];

  static const List<String> _difficulties = [
    'Beginner', 'Intermediate', 'Advanced',
  ];

  // Suggested practice interval per difficulty
  int _suggestedFrequency(String difficulty) {
    switch (difficulty) {
      case 'Beginner': return 2;
      case 'Advanced': return 5;
      default: return 3;
    }
  }

  @override
  void initState() {
    super.initState();
    final s = widget.skill;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _notesCtrl = TextEditingController(text: s?.notes ?? '');
    _category = s?.category ?? '';
    _difficulty = s?.difficultyLevel ?? 'Intermediate';
    _lastPracticed = s?.lastPracticed ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPracticed,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF6366F1),
            onPrimary: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _lastPracticed = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a category'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user =
          Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) throw Exception('User not logged in');

      final notes =
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

      if (_isEdit) {
        final updated = widget.skill!.copyWith(
          name: _nameCtrl.text.trim(),
          category: _category,
          difficultyLevel: _difficulty,
          lastPracticed: _lastPracticed,
          notes: notes,
          updatedAt: DateTime.now(),
        );
        await _skillService.updateSkill(widget.skill!.id!, updated);
      } else {
        final skill = Skill(
          userId: user.uid,
          name: _nameCtrl.text.trim(),
          category: _category,
          difficultyLevel: _difficulty,
          lastPracticed: _lastPracticed,
          notes: notes,
        );
        await _skillService.addSkill(skill);
      }

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Skill updated! 🎉' : 'Skill added! 🎉'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again later.';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'You don\'t have permission to save this skill. Please check your login status.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: mq.viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ───────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ─────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Skill' : 'Add New Skill',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color:
                            isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Skill Name ────────────────────────────────────────────
              _sectionLabel('Skill Name *', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E293B)),
                decoration: _inputDecoration(
                  hint: 'e.g. React Hooks, Python OOP…',
                  isDark: isDark,
                  prefixIcon: const Icon(Icons.school_outlined,
                      size: 20, color: Color(0xFF6366F1)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a skill name'
                    : null,
              ),
              const SizedBox(height: 22),

              // ── Category ──────────────────────────────────────────────
              _sectionLabel('Category *', isDark),
              const SizedBox(height: 10),
              _CategoryChips(
                categories: _categories,
                selected: _category,
                isDark: isDark,
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 22),

              // ── Difficulty ────────────────────────────────────────────
              _sectionLabel('Difficulty', isDark),
              const SizedBox(height: 10),
              _DifficultySelector(
                difficulties: _difficulties,
                selected: _difficulty,
                isDark: isDark,
                onChanged: (v) => setState(() => _difficulty = v),
              ),
              const SizedBox(height: 6),
              // Suggested frequency hint
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 14, color: Color(0xFF6366F1)),
                  const SizedBox(width: 5),
                  Text(
                    'Suggested: practice every ${_suggestedFrequency(_difficulty)} days',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── Last Practiced ────────────────────────────────────────
              _sectionLabel('Last Practiced', isDark),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: Color(0xFF6366F1)),
                      const SizedBox(width: 12),
                      Text(
                        '${_lastPracticed.day.toString().padLeft(2, '0')}-'
                        '${_lastPracticed.month.toString().padLeft(2, '0')}-'
                        '${_lastPracticed.year}',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ── Notes ─────────────────────────────────────────────────
              _sectionLabel('Notes (Optional)', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                maxLength: 300,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1E293B)),
                decoration: _inputDecoration(
                  hint: 'Resources, context, learning goals…',
                  isDark: isDark,
                ).copyWith(counterStyle: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                )),
              ),
              const SizedBox(height: 28),

              // ── Buttons ───────────────────────────────────────────────
              _GradientButton(
                label: _isEdit ? 'Update Skill' : 'Add Skill',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white54
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, bool isDark) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: isDark ? Colors.white60 : const Color(0xFF64748B),
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required bool isDark,
    Widget? prefixIcon,
  }) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon,
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
          fontSize: 14,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide:
              const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
      );
}

// ─── Category chip selector ───────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(c);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    )
                  : null,
              color: isSelected
                  ? null
                  : isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              c,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.white60
                        : const Color(0xFF64748B),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Difficulty selector ──────────────────────────────────────────────────────

class _DifficultySelector extends StatelessWidget {
  final List<String> difficulties;
  final String selected;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _DifficultySelector({
    required this.difficulties,
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  Color _chipColor(String d) {
    switch (d) {
      case 'Beginner': return const Color(0xFF10B981);
      case 'Advanced': return const Color(0xFFEF4444);
      default: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: difficulties.map((d) {
        final isSelected = d == selected;
        final chipColor = _chipColor(d);
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(d);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(
                right: d != difficulties.last ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? chipColor.withOpacity(0.12)
                    : isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? chipColor : isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? chipColor
                      : isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Gradient primary button ──────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
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
        widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.97).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
