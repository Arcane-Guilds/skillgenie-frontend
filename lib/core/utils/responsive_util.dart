import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// A utility class for responsive design and device detection
class ResponsiveUtil {
  /// Screen width breakpoints for different device sizes
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if the current device is mobile based on screen width
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if the current device is a tablet based on screen width
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if the current device is a desktop based on screen width
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Check if the current device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get the appropriate padding based on screen size and platform
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (kIsWeb) {
      // On web, adapt based on screen size
      if (isDesktop(context)) {
        return const EdgeInsets.symmetric(horizontal: 64, vertical: 32);
      } else if (isTablet(context)) {
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
      } else {
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
      }
    } else {
      // On mobile devices
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
  }

  /// Get a responsive font size that adapts to the screen size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    double scaleFactor = 1.0;
    
    if (kIsWeb) {
      if (isDesktop(context)) {
        scaleFactor = 1.2;
      } else if (isTablet(context)) {
        scaleFactor = 1.1;
      }
    }
    
    return baseFontSize * scaleFactor;
  }

  /// Get the appropriate content width constraint for responsive layouts
  static BoxConstraints getContentConstraints(BuildContext context) {
    if (kIsWeb) {
      if (isDesktop(context)) {
        return const BoxConstraints(maxWidth: 1200);
      } else if (isTablet(context)) {
        return const BoxConstraints(maxWidth: 800);
      }
    }
    
    // Mobile devices or smaller web screens
    return BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width,
    );
  }
  
  /// Widget builder that returns different widgets based on screen size
  static Widget buildResponsive({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (kIsWeb && isDesktop(context) && desktop != null) {
      return desktop;
    }
    
    if ((kIsWeb || !kIsWeb) && isTablet(context) && tablet != null) {
      return tablet;
    }
    
    return mobile;
  }
} 