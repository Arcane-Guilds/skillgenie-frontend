import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/api_constants.dart';
import 'step1_screen.dart';

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
      title: json['title'] ?? 'No Title', // Default to 'No Title' if null
      difficulty: json['difficulty'] ??
          'No Difficulty', // Default to 'No Difficulty' if null
      languages: List<String>.from(
          json['languages'] ?? []), // Default to empty list if null
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

  // Fetch challenges from API
  Future<void> fetchChallenges() async {
    final response =
        await http.get(Uri.parse('${ApiConstants.baseUrl}/challenges'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _challengesList = data.map((json) => Challenge.fromJson(json)).toList();
      });
    } else {
      // Handle error when API call fails
      throw Exception('Failed to load challenges');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchChallenges();
  }

  @override
  Widget build(BuildContext context) {
    int selectedIndex = 0;
    Size size = MediaQuery.of(context).size;

    // Challenge categories
    List<String> challengesTypes = [
      'Recommended',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges Library'),
        //backgroundColor: Constants.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar section
            Container(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    width: size.width * .9,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.black54.withOpacity(.6),
                        ),
                        const Expanded(
                          child: TextField(
                            showCursor: false,
                            decoration: InputDecoration(
                              hintText: 'Search challenges',
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.mic,
                          color: Colors.black54.withOpacity(.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Categories list section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 50.0,
              width: size.width,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: challengesTypes.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: Text(
                        challengesTypes[index],
                        style: TextStyle(
                          fontSize: 16.6,
                          fontWeight: selectedIndex == index
                              ? FontWeight.bold
                              : FontWeight.w300,
                          color: selectedIndex == index
                              ? Theme.of(context).primaryColor
                              : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Challenges list section (Horizontal scroll)
            SizedBox(
              height: size.height * 0.3, // Ensure it has a fixed height
              child: ListView.builder(
                itemCount: _challengesList.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext context, int index) {
                  final challenge = _challengesList[index];

                  return GestureDetector(
                    onTap: () {
                      // Navigate to Step1Screen with the challenge title
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Step1Screen(
                            name:
                                challenge.title, // Passing the challenge title
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 300,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(.8),
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: NetworkImage(
                              'https://source.unsplash.com/random?sig=$index&coding'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.7),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 10,
                            right: 20,
                            child: Container(
                              height: 50,
                              width: 50,
                              child: IconButton(
                                onPressed: () {
                                  // Handle favorite button if needed
                                },
                                icon: Icon(
                                  Icons.favorite_border,
                                  color: Theme.of(context).primaryColor,
                                ),
                                iconSize: 30,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 50,
                            right: 50,
                            bottom: 50,
                            child: Container(
                              height:
                                  100, // Adjust to fit the title and category
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      challenge.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      challenge.difficulty,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Languages: ${challenge.languages.join(', ')}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
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
                },
              ),
            ),

            // Popular challenges section
            const Padding(
              padding: EdgeInsets.only(left: 12, top: 20),
              child: Text(
                'Popular Challenges',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            // Popular challenges list (Vertical list)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _challengesList.length,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemBuilder: (BuildContext context, int index) {
                final challenge = _challengesList[index];

                return GestureDetector(
                  onTap: () {
                    // Navigate to Step1Screen with the challenge title
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Step1Screen(
                          name: challenge.title, // Passing the challenge title
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: NetworkImage(
                                  'https://source.unsplash.com/random?sig=${index + 10}&coding'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                challenge.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Difficulty: ${challenge.difficulty}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
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
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ).animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.3, end: 0),
    );
  }
} 