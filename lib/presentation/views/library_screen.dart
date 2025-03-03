import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'step1_screen.dart'; // Make sure Step1Screen is imported

class Constants {
  static const primaryColor = Colors.deepPurple; // Or any color you prefer
}

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

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Challenge> _challengesList = [];

  // Fetch challenges from API
  Future<void> fetchChallenges() async {
    final response =
        await http.get(Uri.parse('http://localhost:3000/challenges'));

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
    List<String> _challengesTypes = [
      'Recommended',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges Library'),
        backgroundColor: Constants.primaryColor,
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
                    decoration: BoxDecoration(
                      color: Constants.primaryColor.withOpacity(.1),
                      borderRadius: BorderRadius.circular(20),
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
                itemCount: _challengesTypes.length,
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
                        _challengesTypes[index],
                        style: TextStyle(
                          fontSize: 16.6,
                          fontWeight: selectedIndex == index
                              ? FontWeight.bold
                              : FontWeight.w300,
                          color: selectedIndex == index
                              ? Constants.primaryColor
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
                                  color: Constants.primaryColor,
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
                      decoration: BoxDecoration(
                        color: Constants.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
              ),
            ),

            // New challenges section (Vertical scroll)
            Container(
              padding: const EdgeInsets.only(left: 16, bottom: 20, top: 20),
              child: const Text(
                'All challenges',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: size.height * .5,
              child: ListView.builder(
                  itemCount: _challengesList.length,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final challenge = _challengesList[index];

                    return GestureDetector(
                      onTap: () {
                        // Navigate to Step1Screen with the challenge title
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Step1Screen(
                              name: challenge
                                  .title, // Passing the challenge title
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        height: 80.0,
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        margin: const EdgeInsets.only(bottom: 10, top: 10),
                        width: size.width,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 60.0,
                                  height: 60.0,
                                  decoration: BoxDecoration(
                                    color:
                                        Constants.primaryColor.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Positioned(
                                  bottom: 5,
                                  left: 10,
                                  right: 10,
                                  child: SizedBox(
                                    height: 80.0,
                                    child: Container(
                                      color: Constants.primaryColor
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 80,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(challenge.difficulty),
                                      Text(challenge.title),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
