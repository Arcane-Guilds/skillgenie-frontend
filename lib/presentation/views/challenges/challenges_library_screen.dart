import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/constants/api_constants.dart';
import 'step1_screen.dart';

// App-wide primary color - changing from purple to blue
const Color kPrimaryBlue = Color(0xFF29B6F6); // Matching the "New Post" button blue

class Challenge {
  final String title;
  final String difficulty;
  final List<String> languages;

  Challenge({
    required this.title,
    required this.difficulty,
    required this.languages,
  });

  // Factory constructor to create Challenge from JSON response
  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      title: json['title'] ?? 'No Title', 
      difficulty: json['difficulty'] ?? 'No Difficulty',
      languages: List<String>.from(json['languages'] ?? []),
    );
  }
}

class ChallengesLibraryScreen extends StatefulWidget {
  const ChallengesLibraryScreen({super.key});

  @override
  _ChallengesLibraryScreenState createState() => _ChallengesLibraryScreenState();
}

class _ChallengesLibraryScreenState extends State<ChallengesLibraryScreen> {
  List<Challenge> _challengesList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedCategoryIndex = 0;

  // Fetch challenges from API
  Future<void> fetchChallenges() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/challenges'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _challengesList = data.map((json) => Challenge.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load challenges. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF58CC02); // Green
      case 'medium':
        return const Color(0xFFFF9600); // Orange
      case 'hard':
        return const Color(0xFFFF4B4B); // Red
      default:
        return kPrimaryBlue; // Changed to blue
    }
  }

  @override
  void initState() {
    super.initState();
    fetchChallenges();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Size size = MediaQuery.of(context).size;
    const bool isWeb = kIsWeb;

    // Challenge categories
    List<String> challengesTypes = [
      'Recommended',
      'Popular',
      'New',
      'Beginner Friendly',
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kPrimaryBlue.withOpacity(0.2), // Changed to blue
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar - only show in mobile mode
              if (!isWeb) 
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimaryBlue.withOpacity(0.3), // Changed to blue
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: kPrimaryBlue, // Changed to blue
                            size: 20,
                          ),
                        ),
                      ),
                      Text(
                        'Challenges Library',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryBlue.withOpacity(0.3), // Changed to blue
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: kPrimaryBlue, // Changed to blue
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Content
              Expanded(
                child: _isLoading 
                ? const Center(
                    child: CircularProgressIndicator(
                      color: kPrimaryBlue, // Changed to blue
                    ),
                  )
                : _errorMessage.isNotEmpty
                  ? _buildErrorMessage()
                  : _buildChallengesContent(challengesTypes, size, theme, colorScheme),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Step1Screen(name: 'New Challenge'),
            ),
          );
        },
        backgroundColor: kPrimaryBlue, // Changed to blue
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ).animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: fetchChallenges,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue, // Changed to blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildChallengesContent(List<String> challengesTypes, Size size, ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.1), // Changed to blue
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: kPrimaryBlue.withOpacity(0.2), // Changed to blue
                ),
              ),
              child: Row(
                      children: [
                        Icon(
                          Icons.search,
                    color: kPrimaryBlue.withOpacity(0.6), // Changed to blue
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search challenges',
                              border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: kPrimaryBlue.withOpacity(0.6), // Changed to blue
                        ),
                        ),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  Icon(
                    Icons.mic,
                    color: kPrimaryBlue.withOpacity(0.6), // Changed to blue
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

            // Categories list section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: challengesTypes.length,
                itemBuilder: (BuildContext context, int index) {
                  final bool isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                      onTap: () {
                        setState(() {
                        _selectedCategoryIndex = index;
                        });
                      },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? kPrimaryBlue // Changed to blue
                          : kPrimaryBlue.withOpacity(0.1), // Changed to blue
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected 
                          ? null 
                          : Border.all(color: kPrimaryBlue.withOpacity(0.3)), // Changed to blue
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        challengesTypes[index],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected 
                            ? Colors.white 
                            : kPrimaryBlue, // Changed to blue
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

          const SizedBox(height: 24),

          // Featured challenges heading
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Featured Challenges',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

          const SizedBox(height: 16),

            // Challenges list section (Horizontal scroll)
            SizedBox(
            height: 220, 
              child: ListView.builder(
                itemCount: _challengesList.length,
                scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, right: 10),
                itemBuilder: (BuildContext context, int index) {
                  final challenge = _challengesList[index];
                final color = _getDifficultyColor(challenge.difficulty);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Step1Screen(
                          name: challenge.title,
                        ),
                        ),
                      );
                    },
                    child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16, bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Background gradient based on challenge difficulty
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withOpacity(0.7),
                                  color.withOpacity(0.9),
                                ],
                              ),
                            ),
                          ),
                          
                          // Pattern overlay for visual interest
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.1,
                              child: CustomPaint(
                                painter: PatternPainter(color: Colors.white),
                              ),
                            ),
                          ),
                          
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(16),
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                // Difficulty badge
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      challenge.difficulty,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const Spacer(),
                                
                                // Title
                                    Text(
                                  challenge.title,
                                      style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Languages
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: challenge.languages.map((lang) => 
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        lang,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  ).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate()
                  .fadeIn(duration: 600.ms, delay: 300.ms + (100.ms * index))
                  .slideX(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad);
                },
              ),
            ),

          const SizedBox(height: 24),

            // Popular challenges section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Popular Challenges',
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(duration: 700.ms, delay: 400.ms),

          const SizedBox(height: 16),

            // Popular challenges list (Vertical list)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _challengesList.length,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
              itemBuilder: (BuildContext context, int index) {
                final challenge = _challengesList[index];
              final color = _getDifficultyColor(challenge.difficulty);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: kPrimaryBlue.withOpacity(0.1), // Changed to blue
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Step1Screen(
                          name: challenge.title,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Challenge image/icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.withOpacity(0.7),
                                color.withOpacity(0.9),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _getIconForLanguage(challenge.languages.isNotEmpty ? challenge.languages.first : ''),
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Challenge details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              const SizedBox(height: 4),
                              
                              // Languages
                              Text(
                                'Languages: ${challenge.languages.join(', ')}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: kPrimaryBlue.withOpacity(0.8), // Changed to blue
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Difficulty badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  challenge.difficulty,
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Arrow icon
                        Icon(
                          Icons.arrow_forward_ios,
                          color: kPrimaryBlue.withOpacity(0.6), // Changed to blue
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate()
                .fadeIn(duration: 800.ms, delay: 500.ms + (50.ms * index))
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
              },
            ),
          ],
        ),
    );
  }

  IconData _getIconForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'python':
        return Icons.code;
      case 'javascript':
        return Icons.javascript;
      case 'java':
        return Icons.coffee;
      case 'c++':
      case 'c#':
      case 'c':
        return Icons.data_object;
      case 'flutter':
        return Icons.flutter_dash;
      case 'dart':
        return Icons.sports_cricket;
      default:
        return Icons.code;
    }
  }
}

class PatternPainter extends CustomPainter {
  final Color color;
  
  PatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
      
    const double spacing = 20.0;
    
    // Draw diagonal lines
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i < size.width ? i : 0, i < size.width ? 0 : i - size.width),
        Offset(i < size.height ? 0 : i - size.height, i < size.height ? i : size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 