import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility functions for UI related functionality
class UiUtils {
  /// Determines if the AppBar should be shown based on platform
  /// 
  /// Returns null for web platforms (to hide AppBar) and returns the provided AppBar for mobile
  static PreferredSizeWidget? getResponsiveAppBar(PreferredSizeWidget appBar) {
    return kIsWeb ? null : appBar;
  }
  
  /// Creates an AppBar with the given title that will only be displayed on mobile
  static PreferredSizeWidget? responsiveAppBar({
    required String title,
    List<Widget>? actions,
    bool centerTitle = true,
    PreferredSizeWidget? bottom,
    Widget? leading,
    Color? backgroundColor,
  }) {
    if (kIsWeb) return null;
    
    return AppBar(
      title: Text(title),
      actions: actions,
      centerTitle: centerTitle,
      bottom: bottom,
      leading: leading,
      backgroundColor: backgroundColor,
    );
  }
} 