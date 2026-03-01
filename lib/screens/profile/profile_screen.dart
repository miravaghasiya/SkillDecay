import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/theme_provider.dart';
import '../edit_profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeIn =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthService>(context, listen: false).signOut();
              // Return to the first route (AppStartRouter root)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                  color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Provider.of<AuthService>(context).currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Card ──────────────────────────────────────────────
              _sectionCard(
                isDark,
                child: Column(
                  children: [
                    // Gradient avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF6366F1).withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: user?.photoURL != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(user!.photoURL!,
                                  fit: BoxFit.cover))
                          : Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color:
                            isDark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _sectionLabel('Preferences', isDark),
              const SizedBox(height: 10),

              // ── Preferences Card ─────────────────────────────────────────
              _sectionCard(
                isDark,
                child: Column(
                  children: [
                    Consumer<ThemeProvider>(
                      builder: (ctx, theme, _) => _buildTile(
                        isDark: isDark,
                        icon: Icons.dark_mode_rounded,
                        iconColor: const Color(0xFF6366F1),
                        title: 'Dark Mode',
                        subtitle: theme.isDarkMode ? 'Enabled' : 'Disabled',
                        trailing: Switch(
                          value: theme.isDarkMode,
                          onChanged: (_) => theme.toggleTheme(),
                          activeColor: const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    _divider(isDark),
                    _buildTile(
                      isDark: isDark,
                      icon: Icons.notifications_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Notifications',
                      subtitle: 'Push & email alerts',
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (v) =>
                            setState(() => _notificationsEnabled = v),
                        activeColor: const Color(0xFF6366F1),
                      ),
                    ),
                    _divider(isDark),
                    _buildTile(
                      isDark: isDark,
                      icon: Icons.alarm_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Reminder Frequency',
                      subtitle: 'Daily at 9:00 AM',
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8)),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Reminder settings coming soon')),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _sectionLabel('App Settings', isDark),
              const SizedBox(height: 10),

              // ── App Settings Card ─────────────────────────────────────────
              _sectionCard(
                isDark,
                child: Column(
                  children: [
                    _buildTile(
                      isDark: isDark,
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF0EA5E9),
                      title: 'About SkillDecay',
                      subtitle: 'Version 1.0.0',
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8)),
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'SkillDecay',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2026 SkillDecay',
                      ),
                    ),
                    _divider(isDark),
                    _buildTile(
                      isDark: isDark,
                      icon: Icons.privacy_tip_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'Privacy Policy',
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8)),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Privacy Policy coming soon')),
                      ),
                    ),
                    _divider(isDark),
                    _buildTile(
                      isDark: isDark,
                      icon: Icons.help_outline_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Help & Support',
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8)),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Help & Support coming soon')),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Logout Button ───────────────────────────────────────────
              GestureDetector(
                onTap: _showLogoutDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionCard(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
    );
  }

  Widget _buildTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
