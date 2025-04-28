# UI Utils Documentation

## Responsive AppBar for Web/Mobile

The `UiUtils` class provides utilities to create responsive UI elements that adapt to web or mobile platforms.

### Hiding AppBars in Web Mode

In our application, we want to hide AppBars inside individual screens when running in web mode, while still maintaining the overall navigation structure.

#### How to Use:

1. **Using the Utility Method:**

   ```dart
   import '../../../core/utils/ui_utils.dart';
   
   // Inside your build method:
   appBar: UiUtils.responsiveAppBar(
     title: 'Screen Title',
     actions: [/* your action buttons */],
     // Other AppBar properties...
   ),
   ```

2. **Conditional Rendering:**

   If you have a custom AppBar, you can use the following pattern:

   ```dart
   import 'package:flutter/foundation.dart' show kIsWeb;
   
   // Inside your build method:
   if (!kIsWeb)
     Padding(
       padding: EdgeInsets.all(16),
       child: YourCustomAppBarWidget(), 
     ),
   ```

3. **Converting Existing AppBars:**

   Replace:
   ```dart
   appBar: AppBar(
     title: Text('Screen Title'),
     // Other properties...
   ),
   ```

   With:
   ```dart
   appBar: UiUtils.responsiveAppBar(
     title: 'Screen Title',
     // Other properties...
   ),
   ```

### Guidelines:

1. Use this pattern for all screens that should have their AppBar hidden in web mode.
2. The main navigation structure (ResponsiveNavigation) will continue to provide navigation in web mode.
3. For very custom AppBar designs, use conditional rendering with `kIsWeb` check.

### Usage Examples:

- See `challenges_library_screen.dart` for conditional rendering of a custom AppBar
- See `games_screens.dart` for using the utility method 