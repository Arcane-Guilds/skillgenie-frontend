import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// This file contains web-specific code and is only used on web platform

void configureApp() {
  // Set URL strategy for web
  setUrlStrategy(PathUrlStrategy());
} 