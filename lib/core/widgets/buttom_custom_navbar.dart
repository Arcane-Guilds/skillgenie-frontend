import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  // Add debounce to prevent rapid taps
  static DateTime? _lastTapTime;
  static const Duration _debounceTime = Duration(milliseconds: 300);

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _safeIndex(currentIndex),
        onTap: (index) {
          // Skip navigation if we're already on this tab or tapped too quickly
          if (_safeIndex(currentIndex) == index || _isNavigationInProgress()) {
            return;
          }
          _navigateToTab(context, index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade400,
        // Use minimal elevation to reduce lag when switching
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games_outlined),
            label: 'games',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Check if we're in the middle of a navigation
  bool _isNavigationInProgress() {
    final now = DateTime.now();
    if (_lastTapTime != null && 
        now.difference(_lastTapTime!) < _debounceTime) {
      return true;
    }
    _lastTapTime = now;
    return false;
  }

  // Helper method to ensure index is within valid range
  int _safeIndex(int index) {
    if (index < 0) return 0;
    if (index > 4) return 4;
    return index;
  }

  void _navigateToTab(BuildContext context, int index) {
    try {
      switch (index) {
        case 0:
          GoRouter.of(context).go('/home');
          break;
        case 1:
          GoRouter.of(context).go('/games');
          break;
        case 2:
          GoRouter.of(context).go('/library');
          break;
        case 3:
          GoRouter.of(context).go('/community');
          break;
        case 4:
          GoRouter.of(context).go('/profile');
          break;
        default:
          // Default to home tab if index is invalid
          GoRouter.of(context).go('/home');
      }
    } catch (e) {
      print('Error in _navigateToTab: $e');
      // Fallback to try/catch with context.go
      try {
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/games');
            break;
          case 2:
            context.go('/library');
            break;
          case 3:
            context.go('/community');
            break;
          case 4:
            context.go('/profile');
            break;
          default:
            context.go('/home');
        }
      } catch (e2) {
        print('Second error in _navigateToTab: $e2');
        // No further fallback available
      }
    }
  }
}

