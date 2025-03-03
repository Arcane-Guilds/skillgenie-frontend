//import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
//import 'package:frontend/presentation/views/Step1_screen.dart';
//import 'ChallengesHomePage.dart';
import 'package:page_transition/page_transition.dart';
import 'package:skillGenie/presentation/views/Step1_screen.dart';

class Constants {
  static const primaryColor = Colors.deepPurple; // Or any color you prefer
}

class Plant {
  final String name;
  final String category;
  final String imageURL;
  final double price;
  bool isFavorited;

  Plant({
    required this.name,
    required this.category,
    required this.imageURL,
    required this.price,
    this.isFavorited = false,
  });
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Plant> _plantList = [
    Plant(
      name: 'Plant 1',
      category: 'Indoor',
      imageURL: 'assets/images/ch1.jpg',
      price: 9.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 2',
      category: 'Outdoor',
      imageURL: 'https://example.com/plant2.jpg',
      price: 12.99,
      isFavorited: true,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
    Plant(
      name: 'Plant 3',
      category: 'Garden',
      imageURL: 'https://example.com/plant3.jpg',
      price: 15.99,
      isFavorited: false,
    ),
  ];
  bool toggleIsFavorited(bool isFavorited) {
    return !isFavorited; // Simply toggles the boolean value
  }

  @override
  Widget build(BuildContext context) {
    int selectedIndex = 0;
    Size size = MediaQuery.of(context).size;

    // Challenge categories
    List<String> _challengesTypes = [
      'Recommended',
      'Indoor',
      'Indoor',
      'Indoor',
      'Indoor',
      'Indoor',
      'Indoor',
      'Outdoor',
      'Outdoor',
      'Outdoor',
      'Outdoor',
      'Garden',
      'Garden',
      'Garden',
      'Garden',
      'Garden',
      'Garden',
      'Garden',
      'Supplement',
      'Supplement',
      'Supplement',
      'Supplement',
      'Supplement',
      'Supplement',
      'Supplement',
      'Supplement',
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

            // Plant list section
            SizedBox(
              height: size.height * 0.3, // Ensure it has a fixed height
              child: ListView.builder(
                itemCount: _plantList.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          PageTransition(
                              child: Step1Screen(
                                name: _plantList[index].name,
                              ),
                              type: PageTransitionType.bottomToTop));
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
                                  setState(() {
                                    bool isFavorited = toggleIsFavorited(
                                        _plantList[index].isFavorited);
                                    _plantList[index].isFavorited = isFavorited;
                                  });
                                },
                                icon: Icon(
                                  _plantList[index].isFavorited
                                      ? Icons.favorite
                                      : Icons.favorite_border,
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
                            child: Image.asset(_plantList[index].imageURL),
                          ),
                          Positioned(
                            bottom: 15,
                            left: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _plantList[index].category,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _plantList[index].name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 15,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                r'$' +
                                    _plantList[index].price.toStringAsFixed(2),
                                style: TextStyle(
                                    color: Constants.primaryColor,
                                    fontSize: 16),
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

            // List of new challenges section
            Container(
              padding: const EdgeInsets.only(left: 16, bottom: 20, top: 20),
              child: const Text(
                'New challenges',
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
                  itemCount: _plantList.length,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
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
                                  child:
                                      Image.asset(_plantList[index].imageURL),
                                ),
                              ),
                              Positioned(
                                  bottom: 10,
                                  left: 80,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_plantList[index].category),
                                      Text(_plantList[index].name),
                                    ],
                                  ))
                            ],
                          ),
                        ],
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
