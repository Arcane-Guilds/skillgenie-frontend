import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/user_model.dart';
import '../../../presentation/viewmodels/course_viewmodel.dart';
import '../../../presentation/viewmodels/auth/auth_viewmodel.dart';
import '../../../data/models/course_model.dart';
import '../../views/course/course_detail_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with SingleTickerProviderStateMixin {

  late TabController _tabController;
  bool _isLoading = true;

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

  /*final List<String> _categories = [
    "All Skills",
    "Popular",
    "Recommended",
    "New"
  ];*/

  // Learning styles from the DTO
  /*final List<Map<String, dynamic>> _learningStyles = [
    {
      'name': 'Visual',
      'description': 'Learn through diagrams, videos, and visual content',
      'icon': Icons.visibility,
      'color': const Color(0xFF58CC02), // Duolingo green
    },
    {
      'name': 'Auditory',
      'description': 'Learn through lectures, podcasts, and discussions',
      'icon': Icons.headphones,
      'color': const Color(0xFF1CB0F6), // Duolingo blue
    },
    {
      'name': 'Kinesthetic',
      'description': 'Learn through hands-on, interactive experiences',
      'icon': Icons.touch_app,
      'color': const Color(0xFFFF9600), // Duolingo orange
    },
  ];*/

  // Skills from the DTO
  final List<Map<String, dynamic>> _skills = [
    {
      'name': 'Flutter Development',
      'description': 'Build beautiful cross-platform apps',
      'icon': 'assets/icons/flutter.png',
      'color': const Color(0xFF1CB0F6),
      'level': 'Beginner',
      'lessons': 12,
      'isPopular': true,
    },
    {
      'name': 'React Native',
      'description': 'Create mobile apps with JavaScript',
      'icon': 'assets/icons/react.png',
      'color': const Color(0xFF58CC02),
      'level': 'Intermediate',
      'lessons': 10,
      'isPopular': true,
    },
    {
      'name': 'Node.js',
      'description': 'Server-side JavaScript programming',
      'icon': 'assets/icons/nodejs.png',
      'color': const Color(0xFFFF9600),
      'level': 'Advanced',
      'lessons': 15,
      'isPopular': false,
    },
    {
      'name': 'Python',
      'description': 'Versatile programming language',
      'icon': 'assets/icons/python.png',
      'color': const Color(0xFFFF4B4B),
      'level': 'Beginner',
      'lessons': 8,
      'isPopular': true,
    },
    {
      'name': 'Machine Learning',
      'description': 'Build intelligent systems',
      'icon': 'assets/icons/ml.png',
      'color': const Color(0xFFA560E8),
      'level': 'Advanced',
      'lessons': 20,
      'isPopular': false,
    },
    {
      'name': 'Web Development',
      'description': 'Create responsive websites',
      'icon': 'assets/icons/web.png',
      'color': const Color(0xFF1CB0F6),
      'level': 'Intermediate',
      'lessons': 14,
      'isPopular': true,
    },
  ];

  // Learning preferences from the DTO
  /*final List<Map<String, dynamic>> _learningPreferences = [
    {
      'name': 'Short lessons',
      'description': 'Quick, focused learning sessions',
      'icon': Icons.timer,
      'color': const Color(0xFF1CB0F6),
    },
    {
      'name': 'In-depth tutorials',
      'description': 'Comprehensive, detailed learning',
      'icon': Icons.menu_book,
      'color': const Color(0xFF58CC02),
    },
    {
      'name': 'Gamified challenges',
      'description': 'Learn through fun, interactive games',
      'icon': Icons.videogame_asset,
      'color': const Color(0xFFFF9600),
    },
    {
      'name': 'Interactive projects',
      'description': 'Hands-on building and creating',
      'icon': Icons.build,
      'color': const Color(0xFFFF4B4B),
    },
  ];*/

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure the widget is built before fetching data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserCourses();
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

  @override
  void dispose() {
    // Dispose of the TabController if it was created
    if (_tabController != null) {
      _tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily streak and stats section
          _buildStreakSection(),

          // Categories tabs
          //_buildCategoriesTabs(),

          // Skills grid
          _buildSkillsGrid(),

          // Learning styles section
          //_buildSectionTitle('Learning Styles'),
          //_buildLearningStylesSection(),

          // Learning preferences section
          //_buildSectionTitle('Learning Preferences'),
          //_buildLearningPreferencesSection(),

          // Chatbot Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => context.push('/chatbot'),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.smart_toy,
                              color: Colors.blue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Assistant',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Chat with our AI assistant to get help with your learning',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 80), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildStreakSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStreakItem(
            icon: Icons.local_fire_department,
            value: '5',
            label: 'Day Streak',
            color: Colors.orange,
          ),
          _buildStreakItem(
            icon: Icons.star,
            value: '240',
            label: 'Total XP',
            color: Colors.amber,
          ),
          _buildStreakItem(
            icon: Icons.emoji_events,
            value: '3',
            label: 'Achievements',
            color: Colors.yellow,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /*Widget _buildCategoriesTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        tabs: _categories.map((category) {
          return Tab(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }*/

  Widget _buildSkillsGrid() {
    final courseViewModel = Provider.of<CourseViewModel>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Continue Learning',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (courseViewModel.errorMessage != null)
            Center(
              child: Text(
                'Error: ${courseViewModel.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (courseViewModel.userCourses.isEmpty)
            _buildEmptyCoursesMessage()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // Determine if we should use grid or list based on screen width
                final isWideScreen = constraints.maxWidth > 600;
                
                if (isWideScreen) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: courseViewModel.userCourses.length,
                    itemBuilder: (context, index) {
                      final course = courseViewModel.userCourses[index];
                      return _buildCourseCard(course);
                    },
                  );
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: courseViewModel.userCourses.length,
                    itemBuilder: (context, index) {
                      final course = courseViewModel.userCourses[index];
                      return _buildCourseCard(course);
                    },
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCoursesMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.school_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No courses yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Take a quiz to get personalized course recommendations',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _navigateToQuiz,
            child: const Text('Take Quiz'),
          )
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final Color courseColor = _getCourseColor(course.title);
    
    return GestureDetector(
      key: ValueKey('course_${course.id}'),
      onTap: () {
        // Use a safer navigation method with future to avoid Hero animation issues
        Future.microtask(() {
          context.push('/course/${course.id}');
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: courseColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course header with color and icon
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: courseColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  // Pattern overlay
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: CustomPaint(
                        painter: DotPatternPainter(),
                      ),
                    ),
                  ),
                  // Course title
                  Positioned(
                    left: 16,
                    bottom: 16,
                    right: 80,
                    child: Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Course icon
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIconForCourse(course.title),
                        color: courseColor,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Course content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.content.overview,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  // Course stats
                  Row(
                    children: [
                      _buildCourseStat(
                        Icons.book,
                        '${course.content.levels.length} Levels',
                      ),
                      const SizedBox(width: 16),
                      _buildCourseStat(
                        Icons.extension,
                        '${_countExercises(course)} Exercises',
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: courseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Level ${course.currentLevel + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: courseColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(_calculateCourseProgress(course) * 100).toInt()}% Complete',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '${_countCompletedExercises(course)}/${_countExercises(course)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _calculateCourseProgress(course),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(courseColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  double _calculateCourseProgress(Course course) {
    int totalExercises = 0;
    int completedExercises = 0;
    
    // Check if course.content or course.content.levels is null
    if (course.content == null || course.content.levels == null) {
      return 0.0;
    }
    
    for (int levelIndex = 0; levelIndex < course.content.levels.length; levelIndex++) {
      final level = course.content.levels[levelIndex];
      
      // Check if level.chapters is null
      if (level.chapters == null) {
        continue;
      }
      
      for (int chapterIndex = 0; chapterIndex < level.chapters.length; chapterIndex++) {
        final chapter = level.chapters[chapterIndex];
        
        // Check if chapter.exercises is null
        if (chapter.exercises == null) {
          continue;
        }
        
        for (int exerciseIndex = 0; exerciseIndex < chapter.exercises.length; exerciseIndex++) {
          totalExercises++;
          
          final progressKey = 'L${levelIndex + 1}C${chapterIndex + 1}E${exerciseIndex + 1}';
          
          // Check if course.progress is null
          if (course.progress == null) {
            continue;
          }
          
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

  // Helper method to get course level based on current level
  String _getCourseLevel(int currentLevel) {
    if (currentLevel == 0) return 'Beginner';
    if (currentLevel == 1) return 'Intermediate';
    return 'Advanced';
  }

  // Helper method to get course progress
  double _getCourseProgress(Course course) {
    if (course.content.levels.isEmpty) return 0.0;
    return course.currentLevel / course.content.levels.length;
  }

  // Helper method to get a color based on course title
  Color _getCourseColor(String title) {
    final List<Color> colors = [
      const Color(0xFF1CB0F6), // Blue
      const Color(0xFF58CC02), // Green
      const Color(0xFFFF9600), // Orange
      const Color(0xFFFF4B4B), // Red
      const Color(0xFFA560E8), // Purple
    ];
    
    // Use a hash of the title to pick a consistent color
    final int hash = title.hashCode.abs();
    return colors[hash % colors.length];
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /*Widget _buildLearningStylesSection() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _learningStyles.length,
        itemBuilder: (context, index) {
          final style = _learningStyles[index];
          return _buildLearningStyleCard(style);
        },
      ),
    );
  }*/

  /*Widget _buildLearningStyleCard(Map<String, dynamic> style) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            style['color'],
            style['color'].withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: style['color'].withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glossy effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(style['icon'], color: style['color'], size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      style['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  style['description'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Learn More',
                      style: TextStyle(
                        color: style['color'],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }*/

  /*Widget _buildLearningPreferencesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _learningPreferences.length,
        itemBuilder: (context, index) {
          final preference = _learningPreferences[index];
          return _buildPreferenceCard(preference);
        },
      ),
    );
  }

  Widget _buildPreferenceCard(Map<String, dynamic> preference) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glossy effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    preference['color'].withOpacity(0.2),
                    preference['color'].withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  preference['icon'],
                  color: preference['color'],
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  preference['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  preference['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }*/

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
      final progress = (entry.value as int?) ?? 0; // Ensure it's an int
      if (progress >= 1) { // Now it's a valid boolean condition
        count++;
      }
    }
    return count;
  }

}

IconData _getIconForSkill(String skillName) {
  switch (skillName.toLowerCase()) {
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
    default:
      return Icons.school;
  }
}

class SkillRoadmapScreen extends StatefulWidget {
  final Map<String, dynamic> skill;

  const SkillRoadmapScreen({
    Key? key,
    required this.skill,
  }) : super(key: key);

  @override
  State<SkillRoadmapScreen> createState() => _SkillRoadmapScreenState();
}

class _SkillRoadmapScreenState extends State<SkillRoadmapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  final double _userProgress = 0.4; // 40% progress through the roadmap

  // Sample lessons for the roadmap
  late List<Map<String, dynamic>> _lessons;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: _userProgress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Generate lessons based on the skill
    _generateLessons();
  }

  void _generateLessons() {
    // Create lessons based on the skill's lesson count
    final int lessonCount = widget.skill['lessons'] as int;
    _lessons = List.generate(lessonCount, (index) {
      final bool isCompleted = index < (lessonCount * _userProgress).floor();
      final bool isCurrent = index == (lessonCount * _userProgress).floor();

      return {
        'id': index + 1,
        'title': 'Lesson ${index + 1}',
        'description': _getLessonDescription(widget.skill['name'], index),
        'isCompleted': isCompleted,
        'isCurrent': isCurrent,
        'isLocked': !isCompleted && !isCurrent,
        'xpReward': 10 + (index * 5),
        'duration': '${5 + (index * 2)} min',
        'challenges': 2 + (index % 3), // Number of challenges in the lesson
        'concepts': 3 + (index % 4), // Number of concepts covered
      };
    });
  }

  String _getLessonDescription(String skillName, int index) {
    final List<String> descriptions = [
      'Introduction to $skillName basics',
      'Core concepts and fundamentals',
      'Building your first project',
      'Advanced techniques and patterns',
      'Best practices and optimization',
      'Real-world application development',
      'Testing and debugging strategies',
      'Performance optimization techniques',
      'Integration with other technologies',
      'Deployment and publishing workflow',
    ];

    return descriptions[index % descriptions.length];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressHeader(),
                _buildRoadmap(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'start_lesson_fab',
        onPressed: () {
          // Start the current lesson
          final currentLesson = _lessons.firstWhere((lesson) => lesson['isCurrent'], orElse: () => _lessons.first);
          _showLessonStartDialog(currentLesson);
        },
        backgroundColor: const Color(0xFF8470FF),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Lesson'),
        elevation: 4,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: widget.skill['color'],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.skill['name'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 4.0,
                color: Colors.black26,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.skill['color'],
                    widget.skill['color'].withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Pattern overlay (dots)
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: DotPatternPainter(),
                ),
              ),
            ),
            // Glossy effect
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.4),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Skill icon with animated glow
            Positioned(
              top: 50,
              right: 20,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.skill['color'].withOpacity(0.3 + (0.2 * math.sin(value * math.pi * 2))),
                          blurRadius: 15 + (5 * math.sin(value * math.pi * 2)),
                          spreadRadius: 2 + (1 * math.sin(value * math.pi * 2)),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: ClipOval(
                  child: Stack(
                    children: [
                      // Icon
                      Center(
                        child: Icon(
                          _getIconForSkill(widget.skill['name']),
                          color: widget.skill['color'],
                          size: 45,
                        ),
                      ),
                      // Glossy effect
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.7),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.skill['color'].withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.trending_up,
                  color: widget.skill['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Progress',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.skill['level']} · ${widget.skill['lessons']} lessons',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${(_progressAnimation.value * 100).toInt()}% Complete',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.skill['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(_progressAnimation.value * widget.skill['lessons']).floor()}/${widget.skill['lessons']} lessons',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: widget.skill['color'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      // Background track
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Progress indicator
                      Container(
                        height: 12,
                        width: MediaQuery.of(context).size.width * _progressAnimation.value * 0.85, // Adjust for padding
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.skill['color'],
                              const Color(0xFF8470FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: widget.skill['color'].withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmap() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.skill['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.route,
                    color: widget.skill['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Your Learning Path',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Roadmap path
          Stack(
            children: [
              // Path line
              Positioned(
                left: 24,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Progress line (animated)
              Positioned(
                left: 24,
                top: 0,
                width: 4,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Container(
                      height: (_lessons.length * 140 * _progressAnimation.value),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            widget.skill['color'],
                            const Color(0xFF8470FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: widget.skill['color'].withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Lesson nodes
              Column(
                children: _lessons.map((lesson) => _buildLessonNode(lesson)).toList(),
              ),
            ],
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildLessonNode(Map<String, dynamic> lesson) {
    final bool isCompleted = lesson['isCompleted'];
    final bool isCurrent = lesson['isCurrent'];
    final bool isLocked = lesson['isLocked'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node circle with animation for current node
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: isCurrent ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                width: 50 + (value * 4),
                height: 50 + (value * 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? widget.skill['color']
                      : isCurrent
                      ? Colors.white
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: widget.skill['color'], width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: (isCompleted || isCurrent)
                          ? widget.skill['color'].withOpacity(0.3 + (value * 0.2))
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 8 + (value * 4),
                      spreadRadius: value * 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: isLocked
                      ? const Icon(Icons.lock, color: Colors.grey, size: 20)
                      : isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : Text(
                    lesson['id'].toString(),
                    style: TextStyle(
                      color: isCurrent ? widget.skill['color'] : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            },
          ),
          // Lesson content
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isLocked) {
                  _showLessonStartDialog(lesson);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isLocked
                          ? Colors.grey.withOpacity(0.1)
                          : widget.skill['color'].withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: isCurrent
                      ? Border.all(color: widget.skill['color'], width: 2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lesson['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isLocked ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLocked
                                ? Colors.grey[200]
                                : widget.skill['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${lesson['xpReward']} XP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isLocked ? Colors.grey : widget.skill['color'],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lesson['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isLocked ? Colors.grey : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Lesson stats row
                    Row(
                      children: [
                        _buildLessonStat(
                            Icons.access_time,
                            lesson['duration'],
                            isLocked
                        ),
                        const SizedBox(width: 16),
                        _buildLessonStat(
                            Icons.extension,
                            '${lesson['challenges']} challenges',
                            isLocked
                        ),
                        const SizedBox(width: 16),
                        _buildLessonStat(
                            Icons.lightbulb_outline,
                            '${lesson['concepts']} concepts',
                            isLocked
                        ),
                      ],
                    ),
                    if (isCurrent) const SizedBox(height: 12),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8470FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF8470FF).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              size: 16,
                              color: Color(0xFF8470FF),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'CURRENT LESSON',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8470FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonStat(IconData icon, String text, bool isLocked) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isLocked ? Colors.grey : Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isLocked ? Colors.grey : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showLessonStartDialog(Map<String, dynamic> lesson) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.skill['color'],
                          const Color(0xFF8470FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.skill['color'].withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                  // Glossy effect
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.4),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                  // XP badge
                  Positioned(
                    bottom: -10,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${lesson['xpReward']} XP',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Start ${lesson['title']}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                lesson['description'],
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Lesson stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDialogStat(
                      Icons.access_time,
                      lesson['duration'],
                      'Duration',
                    ),
                    _buildDialogStat(
                      Icons.extension,
                      '${lesson['challenges']}',
                      'Challenges',
                    ),
                    _buildDialogStat(
                      Icons.lightbulb_outline,
                      '${lesson['concepts']}',
                      'Concepts',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Here you would navigate to the actual lesson content
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Starting ${lesson['title']}...'),
                      backgroundColor: const Color(0xFF8470FF),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8470FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow),
                    const SizedBox(width: 8),
                    const Text(
                      'Begin Lesson',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.skill['color'].withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: widget.skill['color'],
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
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