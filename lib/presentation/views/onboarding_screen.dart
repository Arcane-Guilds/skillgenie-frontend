import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:skillGenie/core/theme/app_theme.dart';
import 'package:skillGenie/presentation/widgets/avatar_widget.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  bool _isLastPage = false;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Welcome to SkillGenie',
      'description': 'Your magical companion in the journey of learning',
      'isGenie': true,
      'backgroundColor': AppTheme.backgroundColor,
      'textColor': AppTheme.primaryColor,
    },
    {
      'title': 'Learn New Skills',
      'description': 'Explore a variety of courses tailored just for you',
      'animation': 'assets/images/motivation.json',
      'isGenie': false,
      'backgroundColor': AppTheme.backgroundColor.withOpacity(0.95),
      'textColor': AppTheme.primaryColor,
    },
    {
      'title': 'Track Your Progress',
      'description': 'Watch your skills grow with interactive lessons',
      'animation': 'assets/images/check.json',
      'isGenie': false,
      'backgroundColor': AppTheme.backgroundColor.withOpacity(0.9),
      'textColor': AppTheme.primaryColor,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pages[_currentPage]['backgroundColor'],
      body: Stack(
        children: [
          // Skip button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _handleSkip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 16,
                      color: _pages[_currentPage]['textColor'],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Page content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _isLastPage = index == _pages.length - 1;
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // GenieAvatar or Lottie
                    if (page['isGenie'])
                      const GenieAvatar(
                        state: AvatarState.celebrating,
                        size: 180,
                        message: "Welcome to SkillGenie!",
                      )
                    else
                      Lottie.asset(
                        page['animation'],
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    const SizedBox(height: 40),
                    // Card for text
                    Card(
                      color: AppTheme.surfaceColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Column(
                          children: [
                            Text(
                              page['title'],
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: page['textColor'],
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page['description'],
                              style: const TextStyle(
                                fontSize: 18,
                                color: AppTheme.textSecondaryColor,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Reserve space for bottom navigation
                    const SizedBox(height: 120),
                  ],
                ),
              );
            },
          ),

          // Bottom navigation and indicators
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotColor: _pages[_currentPage]['textColor'].withOpacity(0.3),
                      activeDotColor: _pages[_currentPage]['textColor'],
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isLastPage ? 200 : 60,
                    height: 60,
                    curve: Curves.easeInOut,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isLastPage) {
                          context.go('/genie-story');
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage]['textColor'].withOpacity(0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                        padding: EdgeInsets.zero,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isLastPage
                            ? const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSkip() {
    context.go('/genie-story');
  }
}