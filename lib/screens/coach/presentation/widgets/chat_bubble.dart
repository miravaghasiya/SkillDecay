import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../services/coach_service.dart';
import '../../../../core/animations/entrance_animation.dart';

class ChatBubble extends StatefulWidget {
  final CoachMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final structured = isUser
        ? null
        : _parseStructuredResponse(widget.message.text);

    return AnimatedEntranceWrapper(
      animationController: _controller,
      yOffset: 20.0,
      child: Padding(
        padding: EdgeInsets.only(
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
          bottom: 12,
        ),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[_buildAiAvatar(), const SizedBox(width: 8)],
            Flexible(
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  isUser
                      ? _buildTextBubble(isDark, isUser)
                      : (structured != null
                            ? _buildStructuredBubble(isDark, structured)
                            : _buildTextBubble(isDark, isUser)),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(widget.message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            if (isUser) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBubble(bool isDark, bool isUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isUser
            ? null
            : isDark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: isUser
                ? const Color(0xFF6366F1).withOpacity(0.25)
                : Colors.black.withOpacity(isDark ? 0.2 : 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        widget.message.text,
        style: TextStyle(
          fontSize: 14.5,
          height: 1.5,
          color: isUser
              ? Colors.white
              : isDark
              ? Colors.white.withOpacity(0.9)
              : const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildStructuredBubble(bool isDark, Map<String, dynamic> data) {
    final snapshot = '${data['snapshot'] ?? ''}'.trim();
    final problems = _toStringList(data['problems']);
    final nextMove = '${data['next_move'] ?? ''}'.trim();
    final tips = _toStringList(data['tips']);
    final patterns = _toStringList(data['patterns']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (snapshot.isNotEmpty) ...[
            _SectionCard(
              title: 'Snapshot',
              icon: Icons.insights_rounded,
              color: const Color(0xFF6366F1),
              child: Text(
                snapshot,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (problems.isNotEmpty) ...[
            _SectionCard(
              title: 'Problems',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFF59E0B),
              child: _BulletList(items: problems, isDark: isDark),
            ),
            const SizedBox(height: 10),
          ],
          if (nextMove.isNotEmpty) ...[
            _SectionCard(
              title: 'Next Move',
              icon: Icons.arrow_forward_rounded,
              color: const Color(0xFF10B981),
              child: Text(
                nextMove,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (tips.isNotEmpty) ...[
            _SectionCard(
              title: 'Tips',
              icon: Icons.tips_and_updates_rounded,
              color: const Color(0xFF8B5CF6),
              child: _BulletList(items: tips, isDark: isDark),
            ),
            const SizedBox(height: 10),
          ],
          if (patterns.isNotEmpty) ...[
            _SectionCard(
              title: 'Patterns',
              icon: Icons.query_stats_rounded,
              color: const Color(0xFFEF4444),
              child: _BulletList(items: patterns, isDark: isDark),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic>? _parseStructuredResponse(String text) {
    try {
      var cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'```json|```'), '').trim();
      }
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        return null;
      }
      final decoded = jsonDecode(cleaned.substring(start, end + 1));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
    }
    final text = '$value'.trim();
    return text.isEmpty || text == 'null' ? const [] : [text];
  }

  Widget _buildAiAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  final bool isDark;

  const _BulletList({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
