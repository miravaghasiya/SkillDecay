import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_button.dart';
import '../onboarding/widgets/gradient_button.dart';
import '../../core/animations/entrance_animation.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await Provider.of<AuthService>(context, listen: false)
            .registerWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );

        // Clear navigation stack to return to AppStartRouter root
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background blobs
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6).withOpacity(0.05),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title Section
                      AnimatedEntranceWrapper(
                        animationController: _entranceController,
                        intervalStart: 0.0,
                        intervalEnd: 0.4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Start tracking your skills today",
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Form Fields
                      AnimatedEntranceWrapper(
                        animationController: _entranceController,
                        intervalStart: 0.2,
                        intervalEnd: 0.6,
                        child: Column(
                          children: [
                            CustomTextField(
                              label: "Full Name",
                              hint: "John Doe",
                              prefixIcon: Icons.person_outline_rounded,
                              controller: _nameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              label: "Email",
                              hint: "you@example.com",
                              prefixIcon: Icons.email_outlined,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              label: "Password",
                              hint: "••••••••",
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: true,
                              controller: _passwordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              label: "Confirm Password",
                              hint: "••••••••",
                              prefixIcon: Icons.lock_clock_outlined,
                              obscureText: true,
                              controller: _confirmPasswordController,
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Signup Button
                      AnimatedEntranceWrapper(
                        animationController: _entranceController,
                        intervalStart: 0.4,
                        intervalEnd: 0.8,
                        child: Column(
                          children: [
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : GradientButton(
                                    label: "Create Account",
                                    onTap: _handleSignUp,
                                  ),
                            const SizedBox(height: 16),
                            Text(
                              "By creating an account, you agree to our Terms & Conditions",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white24
                                    : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Divider
                      AnimatedEntranceWrapper(
                        animationController: _entranceController,
                        intervalStart: 0.5,
                        intervalEnd: 0.9,
                        child: Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: isDark
                                        ? Colors.white10
                                        : const Color(0xFFE2E8F0))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "or sign up with",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFF94A3B8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                                child: Divider(
                                    color: isDark
                                        ? Colors.white10
                                        : const Color(0xFFE2E8F0))),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Social Button
                      AnimatedEntranceWrapper(
                        animationController: _entranceController,
                        intervalStart: 0.6,
                        intervalEnd: 1.0,
                        child: SocialButton(
                          text: "Google",
                          onPressed: () async {
                            setState(() {
                              _isLoading = true;
                            });
                            try {
                              await Provider.of<AuthService>(context,
                                      listen: false)
                                  .signInWithGoogle();
                              if (mounted) {
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: const Color(0xFFEF4444),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          },
                          icon: Image.asset(
                            'assets/images/google_logo.png',
                            errorBuilder: (ctx, e, s) => const Icon(
                                Icons.g_mobiledata,
                                color: Color(0xFF6366F1),
                                size: 30),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Login Link
                      AnimatedEntranceWrapper(
                        animationController: _entranceController,
                        intervalStart: 0.7,
                        intervalEnd: 1.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account?",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF6366F1),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              child: const Text("Login"),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
