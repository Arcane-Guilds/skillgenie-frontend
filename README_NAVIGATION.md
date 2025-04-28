# Responsive Navigation for SkillGenie

This document describes the responsive navigation implementation for SkillGenie which adapts between mobile and web interfaces.

## Components

1. **ResponsiveNavigation** (`responsive_navigation.dart`)  
   Main component that handles screen size detection and conditionally renders:
   - Bottom navigation for mobile devices
   - Top navigation bar with horizontal menu for desktop web
   - Top navigation with drawer for narrow web views
   - Displays the user's profile picture in the navigation bar

2. **AppLogo** (`app_logo.dart`)  
   A component to handle displaying the app logo that:
   - Uses SVG when available
   - Falls back to a styled text logo when SVG isn't available

## User Profile Integration

The navigation now shows the user's profile information:

1. User profile picture is displayed in the top-right corner on web views
2. Username is shown next to the profile picture on wider screens
3. Avatar widget is used as a fallback if no profile picture is available
4. A loading indicator is shown while user data is being fetched

## Responsive Breakpoints

- **Mobile**: Width <= 600px  
  Uses bottom navigation bar (existing mobile UI)

- **Narrow Web**: 600px < Width <= 960px  
  Uses top app bar with drawer navigation

- **Wide Web**: Width > 960px  
  Uses top app bar with horizontal navigation items

## Usage

The responsive navigation is automatically applied through the ShellScaffold wrapper in the app's router.

## Features

- **Platform Adaptive**: Uses appropriate navigation patterns for each platform
- **Responsive**: Adjusts layout based on screen width
- **Consistent**: Maintains visual style across platforms
- **Resource-aware**: Includes fallback for logo and assets
- **User-centric**: Displays user profile information appropriately

## Implementation Notes

1. The navigation doesn't require any changes to existing routes
2. Mobile navigation remains unchanged to maintain existing UX
3. Web navigation introduces proper web patterns like top navigation bar
4. Medium-sized screens (narrow web) use a drawer for better space utilization
5. User profile and notification icons remain consistently accessible across layouts
6. The User model has been updated to handle profilePicture field
7. A fallback mechanism for the SVG logo has been implemented 