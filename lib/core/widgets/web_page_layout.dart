import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// A reusable widget for web page layout that includes breadcrumb navigation.
///
/// This widget is designed to be used across the app for consistent web layout.
class WebPageLayout extends StatelessWidget {
  /// The current page title to display in the breadcrumb
  final String pageTitle;
  
  /// The main content of the page
  final Widget child;
  
  /// Optional callback for the home button
  final VoidCallback? onHomePressed;
  
  /// Additional actions to display in the top right
  final List<Widget>? actions;

  const WebPageLayout({
    super.key,
    required this.pageTitle,
    required this.child,
    this.onHomePressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isWeb = kIsWeb && MediaQuery.of(context).size.width > 600;
    
    // If not on web or narrow screen, just return the child directly
    if (!isWeb) {
      return child;
    }
    
    // Using LayoutBuilder to ensure proper constraints are passed down
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb navigation and actions row
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
              child: Row(
                children: [
                  // Breadcrumb navigation
                  Expanded(
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: onHomePressed ?? () => Navigator.pop(context),
                          icon: const Icon(Icons.home_outlined, size: 18),
                          label: const Text('Home'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade600,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
                        Text(
                          pageTitle,
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Optional actions
                  if (actions != null && actions!.isNotEmpty)
                    ...actions!,
                ],
              ),
            ),
            
            // Main content with proper padding
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 