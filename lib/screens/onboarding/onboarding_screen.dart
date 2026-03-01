import 'package:flutter/material.dart';
import 'package:micro_skill_decay_detector/screens/login/login_screen.dart';
import 'package:micro_skill_decay_detector/screens/onboarding/widgets/animated_indicator.dart';
import 'package:micro_skill_decay_detector/screens/onboarding/widgets/gradient_button.dart';
import 'package:micro_skill_decay_detector/screens/onboarding/widgets/onboarding_illustrations.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

class _PageData {
  final Widget illustration;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;

  const _PageData({
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
  });
}

// ─── Main screen ─────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _textController;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final AnimationController _bgController;
  late final Animation<double> _bgAnim;

  late final List<_PageData> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const _PageData(
        illustration: Screen1Illustration(),
        title: 'SkillDecay',
        subtitle: 'Never forget what you learn.\nMaster skills that actually stick.',
        gradientColors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      ),
      const _PageData(
        illustration: Screen2Illustration(),
        title: 'Track Your Skills',
        subtitle:
            'Our AI detects when you\'re about to forget and reminds you to practice — right on time.',
        gradientColors: [Color(0xFF4338CA), Color(0xFF6366F1)],
      ),
      const _PageData(
        illustration: Screen3Illustration(),
        title: 'Stay Consistent',
        subtitle:
            'Build streaks, earn rewards, and master your skills faster with daily micro-sessions.',
        gradientColors: [Color(0xFF3730A3), Color(0xFF4F46E5)],
      ),
    ];

    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _textFade =
        CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textController, curve: Curves.easeOutCubic));

    _bgController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _bgAnim =
        CurvedAnimation(parent: _bgController, curve: Curves.easeInOut);

    _textController.forward();
    _bgController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _textController
      ..reset()
      ..forward();
    _bgController
      ..reset()
      ..forward();
  }

  void _goToNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: PopScope(
        canPop: _currentPage == 0,
        onPopInvoked: (didPop) {
          if (!didPop && _currentPage > 0) {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          }
        },
        child: AnimatedBuilder(
          animation: _bgAnim,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: page.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: child,
            );
          },
          child: Stack(
            children: [
              // Decorative background blobs
              _buildBackgroundBlobs(size),

              SafeArea(
                child: Column(
                  children: [
                    // Skip button
                    _buildTopBar(),

                    // Page view (illustrations)
                    Expanded(
                      flex: 5,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _pages.length,
                        itemBuilder: (ctx, i) => _IllustrationSlot(
                          child: _pages[i].illustration,
                        ),
                      ),
                    ),

                    // Text + CTA area
                    Expanded(
                      flex: 4,
                      child: _buildBottomContent(page),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundBlobs(Size size) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.2,
          left: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.2),
                  const Color(0xFF8B5CF6).withOpacity(0),
                ],
              ),
            ),
          ),
        ),
        // Overlay gradient to soften the bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: size.height * 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App brand mark
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 17),
              ),
              const SizedBox(width: 8),
              const Text('SkillDecay',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
            ],
          ),
          // Skip
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _navigateToLogin,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            )
          else
            const SizedBox(width: 56), // balance the row
        ],
      ),
    );
  }

  Widget _buildBottomContent(_PageData page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Page indicator
          AnimatedPageIndicator(
            count: _pages.length,
            currentIndex: _currentPage,
          ),
          const SizedBox(height: 28),

          // Title
          FadeTransition(
            opacity: _textFade,
            child: SlideTransition(
              position: _textSlide,
              child: Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Subtitle
          FadeTransition(
            opacity: _textFade,
            child: SlideTransition(
              position: _textSlide,
              child: Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.5,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // CTA
          GradientButton(
            label: _currentPage == _pages.length - 1
                ? 'Get Started'
                : 'Continue',
            trailingIcon: _currentPage == _pages.length - 1
                ? Icons.arrow_forward_rounded
                : Icons.chevron_right_rounded,
            onTap: _goToNext,
          ),
        ],
      ),
    );
  }
}

// ─── Illustration slot with parallax-like entrance ───────────────────────────

class _IllustrationSlot extends StatefulWidget {
  final Widget child;
  const _IllustrationSlot({required this.child});

  @override
  State<_IllustrationSlot> createState() => _IllustrationSlotState();
}

class _IllustrationSlotState extends State<_IllustrationSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Center(child: widget.child),
      ),
    );
  }
}
