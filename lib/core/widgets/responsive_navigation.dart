import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'app_logo.dart';
import '../../data/models/user_model.dart';
import '../../presentation/widgets/avatar_widget.dart';

class ResponsiveNavigation extends StatefulWidget {
  final int currentIndex;
  final Widget child;
  
  // Add debounce to prevent rapid taps
  static DateTime? _lastTapTime;
  static const Duration _debounceTime = Duration(milliseconds: 300);

  const ResponsiveNavigation({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  @override
  State<ResponsiveNavigation> createState() => _ResponsiveNavigationState();
}

class _ResponsiveNavigationState extends State<ResponsiveNavigation> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString("user");

      if (userJson != null) {
        final user = User.fromJson(jsonDecode(userJson));
        setState(() {
          _user = user;
          _isLoading = false;
        });
      } else {
        setState(() {
          _user = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _user = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Screen width breakpoints
    final bool isNarrowWeb = kIsWeb && MediaQuery.of(context).size.width > 600 && MediaQuery.of(context).size.width <= 960;
    final bool isWideWeb = kIsWeb && MediaQuery.of(context).size.width > 960;
    final bool isWeb = isNarrowWeb || isWideWeb;
    
    return Scaffold(
      // For web, use app bar with top navigation
      appBar: isWeb ? _buildWebAppBar(context, isWideWeb: isWideWeb) : null,
      // Drawer for narrow web views
      drawer: isNarrowWeb ? _buildNavigationDrawer(context) : null,
      body: Column(
        children: [
          // Main content
          Expanded(child: widget.child),
        ],
      ),
      // For mobile, use bottom navigation bar
      bottomNavigationBar: isWeb ? null : _buildMobileBottomNavBar(context),
    );
  }

  // Web app bar with horizontal navigation
  PreferredSizeWidget _buildWebAppBar(BuildContext context, {required bool isWideWeb}) {
    return AppBar(
      automaticallyImplyLeading: !isWideWeb, // Show drawer icon on narrow web views
      title: const Row(
        children: [
          // Logo and app name
          AppLogo(height: 30),
          SizedBox(width: 10),
          Text('SkillGenie', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      centerTitle: false, // Align title (logo and name) to the left
      actions: [
        // Navigation items horizontally - only on wide screens
        if (isWideWeb) ...[
          const SizedBox(width: 24), // Add spacing after the logo and name
          _buildNavItem(context, 0, 'Home', Icons.home_outlined),
          _buildNavItem(context, 1, 'Games', Icons.games_outlined),
          _buildNavItem(context, 2, 'Library', Icons.book_outlined),
          _buildNavItem(context, 3, 'Community', Icons.people_outlined),
          
          const Spacer(),
        ],
        
        // Notification bell
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => GoRouter.of(context).go('/notifications'),
        ),
        
        // User profile menu
        const SizedBox(width: 8),
        _buildUserProfileButton(context),
        const SizedBox(width: 16),
      ],
    );
  }

  // Navigation drawer for narrow web views
  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(height: 50),
                const SizedBox(height: 12),
                Text(
                  'SkillGenie',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Drawer navigation items
          _buildDrawerNavItem(context, 0, 'Home', Icons.home_outlined),
          _buildDrawerNavItem(context, 1, 'Games', Icons.games_outlined),
          _buildDrawerNavItem(context, 2, 'Library', Icons.book_outlined),
          _buildDrawerNavItem(context, 3, 'Community', Icons.people_outlined),
          _buildDrawerNavItem(context, 4, 'Profile', Icons.person_outlined),
          
          const Divider(),
          
          // Additional drawer items
          _buildDrawerNavItem(
            context, 
            -1, 
            'Settings', 
            Icons.settings_outlined,
            onTap: () => GoRouter.of(context).go('/settings'),
          ),
        ],
      ),
    );
  }

  // Build a drawer navigation item
  Widget _buildDrawerNavItem(
    BuildContext context, 
    int index, 
    String label, 
    IconData icon, 
    {VoidCallback? onTap}
  ) {
    final bool isSelected = index == widget.currentIndex;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      onTap: onTap ?? () {
        Navigator.pop(context); // Close drawer
        _navigateToTab(context, index);
      },
    );
  }

  // Build the user profile button with popup menu and user's avatar
  Widget _buildUserProfileButton(BuildContext context) {
    return InkWell(
      onTap: () => GoRouter.of(context).go('/profile'),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User avatar - show profile pic if available
            _isLoading 
              ? SizedBox(
                  width: 32, 
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor
                    ),
                  ),
                )
              : _user?.profilePicture != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _user!.profilePicture!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const GenieAvatar(
                        size: 32,
                        state: AvatarState.idle,
                      ),
                    ),
                  )
                : const GenieAvatar(
                    size: 32,
                    state: AvatarState.idle,
                  ),
                
            if (MediaQuery.of(context).size.width > 800) ...[
              const SizedBox(width: 8),
              Text(
                _user?.username ?? 'Profile',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  // Navigation item for web
  Widget _buildNavItem(BuildContext context, int index, String label, IconData icon) {
    final bool isSelected = index == widget.currentIndex;
    
    return InkWell(
      onTap: () => _navigateToTab(context, index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile bottom navigation bar (using existing styles)
  Widget _buildMobileBottomNavBar(BuildContext context) {
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
        currentIndex: _safeIndex(widget.currentIndex),
        onTap: (index) {
          if (_safeIndex(widget.currentIndex) == index || _isNavigationInProgress()) {
            return;
          }
          _navigateToTab(context, index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade400,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games_outlined),
            label: 'Games',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Check if we're in the middle of a navigation
  bool _isNavigationInProgress() {
    final now = DateTime.now();
    if (ResponsiveNavigation._lastTapTime != null &&
        now.difference(ResponsiveNavigation._lastTapTime!) < ResponsiveNavigation._debounceTime) {
      return true;
    }
    ResponsiveNavigation._lastTapTime = now;
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
          GoRouter.of(context).go('/home');
      }
    } catch (e) {
      print('Error in _navigateToTab: $e');
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
      }
    }
  }
}