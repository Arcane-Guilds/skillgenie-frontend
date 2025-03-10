import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/course_model.dart';
import '../../viewmodels/course_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final int? initialLevelIndex;
  final int? initialChapterIndex;

  const CourseDetailScreen({
    Key? key, 
    required this.courseId, 
    this.initialLevelIndex,
    this.initialChapterIndex,
  }) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedLevelIndex = 0;
  int _selectedChapterIndex = 0;

  @override
  void initState() {
    super.initState();
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
      
      // Set the selected level to the current level from the course or the initialLevelIndex if provided
      if (courseViewModel.currentCourse != null) {
        setState(() {
          _selectedLevelIndex = widget.initialLevelIndex ?? courseViewModel.currentCourse!.currentLevel;
          _selectedChapterIndex = widget.initialChapterIndex ?? 0;
        });
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

  Future<void> _updateProgress(int levelIndex, int chapterIndex, int exerciseIndex) async {
    final courseViewModel = Provider.of<CourseViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    if (courseViewModel.currentCourse != null && authViewModel.user != null) {
      // Calculate progress key
      final progressKey = 'L${levelIndex + 1}C${chapterIndex + 1}E${exerciseIndex + 1}';

      // Update progress in the view model
      await courseViewModel.updateCourseProgress(
        courseViewModel.currentCourse!.id,
        progressKey,
        1, // Completed
      );

      // Check if all exercises in the chapter are completed
      final level = courseViewModel.currentCourse!.content.levels[levelIndex];
      final chapter = level.chapters[chapterIndex];

      bool allExercisesCompleted = true;
      for (int i = 0; i < chapter.exercises.length; i++) {
        final exerciseKey = 'L${levelIndex + 1}C${chapterIndex + 1}E${i + 1}';
        final progress = courseViewModel.currentCourse!.progress[exerciseKey] ?? 0;
        if (progress < 1) {
          allExercisesCompleted = false;
          break;
        }
      }

      // If all exercises are completed, move to the next chapter or level
      if (allExercisesCompleted) {
        if (chapterIndex < level.chapters.length - 1) {
          // Move to the next chapter
          setState(() {
            _selectedChapterIndex = chapterIndex + 1;
          });
        } else if (levelIndex < courseViewModel.currentCourse!.content.levels.length - 1) {
          // Move to the next level
          await courseViewModel.updateCurrentLevel(
            courseViewModel.currentCourse!.id,
            levelIndex + 1,
          );
          setState(() {
            _selectedLevelIndex = levelIndex + 1;
            _selectedChapterIndex = 0;
          });
        }
      }
    }
  }

  double _calculateLevelProgress(Course course, int levelIndex) {
    if (course.content.levels.isEmpty) return 0.0;

    final level = course.content.levels[levelIndex];
    int totalExercises = 0;
    int completedExercises = 0;

    for (int chapterIndex = 0; chapterIndex < level.chapters.length; chapterIndex++) {
      final chapter = level.chapters[chapterIndex];
      for (int exerciseIndex = 0; exerciseIndex < chapter.exercises.length; exerciseIndex++) {
        totalExercises++;
        final progressKey = 'L${levelIndex + 1}C${chapterIndex + 1}E${exerciseIndex + 1}';
        final progress = course.progress[progressKey] ?? 0;
        if (progress >= 1) {
          completedExercises++;
        }
      }
    }

    return totalExercises > 0 ? completedExercises / totalExercises : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<CourseViewModel>(
          builder: (context, courseViewModel, child) {
            if (courseViewModel.currentCourse != null) {
              return Text(courseViewModel.currentCourse!.title);
            }
            return const Text('Course Details');
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<CourseViewModel>(
        builder: (context, courseViewModel, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_errorMessage != null) {
            return Center(child: Text('Error: $_errorMessage'));
          }

          final course = courseViewModel.currentCourse;
          if (course == null) {
            return const Center(child: Text('Course not found'));
          }

          return _buildChapterContent(course);
        },
      ),
      bottomNavigationBar: Consumer<CourseViewModel>(
        builder: (context, courseViewModel, child) {
          final course = courseViewModel.currentCourse;
          if (course == null || _isLoading) {
            return const SizedBox.shrink();
          }

          final level = course.content.levels[_selectedLevelIndex];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_selectedChapterIndex > 0)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedChapterIndex--;
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                    ),
                  )
                else
                  const SizedBox.shrink(),

                if (_selectedChapterIndex < level.chapters.length - 1)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedChapterIndex++;
                      });
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  )
                else if (_selectedLevelIndex < course.content.levels.length - 1 &&
                        _selectedLevelIndex <= course.currentLevel)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedLevelIndex++;
                        _selectedChapterIndex = 0;
                      });
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next Level'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChapterContent(Course course) {
    if (_selectedLevelIndex >= course.content.levels.length) {
      return const Center(child: Text('Level not found'));
    }

    final level = course.content.levels[_selectedLevelIndex];

    if (_selectedChapterIndex >= level.chapters.length) {
      return const Center(child: Text('Chapter not found'));
    }

    final chapter = level.chapters[_selectedChapterIndex];
    final Color courseColor = _getCourseColor(course.title);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter header with level and chapter info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  courseColor,
                  courseColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
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
                // Level indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Level ${level.levelNumber}: ${level.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Chapter title
                Text(
                  chapter.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress indicator
                LinearProgressIndicator(
                  value: (_selectedChapterIndex + 1) / level.chapters.length,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                // Chapter progress text
                Text(
                  'Chapter ${_selectedChapterIndex + 1} of ${level.chapters.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Chapter story
          _buildContentSection(
            title: 'Story',
            content: chapter.story,
            icon: Icons.auto_stories,
            color: Colors.blue,
          ),
          
          // Concept Introduction Section
          if (chapter.conceptIntroduction.isNotEmpty)
            _buildContentSection(
              title: 'Concept Introduction',
              content: chapter.conceptIntroduction,
              icon: Icons.lightbulb,
              color: Colors.purple,
            ),
          
          // Real-World Application Section
          if (chapter.realWorldApplication.isNotEmpty)
            _buildContentSection(
              title: 'Real-World Application',
              content: chapter.realWorldApplication,
              icon: Icons.public,
              color: Colors.green,
            ),

          // Exercises Section
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Exercises',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chapter.exercises.length,
            itemBuilder: (context, exerciseIndex) {
              final exercise = chapter.exercises[exerciseIndex];
              final progressKey = 'L${_selectedLevelIndex + 1}C${_selectedChapterIndex + 1}E${exerciseIndex + 1}';
              final isCompleted = (course.progress[progressKey] ?? 0) >= 1;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCompleted ? Colors.green : Colors.grey.withOpacity(0.3),
                    width: isCompleted ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildExerciseTypeIcon(exercise.type),
                          const SizedBox(width: 8),
                          Text(
                            'Exercise ${exerciseIndex + 1} (${exercise.type.toUpperCase()})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        exercise.content,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      if (exercise.hints.isNotEmpty) ...[
                        ExpansionTile(
                          title: const Text('Hints'),
                          children: exercise.hints.map((hint) =>
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(hint),
                            )
                          ).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                      ExpansionTile(
                        title: const Text('Solution'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(exercise.solution),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: isCompleted ? null : () {
                              _updateProgress(_selectedLevelIndex, _selectedChapterIndex, exerciseIndex);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCompleted ? Colors.grey : Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(isCompleted ? 'Completed' : 'Mark as Complete'),
                          ),
                        ],
                      ),
                      if (isCompleted && exercise.successMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  exercise.successMessage,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          // Challenge Section
          if (chapter.challenge != null)
            _buildChallengeSection(chapter.challenge!, context),
          
          // Bonus Content Section
          if (level.bonusContent != null)
            _buildBonusContentSection(level.bonusContent!),
          
          const SizedBox(height: 80), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildContentSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChallengeSection(ChapterChallenge challenge, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            const Text(
              'Challenge',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).primaryColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.scenario,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Requirements:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...challenge.requirements.map((req) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            req,
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )
                ).toList(),
                const SizedBox(height: 16),
                const Text(
                  'Starter Code:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    challenge.starterCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement challenge submission
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Challenge submission not implemented yet')),
                      );
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Submit Solution'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBonusContentSection(BonusContent bonusContent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'Bonus Content',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Fun Fact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bonusContent.funFact,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Advanced Concept',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bonusContent.advancedConcept,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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

  Widget _buildExerciseTypeIcon(String type) {
    IconData iconData;
    Color color;

    switch (type.toLowerCase()) {
      case 'quiz':
        iconData = Icons.quiz;
        color = Colors.blue;
        break;
      case 'code':
        iconData = Icons.code;
        color = Colors.purple;
        break;
      case 'concept':
        iconData = Icons.lightbulb;
        color = Colors.orange;
        break;
      default:
        iconData = Icons.assignment;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color),
    );
  }
}