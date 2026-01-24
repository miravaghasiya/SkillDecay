import 'package:flutter/material.dart';
import 'package:micro_skill_decay_detector/config/theme.dart';
import 'package:micro_skill_decay_detector/screens/login/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: "SkillDecay",
      description: "Never Forget What You Learn",
      icon: Icons.bolt_outlined, // Placeholder for the first image
      isIntro: true,
    ),
    OnboardingContent(
      title: "Track Your Skills",
      description:
          "Our AI detects when you're about to forget and reminds you to practice",
      icon: Icons.show_chart, // Placeholder for the second image
      isIntro: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PopScope(
        canPop: _currentPage == 0,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          if (_currentPage > 0) {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                physics: const BouncingScrollPhysics(), // Basic physics
                itemCount: _contents.length,
                itemBuilder: (context, index) => OnboardingPage(
                  content: _contents[index],
                ),
              ),
            ),
            // Bottom Section (Indicators + Buttons)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _contents.length + 1, // Adding 1 just to match the visual of 3 dots if needed, but sticking to logic
                      // Wait, the design shows 3 dots. I'll make it static 3 for visual fidelity even if I have 2 pages.
                      // Actually, let's just show the collected pages.
                      (index) => buildDot(
                          index: index, 
                          // Mocking 3 dots: 0, 1, 2. If current page is 0, dot 0 is active.
                          // If current page is 1, dot 1 is active.
                          isActive: _currentPage == index || (index == 2 && false)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Buttons
                  if (_currentPage == _contents.length - 1) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () {
                           // Navigate to Login or Dashboard
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()), 
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B), // Dark Blue/Slate
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Next",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                         // Skip action
                         Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                      },
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Empty space or Next arrow if first screen needed it?
                    // Design 1 shows dots but no buttons visible at bottom in partial screenshot.
                    // Usually first screen auto-slides or has tap to continue.
                    // For now, I'll allow swiping and maybe a subtle prompt or just empty space.
                    const SizedBox(height: 56 + 16 + 20), // Placeholder space to keep dots stable
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget buildDot({required int index, required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 6,
      width: isActive ? 24 : 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;
  final bool isIntro;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
    this.isIntro = false,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingContent content;

  const OnboardingPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Spacer(),
          // Icon / Image
          Container(
             // width: 120, // Removing fixed size to let it be flexible
             // height: 120,
             child: content.isIntro 
               ? Container(
                   height: 300, 
                   width: 300,
                   // Removed manual circular border to let the new logo asset shine as-is
                   decoration: BoxDecoration(
                     color: Colors.transparent, 
                     // Added subtle shadow if logo is transparent, otherwise optional.
                     // Assuming new logo is a self-contained badge.
                     // If it's a square badge, we can add a shadow to it.
                      borderRadius: BorderRadius.circular(24), // matching assumed logo radius or just soft
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                   ),
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(24),
                     child: Image.asset(
                       'assets/images/logo.png',
                       fit: BoxFit.contain,
                     ),
                   ),
                 )
               : Icon(
                   content.icon,
                   size: 100,
                   color: const Color(0xFF1E293B),
                 ),
          ),
          const SizedBox(height: 32),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          // Spacer(),
        ],
      ),
    );
  }
}
