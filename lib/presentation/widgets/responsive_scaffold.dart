import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/utils/responsive_util.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool? resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBarBottom;
  final Widget? leading;
  
  /// Creates a scaffold that adapts to web or mobile platforms
  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.actions,
    this.centerTitle = true,
    this.drawer,
    this.endDrawer,
    this.resizeToAvoidBottomInset,
    this.backgroundColor,
    this.appBarBottom,
    this.leading,
  });
  
  @override
  Widget build(BuildContext context) {
    // Determine if we're on a mobile-sized screen
    final isMobileSize = ResponsiveUtil.isMobile(context);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: AppBar(
        elevation: kIsWeb ? 1 : null,
        title: Text(
          title,
          style: TextStyle(
            fontSize: kIsWeb && !isMobileSize ? 22 : 20,
          ),
        ),
        centerTitle: kIsWeb ? true : centerTitle,
        actions: actions,
        bottom: appBarBottom,
        leading: leading,
      ),
      body: _buildResponsiveBody(context),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
    );
  }
  
  Widget _buildResponsiveBody(BuildContext context) {
    if (kIsWeb && !ResponsiveUtil.isMobile(context)) {
      // For web on larger screens, center the content and apply max width
      return Center(
        child: ConstrainedBox(
          constraints: ResponsiveUtil.getContentConstraints(context),
          child: _buildContentArea(context),
        ),
      );
    } else {
      // For mobile or mobile-size web screens
      return _buildContentArea(context);
    }
  }
  
  Widget _buildContentArea(BuildContext context) {
    return Padding(
      padding: kIsWeb 
          ? ResponsiveUtil.getScreenPadding(context)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: body,
    );
  }
}

/// A page layout specifically designed for forms (login, signup, etc.)
class ResponsiveFormLayout extends StatelessWidget {
  final String title;
  final Widget form;
  final Widget? footer;
  final bool centerTitle;
  final Widget? logo;
  
  const ResponsiveFormLayout({
    super.key,
    required this.title,
    required this.form,
    this.footer,
    this.centerTitle = true,
    this.logo,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        elevation: kIsWeb ? 0 : 1,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (logo != null) ...[
                    Center(child: logo),
                    const SizedBox(height: 32),
                  ],
                  form,
                  if (footer != null) ...[
                    const SizedBox(height: 24),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 