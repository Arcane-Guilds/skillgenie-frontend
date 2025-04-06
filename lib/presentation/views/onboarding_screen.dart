import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:math' as math;

import '../../core/navigation/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  bool _isLastPage = false;
  int _currentPage = 0;

  // Use the app's theme colors
  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Welcome to SkillGenie',
      'description': 'Your magical companion in the journey of learning',
      'animation': 'assets/images/genie.png',
      'isImage': true,
      'backgroundColor': Color(0xFFE6F4FF), // Light variation of primary color
      'textColor': Color(0xFF1CB0F6), // Primary color
    },
    {
      'title': 'Learn New Skills',
      'description': 'Explore a variety of courses tailored just for you',
      'animation': 'assets/images/motivation.json',
      'isImage': false,
      'backgroundColor': Color(0xFFF0F9EA), // Light variation of secondary color
      'textColor': Color(0xFF58CC02), // Secondary color
    },
    {
      'title': 'Track Your Progress',
      'description': 'Watch your skills grow with interactive lessons',
      'animation': 'assets/images/check.json',
      'isImage': false,
      'backgroundColor': Color(0xFFFFF4E6), // Light variation of accent color
      'textColor': Color(0xFFFF9600), // Accent color
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
      body: Stack(
        children: [
          // Background color animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: _pages[_currentPage]['backgroundColor'],
            curve: Curves.easeInOut,
          ),

          // Skip button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () => context.go('/signup'),
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
              return OnboardingPage(
                title: _pages[index]['title'],
                description: _pages[index]['description'],
                animation: _pages[index]['animation'],
                isImage: _pages[index]['isImage'],
                animationController: _animationController,
                textColor: _pages[index]['textColor'],
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
                          context.go('/signup');
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage]['textColor'].withOpacity(0.3), // Primary color
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
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String animation;
  final bool isImage;
  final AnimationController animationController;
  final Color textColor;

  const OnboardingPage({
    Key? key,
    required this.title,
    required this.description,
    required this.animation,
    required this.isImage,
    required this.animationController,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Top section for image/animation (50% of available height)
              SizedBox(
                height: constraints.maxHeight * 0.5,
                child: Center(
                  child: isImage
                      ? Hero(
                    tag: 'onboarding-hero-${DateTime.now().millisecondsSinceEpoch}',
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: const Offset(0, -0.05),
                      ).animate(animationController),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          animation,
                          height: constraints.maxHeight * 0.3,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                      : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Lottie.asset(
                      animation,
                      height: constraints.maxHeight * 0.3,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Bottom section for text
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF6F6F6F), // textPrimaryColor from theme
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Reserve space for bottom navigation
              SizedBox(height: 120),
            ],
          );
        },
      ),
    );
  }
}