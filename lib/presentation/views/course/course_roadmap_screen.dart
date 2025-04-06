import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../../data/models/course_model.dart';
import '../../viewmodels/course_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import 'course_detail_screen.dart';

class CourseRoadmapScreen extends StatefulWidget {
  final String courseId;

  const CourseRoadmapScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  State<CourseRoadmapScreen> createState() => _CourseRoadmapScreenState();
}

class _CourseRoadmapScreenState extends State<CourseRoadmapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _lessons = [];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _loadCourse();
  }

  Future<void> _loadCourse() async {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await courseViewModel.fetchCourseById(widget.courseId);

      if (courseViewModel.currentCourse != null) {
        _generateLessons(courseViewModel.currentCourse!);

        // Calculate progress
        final progress = _calculateCourseProgress(courseViewModel.currentCourse!);

        _progressAnimation = Tween<double>(
          begin: 0.0,
          end: progress,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ));

        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load course: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateLessons(Course course) {
    _lessons = [];
    
    // Generate lessons based on the course structure
    for (int levelIndex = 0; levelIndex < course.content.levels.length; levelIndex++) {
      final level = course.content.levels[levelIndex];
      
      // Add a level header
      _lessons.add({
        'id': _lessons.length + 1,
        'isLevelHeader': true,
        'levelIndex': levelIndex,
        'title': 'Level ${level.levelNumber}: ${level.title}',
        'description': level.narrative,
        'isCompleted': levelIndex < course.currentLevel,
        'isCurrent': levelIndex == course.currentLevel,
        'isLocked': levelIndex > course.currentLevel,
        'xpReward': 50 + (levelIndex * 25),
      });
      
      for (int chapterIndex = 0; chapterIndex < level.chapters.length; chapterIndex++) {
        final chapter = level.chapters[chapterIndex];
        
        // Determine if this chapter is completed, current, or locked
        final bool isLevelLocked = levelIndex > course.currentLevel;
        final bool isChapterLocked = levelIndex == course.currentLevel && 
                                    chapterIndex > 0 && 
                                    !_isPreviousChapterCompleted(course, levelIndex, chapterIndex);
        
        final bool isLocked = isLevelLocked || isChapterLocked;
        final bool isCompleted = _isChapterCompleted(course, levelIndex, chapterIndex);
        final bool isCurrent = !isCompleted && !isLocked && levelIndex == course.currentLevel;
        
        _lessons.add({
          'id': _lessons.length + 1,
          'isLevelHeader': false,
          'levelIndex': levelIndex,
          'chapterIndex': chapterIndex,
          'title': chapter.title,
          'description': chapter.story,
          'isCompleted': isCompleted,
          'isCurrent': isCurrent,
          'isLocked': isLocked,
          'xpReward': 10 + ((levelIndex * level.chapters.length + chapterIndex) * 5),
          'duration': '${5 + ((levelIndex * level.chapters.length + chapterIndex) * 2)} min',
          'challenges': chapter.exercises.length,
          'concepts': 3 + (chapterIndex % 4), // Placeholder for concept count
        });
      }
    }
  }

  bool _isChapterCompleted(Course course, int levelIndex, int chapterIndex) {
    final level = course.content.levels[levelIndex];
    final chapter = level.chapters[chapterIndex];

    // Check if all exercises in the chapter are completed
    for (int exerciseIndex = 0; exerciseIndex < chapter.exercises.length; exerciseIndex++) {
      final progressKey = 'L${levelIndex + 1}C${chapterIndex + 1}E${exerciseIndex + 1}';
      final progress = course.progress[progressKey] ?? 0;

      if (progress < 1) {
        return false;
      }
    }

    return true;
  }

  bool _isPreviousChapterCompleted(Course course, int levelIndex, int chapterIndex) {
    if (chapterIndex == 0) return true;
    return _isChapterCompleted(course, levelIndex, chapterIndex - 1);
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseViewModel>(
      builder: (context, courseViewModel, child) {
        final course = courseViewModel.currentCourse;

        if (_isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_errorMessage != null) {
          return Scaffold(
            body: Center(child: Text('Error: $_errorMessage')),
          );
        }

        if (course == null) {
          return const Scaffold(
            body: Center(child: Text('Course not found')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(course),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressHeader(course),
                    _buildRoadmap(),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: Consumer<CourseViewModel>(
            builder: (context, courseViewModel, child) {
              final course = courseViewModel.currentCourse;
              if (course == null) return const SizedBox.shrink();
              
              return FloatingActionButton.extended(
                heroTag: 'course_continue_fab',
                onPressed: () {
                  // Navigate to the current level and chapter
                  if (course.currentLevel < course.content.levels.length) {
                    final level = course.content.levels[course.currentLevel];
                    if (level.chapters.isNotEmpty) {
                      // Find the first incomplete chapter in the current level
                      int chapterIndex = 0;
                      for (int i = 0; i < level.chapters.length; i++) {
                        if (!_isChapterCompleted(course, course.currentLevel, i)) {
                          chapterIndex = i;
                          break;
                        }
                      }
                      
                      context.push(
                        '/course-detail/${course.id}?level=${course.currentLevel}&chapter=${chapterIndex}'
                      );
                    }
                  }
                },
                backgroundColor: Theme.of(context).primaryColor,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Continue Learning'),
                elevation: 4,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAppBar(Course course) {
    final Color courseColor = _getCourseColor(course.title);
    
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: courseColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/home'),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          course.title,
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
                    courseColor,
                    courseColor.withOpacity(0.7),
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
            // Course icon with animated glow
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
                          color: courseColor.withOpacity(0.3 + (0.2 * math.sin(value * math.pi * 2))),
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
                          _getIconForCourse(course.title),
                          color: courseColor,
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

  Widget _buildProgressHeader(Course course) {
    final Color courseColor = _getCourseColor(course.title);
    
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
          // Course Overview
          Text(
            course.content.overview,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          
          // Course Story
          if (course.content.story.narrative.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: courseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: courseColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories, color: courseColor),
                      const SizedBox(width: 8),
                      Text(
                        'Your Journey',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: courseColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.content.story.narrative,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Progress Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: courseColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.trending_up,
                  color: courseColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Level ${course.currentLevel + 1} · ${course.content.levels.length} levels',
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
                          color: courseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_lessons.where((l) => l['isCompleted']).length}/${_lessons.length} chapters',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: courseColor,
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
                              courseColor,
                              Theme.of(context).primaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: courseColor.withOpacity(0.4),
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
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.route,
                    color: Theme.of(context).primaryColor,
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
          
          // Course Learning Path Skills
          Consumer<CourseViewModel>(
            builder: (context, courseViewModel, child) {
              final course = courseViewModel.currentCourse;
              if (course != null && course.content.learningPath != null && 
                  course.content.learningPath!.skills.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Skills You\'ll Master',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: course.content.learningPath!.skills.map((skill) {
                          return Chip(
                            label: Text(skill),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          );
                        }).toList(),
                      ),
                      if (course.content.learningPath!.finalProject.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.engineering,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Final Project',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course.content.learningPath!.finalProject,
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
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
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
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
    final bool isLevelHeader = lesson['isLevelHeader'] ?? false;
    final Color courseColor = Theme.of(context).primaryColor;

    if (isLevelHeader) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16, top: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Node circle for level
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCompleted
                    ? courseColor
                    : isCurrent
                    ? Colors.white
                    : Colors.grey[200],
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(color: courseColor, width: 3)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: (isCompleted || isCurrent)
                        ? courseColor.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock, color: Colors.grey, size: 24)
                    : isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : Icon(
                  Icons.school,
                  color: isCurrent ? courseColor : Colors.grey,
                  size: 24,
                ),
              ),
            ),
            // Level header content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isLocked
                          ? Colors.grey.withOpacity(0.1)
                          : courseColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: isCurrent
                      ? Border.all(color: courseColor, width: 2)
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
                              fontSize: 18,
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
                                : courseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${lesson['xpReward']} XP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isLocked ? Colors.grey : courseColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (lesson['description'] != null && lesson['description'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        lesson['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: isLocked ? Colors.grey : Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (isCurrent) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: courseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: courseColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              size: 16,
                              color: courseColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'CURRENT LEVEL',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: courseColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Regular chapter node
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
                      ? courseColor
                      : isCurrent
                      ? Colors.white
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: courseColor, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: (isCompleted || isCurrent)
                          ? courseColor.withOpacity(0.3 + (value * 0.2))
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
                      color: isCurrent ? courseColor : Colors.grey,
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
                  _navigateToChapter(lesson);
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
                          : courseColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: isCurrent
                      ? Border.all(color: courseColor, width: 2)
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
                                : courseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${lesson['xpReward']} XP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isLocked ? Colors.grey : courseColor,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Lesson stats row
                    Wrap(
                      spacing: 16,
                      children: [
                        _buildLessonStat(
                            Icons.access_time,
                            lesson['duration'],
                            isLocked
                        ),
                        _buildLessonStat(
                            Icons.extension,
                            '${lesson['challenges']} exercises',
                            isLocked
                        ),
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
                          color: courseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: courseColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              size: 16,
                              color: courseColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'CURRENT CHAPTER',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: courseColor,
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

  void _navigateToChapter(Map<String, dynamic> lesson) {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    final course = courseViewModel.currentCourse;
    
    if (course != null) {
      // Check if this is a level header
      if (lesson['isLevelHeader'] == true) {
        // For level headers, navigate to the first chapter of that level
        final levelIndex = lesson['levelIndex'];
        if (levelIndex < course.content.levels.length && !lesson['isLocked']) {
          context.push(
            '/course-detail/${course.id}?level=${levelIndex}&chapter=0'
          );
        }
      } else {
        // For regular chapters, navigate to the specific chapter
        context.push(
          '/course-detail/${course.id}?level=${lesson['levelIndex']}&chapter=${lesson['chapterIndex']}'
        );
      }
    }
  }

  // Helper methods
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