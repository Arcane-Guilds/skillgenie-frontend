import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/user_model.dart';
import '../../../presentation/viewmodels/course_viewmodel.dart';
import '../../../presentation/viewmodels/auth/auth_viewmodel.dart';
import '../../../data/models/course_model.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  
  // User data for streak and progress
  User? _userData;
  
  // Define a getter for userData that never returns null
  User get userData {
    return _userData ?? User(
      id: '',
      username: '',
      email: '',
    );
  }

    Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString("user");

    if (userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));
      return user.id;
    }
    return null;
  }

  void _navigateToQuiz() async {
    final userId = await getUserId();
    if (userId != null) {
      context.push('/quiz/$userId');
    } else {
      // Handle the case when userId is null
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure the widget is built before fetching data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserCourses();
      _loadUserData();
    });
  }

  Future<void> _fetchUserCourses() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    
    if (authViewModel.user != null) {
      await courseViewModel.fetchUserCourses(authViewModel.user!.id);
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString("user");

    if (userJson != null) {
      setState(() {
        _userData = User.fromJson(jsonDecode(userJson));
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchUserCourses();
        await _loadUserData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Courses section
            _buildCoursesSection(),
            
            const SizedBox(height: 80), // Bottom padding for FAB
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserGreeting() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          const SizedBox(height: 10),
                      Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
              Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                    'Hello, ${userData.username}',
                    style: const TextStyle(
                      fontSize: 22,
                                    fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ready to continue learning?',
                                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: userData.avatar != null && userData.avatar!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CachedNetworkImage(
                          imageUrl: userData.avatar!,
                          placeholder: (context, url) => const CircleAvatar(
                            backgroundColor: Colors.white10,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesSection() {
    final courseViewModel = Provider.of<CourseViewModel>(context);
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Courses',
                style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
              ),
              if (!_isLoading && courseViewModel.userCourses.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    // Navigate to all courses view
                  },
                  icon: const Icon(Icons.view_list, size: 16),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          else if (courseViewModel.errorMessage != null)
            _buildErrorMessage(courseViewModel.errorMessage!)
          else if (courseViewModel.userCourses.isEmpty)
            _buildEmptyCoursesMessage()
          else
            _buildCourseList(courseViewModel.userCourses),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading courses',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchUserCourses,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCourseList(List<Course> courses) {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
                    itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(course)
          .animate()
          .fadeIn(duration: 400.ms, delay: 100.ms * index)
          .slideX(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildEmptyCoursesMessage() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.8),
          ),
          const SizedBox(height: 24),
          Text(
            'Start Your Learning Journey',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Take a quick quiz to get personalized course recommendations',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
          ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _navigateToQuiz,
            icon: const Icon(Icons.quiz),
            label: const Text('Take Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95), duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildCourseCard(Course course) {
    final Color courseColor = _getCourseColor(course.title);
    final progress = _calculateCourseProgress(course);
    final completedExercises = _countCompletedExercises(course);
    final totalExercises = _countExercises(course);
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
      onTap: () {
        Future.microtask(() {
          context.push('/course/${course.id}');
        });
      },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Course header with icon and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course icon
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                      color: courseColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getIconForCourse(course.title),
                        color: courseColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Course title and overview
                  Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                        Text(
                          course.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                  Text(
                    course.content.overview,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
                  // Course stats
                  Row(
                    children: [
                      _buildCourseStat(
                        Icons.book,
                        '${course.content.levels.length} Levels',
                      ),
                  const SizedBox(width: 24),
                      _buildCourseStat(
                        Icons.extension,
                    '$totalExercises Exercises',
                      ),
                      const Spacer(),
                      Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: courseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Level ${course.currentLevel + 1}',
                          style: TextStyle(
                        fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: courseColor,
                          ),
                        ),
                      ),
                    ],
                  ),
              
              const SizedBox(height: 20),
              
                  // Progress indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                        '${(progress * 100).toInt()}% Complete',
                            style: TextStyle(
                          fontSize: 14,
                              fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                        '$completedExercises/$totalExercises exercises',
                            style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                  const SizedBox(height: 10),
                      ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(progress == 1.0 ? Colors.green : courseColor),
                      minHeight: 8,
                        ),
                      ),
                    ],
                  ),
              
              const SizedBox(height: 16),
              
              // Continue button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/course/${course.id}');
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Continue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: courseColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseStat(IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  double _calculateCourseProgress(Course course) {
    int totalExercises = 0;
    int completedExercises = 0;
    
    // Check if course.content or course.content.levels is null
    if (course.content.levels.isEmpty) {
      return 0.0;
    }
    
    for (int levelIndex = 0; levelIndex < course.content.levels.length; levelIndex++) {
      final level = course.content.levels[levelIndex];
      
      for (int chapterIndex = 0; chapterIndex < level.chapters.length; chapterIndex++) {
        final chapter = level.chapters[chapterIndex];
        
        for (int exerciseIndex = 0; exerciseIndex < chapter.exercises.length; exerciseIndex++) {
          totalExercises++;
          
          final progressKey = 'L${levelIndex + 1}C${chapterIndex + 1}E${exerciseIndex + 1}';
          
          // Safely get the progress value without casting
          final progress = course.progress[progressKey];
          
          // Check if progress is not null and is at least 1
          if (progress != null && progress >= 1) {
            completedExercises++;
          }
        }
      }
    }
    
    return totalExercises > 0 ? completedExercises / totalExercises : 0.0;
  }

  IconData _getIconForCourse(String courseName) {
    switch (courseName.toLowerCase()) {
      case 'flutter development':
        return Icons.flutter_dash;
      case 'react native':
        return Icons.code;
      case 'node.js':
        return Icons.javascript;
      case 'python':
        return Icons.code;
      case 'machine learning':
        return Icons.psychology;
      case 'web development':
        return Icons.web;
      case 'data analysis mastery':
        return Icons.analytics;
      default:
        return Icons.school;
    }
  }

  // Helper method to get a color based on course title
  Color _getCourseColor(String title) {
    final List<Color> colors = [
      const Color(0xFF1CB0F6), // Blue
      const Color(0xFF58CC02), // Green
      const Color(0xFFFF9600), // Orange
      const Color.fromARGB(255, 85, 196, 221), // Red
      const Color(0xFFA560E8), // Purple
    ];
    
    // Use a hash of the title to pick a consistent color
    final int hash = title.hashCode.abs();
    return colors[hash % colors.length];
  }

  int _countExercises(Course course) {
    int count = 0;
    for (final level in course.content.levels) {
      for (final chapter in level.chapters) {
        count += chapter.exercises.length;
      }
    }
    return count;
  }

  int _countCompletedExercises(Course course) {
    int count = 0;
    for (final entry in course.progress.entries) {
      final progress = entry.value;
      if (progress >= 1) {
        count++;
      }
    }
    return count;
  }
}

// Custom painter for dot pattern
class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const spacing = 20.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}