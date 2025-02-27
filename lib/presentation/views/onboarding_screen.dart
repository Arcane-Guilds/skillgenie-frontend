import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final horizontalPadding = size.width * 0.1; // 10% padding on each side

    // Calculate responsive sizes
    final logoSize = size.width * (isSmallScreen ? 0.4 : 0.25); // 40% of width on mobile, 25% on larger screens
    final titleFontSize = isSmallScreen ? 24.0 : 32.0;
    final headlineFontSize = isSmallScreen ? 28.0 : 36.0;
    final subheadingFontSize = isSmallScreen ? 18.0 : 22.0;
    final buttonFontSize = isSmallScreen ? 18.0 : 20.0;

    // Calculate maximum content width for larger screens
    const maxContentWidth = 600.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // App Name
                      Text(
                        'SkillGenie',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: size.height * 0.03),
                      // Genie Logo
                      Image.asset(
                        'assets/images/genie.png',
                        height: logoSize,
                        width: logoSize,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: size.height * 0.03),
                      // Headline
                      Text(
                        'Grow Your Skills',
                        style: TextStyle(
                          fontSize: headlineFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: size.height * 0.02),
                      // Subheading
                      Text(
                        'And Be More Creative',
                        style: TextStyle(
                          fontSize: subheadingFontSize,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: size.height * 0.05),
                      // Get Started Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            GoRouter.of(context).go('/signup');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 15 : 20,
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            GoRouter.of(context).go('/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Colors.blue, width: 2),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 15 : 20,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'I already have an account',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}