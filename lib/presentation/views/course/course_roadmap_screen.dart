import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:skillGenie/data/models/user_model.dart';
import 'package:skillGenie/presentation/viewmodels/auth/auth_viewmodel.dart';

import '../../../data/models/course_model.dart';
import '../../viewmodels/course_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/avatar_widget.dart';

class CourseRoadmapScreen extends StatefulWidget {
  final String courseId;

  const CourseRoadmapScreen({super.key, required this.courseId});

  @override
  State<CourseRoadmapScreen> createState() => _CourseRoadmapScreenState();
}

class _CourseRoadmapScreenState extends State<CourseRoadmapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _lessons = [];
  bool _showingGenieMessage = true;
  late List<bool> _expandedLevels;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Initialize all levels as expanded
    _expandedLevels = List.generate(10, (_) => true); // Placeholder, will be updated after loading

    // Auto-hide Genie message after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showingGenieMessage = false;
        });
      }
    });

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
        _expandedLevels = List.generate(courseViewModel.currentCourse!.content.levels.length, (_) => true);

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

    for (int levelIndex = 0; levelIndex < course.content.levels.length; levelIndex++) {
      final level = course.content.levels[levelIndex];

      for (int chapterIndex = 0; chapterIndex < level.chapters.length; chapterIndex++) {
        final chapter = level.chapters[chapterIndex];

        for (int exerciseIndex = 0; exerciseIndex < chapter.exercises.length; exerciseIndex++) {
          totalExercises++;

          final progressKey = 'L${levelIndex + 1}C${chapterIndex + 1}E${exerciseIndex + 1}';
          
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
          appBar: AppBar(
            title: Text(
              course.title,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => context.go('/home'),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.help_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    _showingGenieMessage = !_showingGenieMessage;
                  });
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCourseHeader(course),
                    _buildLevelsList(course),
                    if (_showingGenieMessage) 
                      const SizedBox(height: 160),
                  ],
                ),
              ),
              if (_showingGenieMessage)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: _buildGenieMessage(course),
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
                        '/course-detail/${course.id}?level=${course.currentLevel}&chapter=$chapterIndex'
                      );
                    }
                  }
                },
                backgroundColor: Theme.of(context).primaryColor,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Continue Learning'),
                elevation: 4,
              ).animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0);
            },
          ),
        );
      },
    );
  }

  Widget _buildCourseHeader(Course course) {
    final Color courseColor = _getCourseColor(course.title);
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            courseColor,
            courseColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: courseColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Roadmap',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            course.content.overview,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _calculateCourseProgress(course),
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_lessons.where((l) => l['isCompleted']).length} / ${_lessons.length} lessons completed',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _buildCertificateWidget(course),
        ],
      ),
    ).animate()
     .fadeIn(duration: 600.ms)
     .slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutQuad);
  }

  Widget _buildLevelsList(Course course) {
    return Column(
      children: List.generate(
        course.content.levels.length,
        (levelIndex) {
          final level = course.content.levels[levelIndex];
          return _buildLevelItem(level, levelIndex, course);
        },
      ),
    );
  }

  Widget _buildLevelItem(CourseLevel level, int levelIndex, Course course) {
    bool isLocked = levelIndex > course.currentLevel;
    
    return Animate(
      effects: [
        FadeEffect(duration: 400.ms, delay: Duration(milliseconds: 100 * levelIndex)),
        SlideEffect(begin: const Offset(0.1, 0), end: Offset.zero, duration: 400.ms, delay: Duration(milliseconds: 100 * levelIndex), curve: Curves.easeOutQuad),
      ],
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isLocked
                ? Theme.of(context).colorScheme.outline.withOpacity(0.5)
                : Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            initiallyExpanded: _expandedLevels[levelIndex],
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedLevels[levelIndex] = expanded;
              });
            },
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                        : Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${level.levelNumber}',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLocked
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                            : Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.title,
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isLocked
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        level.narrative,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: isLocked
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  Icon(
                    Icons.lock,
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                    size: 20,
                  ),
              ],
            ),
            children: level.chapters.map((chapter) => _buildChapterItem(chapter, level, course)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildChapterItem(CourseChapter chapter, CourseLevel parentLevel, Course course) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            chapter.title,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          subtitle: Text(
            chapter.story,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          children: chapter.exercises.map((exercise) => _buildExerciseItem(exercise, parentLevel, chapter, course, parentLevel.levelNumber, chapter.title, exercise.type)).toList(),
        ),
      ),
    );
  }

  Widget _buildExerciseItem(CourseExercise exercise, CourseLevel parentLevel, CourseChapter parentChapter, Course course, int levelIndex, String chapterTitle, String exerciseType) {
    final progressKey = 'L${levelIndex + 1}C${chapterTitle}E$exerciseType';
    final isCompleted = course.progress[progressKey] == 1;
    final isLocked = parentLevel.levelNumber > course.currentLevel;
    
    return GenieCard(
      title: exercise.type,
      subtitle: '5 min • ${exercise.type}',
      description: exercise.content,
      isCompleted: isCompleted,
      isLocked: isLocked,
      onTap: () {
        if (!isLocked) {
          context.push(
            '/course-detail/${course.id}?level=$levelIndex&chapter=$chapterTitle&exercise=$exerciseType'
          );
        }
      },
      leadingWidget: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isCompleted
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getIconForExerciseType(exercise.type),
          color: isCompleted
              ? Theme.of(context).colorScheme.onSecondary
              : Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }

  IconData _getIconForExerciseType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline;
      case 'interactive':
        return Icons.code;
      case 'project':
        return Icons.build;
      case 'quiz':
        return Icons.quiz;
      case 'coding':
        return Icons.code;
      case 'reading':
        return Icons.article;
      default:
        return Icons.article;
    }
  }

  Widget _buildGenieMessage(Course course) {
    String message;
    final completedLessons = _lessons.where((l) => l['isCompleted']).length;
    final totalLessons = _lessons.length;
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0;

    if (completedLessons == 0) {
      message = 'Welcome to your learning roadmap! This is where you can see all the lessons in your course. Start with the first lesson in Level 1 and work your way through.';
    } else if (progress > 0.5) {
      message = 'You\'re making great progress! Keep going to unlock all the lessons and complete the course.';
    } else {
      message = 'Here\'s your personalized learning path. Each level builds on the previous one, so make sure to complete them in order.';
    }

    return AvatarWithMessage(
      message: message,
      state: AvatarState.explaining,
    ).animate()
     .fadeIn(duration: 500.ms)
     .slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutQuad);
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

  // Certificate widget displayed below progress bar
  Widget _buildCertificateWidget(Course course) {
    final double progress = _calculateCourseProgress(course);
    final bool isCompleted = progress >= 1.0;
    return Center(
      child: GestureDetector(
        onTap: isCompleted
            ? () => _showCertificateDialog(context, course)
            : null,
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.amber[400] : Colors.grey[400],
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCompleted ? Icons.emoji_events : Icons.lock_outline,
                color: isCompleted ? Colors.white : Colors.white70,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  isCompleted ? 'Download Certificate!' : 'Certificate Locked',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isCompleted ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shows the certificate popup dialog
  void _showCertificateDialog(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber[700], size: 60),
                const SizedBox(height: 8),
                const Text(
                  'Certificate of Completion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  'Congratulations! You have completed the course "${course.title}".',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.amber[700],
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('Download Certificate'),
                  onPressed: () async {
                      Navigator.of(context).pop();
                      await _generateAndPrintCertificate(course);
                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')
            ),
          ],
        );
      },
    );
  }
  Future<void> _generateAndPrintCertificate(Course course) async {
  final pdf = pw.Document();

  try {
    // Get current user from state
    final username = _currentUser?.username.isNotEmpty == true 
        ? _currentUser!.username
        : 'Valued Learner';  // Fallback name

    // Load certificate template
    final ByteData imageData = await rootBundle.load('assets/images/certificate_template.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.ImageProvider templateImage = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Background image
              pw.Positioned.fill(
                child: pw.Image(templateImage, fit: pw.BoxFit.cover),
              ),

              // Content overlay
              pw.Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Certificate of Completion',
                      style: pw.TextStyle(
                        fontSize: 40,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.deepPurple,
                      ),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Text(
                      'This certifies that',
                      style: const pw.TextStyle(
                        fontSize: 22,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Text(
                      username,
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'has successfully completed the course',
                      style: const pw.TextStyle(
                        fontSize: 22,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 25),
                    pw.Text(
                      course.title,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.deepOrange,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 30),
                    pw.Text(
                      'Date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                      style: const pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Show print dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${course.title}_Certificate',
    );

  } catch (e) {
    print('Certificate generation error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate certificate: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
  Future<void> _loadCurrentUser() async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.checkAuthStatus();
      setState(() {
        _currentUser = authViewModel.currentUser;
      });
    } catch (e) {
      print('Error loading user: $e');
    }
  }

}