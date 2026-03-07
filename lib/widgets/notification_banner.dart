import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

enum NotificationType {
  reminder, // Blue
  warning,  // Orange
  success,  // Green
  error,    // Red
}

class NotificationBannerService {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    NotificationType type = NotificationType.reminder,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    // 1. Try finding overlay from context (works for UI buttons)
    // 2. Fallback to global navigator key overlay (works for background/FCM listeners)
    final overlay = Overlay.maybeOf(context, rootOverlay: true) 
                 ?? Overlay.maybeOf(context) 
                 ?? NotificationService.navigatorKey.currentState?.overlay;
                 
    if (overlay == null) {
      debugPrint('NotificationBannerService: Overlay is null. Cannot show banner.');
      return;
    }
    
    debugPrint('NotificationBannerService: Displaying banner "$title"');
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopBannerWidget(
        title: title,
        message: message,
        type: type,
        onTap: () {
          if (onTap != null) onTap();
          overlayEntry.remove();
        },
        duration: duration,
        onDismissed: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _TopBannerWidget extends StatefulWidget {
  final String title;
  final String message;
  final NotificationType type;
  final VoidCallback onTap;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopBannerWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.onTap,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_TopBannerWidget> createState() => _TopBannerWidgetState();
}

class _TopBannerWidgetState extends State<_TopBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start entrance animation
    _controller.forward();

    // Setup auto-dismiss timer
    _dismissTimer = Timer(widget.duration, _dismissBanner);
  }

  void _dismissBanner() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismissed();
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(bool isDark) {
    if (isDark) {
      return const Color(0xFF1E293B);
    }
    return Colors.white;
  }

  Color _getIconBackgroundColor() {
    switch (widget.type) {
      case NotificationType.reminder:
        return const Color(0xFF3B82F6).withOpacity(0.15); // Blue
      case NotificationType.warning:
        return const Color(0xFFF59E0B).withOpacity(0.15); // Orange
      case NotificationType.success:
        return const Color(0xFF10B981).withOpacity(0.15); // Green
      case NotificationType.error:
        return const Color(0xFFEF4444).withOpacity(0.15); // Red
    }
  }

  Color _getIconColor() {
    switch (widget.type) {
      case NotificationType.reminder:
        return const Color(0xFF3B82F6);
      case NotificationType.warning:
        return const Color(0xFFF59E0B);
      case NotificationType.success:
        return const Color(0xFF10B981);
      case NotificationType.error:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.reminder:
        return Icons.notifications_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.error:
        return Icons.error_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.maybeOf(context)?.padding.top ?? 0.0;

    return Positioned(
      top: topPadding + 16, // Respect safe area notch
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onTap,
            onVerticalDragUpdate: (details) {
              if (details.delta.dy < -5) {
                _dismissTimer?.cancel();
                _dismissBanner();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getBackgroundColor(isDark),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: isDark ? 0 : 2,
                  ),
                ],
                border: isDark 
                    ? Border.all(color: Colors.white12, width: 1)
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getIconBackgroundColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIcon(),
                      color: _getIconColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _dismissTimer?.cancel();
                      _dismissBanner();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
