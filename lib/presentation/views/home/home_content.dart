import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
   // _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    //_tabController.dispose();
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.95,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _skills.length,
            itemBuilder: (context, index) {
              final skill = _skills[index];
              return _buildSkillCard(skill);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> skill) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SkillRoadmapScreen(skill: skill),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: skill['color'].withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Skill icon with glossy effect
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: skill['color'].withOpacity(0.1),
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      skill['color'].withOpacity(0.7),
                      skill['color'],
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: skill['color'].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    children: [
                      // Icon
                      Center(
                        child: Icon(
                          _getIconForSkill(skill['name']),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      // Glossy effect
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.4),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Skill name
              Text(
                skill['name'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Skill level and lessons in a row to save space
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: skill['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      skill['level'],
                      style: TextStyle(
                        fontSize: 10,
                        color: skill['color'],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${skill['lessons']} lessons',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Popular badge if applicable
              if (skill['isPopular'])
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Popular',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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