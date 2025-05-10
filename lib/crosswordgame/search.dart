// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


import 'cross_settings.dart';

class SearchRoute extends StatelessWidget {
  const SearchRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFE3F2FD), // Light blue background
        appBar: AppBar(
          title: Text(
            'Wiki Crossword',
            style: TextStyle(
              color: Colors.blue[900], // Dark blue for contrast
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFFE3F2FD), // Light blue app bar
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.blue[900]), // Dark blue for contrast
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFE3F2FD), // Light blue
                const Color(0xFFBBDEFB), // Slightly darker light blue
              ],
            ),
          ),
          child: const SearchScreen(),
        ),
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, int>>? search; //Результаты поиска
  TextStyle header_style = const TextStyle(fontSize: 25);
  late bool language_rus;
  String query = '';
  
  @override
  void initState() {
    super.initState();
    language_rus = false;
    search = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue[200]!,
                width: 1,
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Wikipedia',
                labelStyle: TextStyle(color: Colors.blue[900]),
                hintText: 'Enter a topic to create a crossword',
                hintStyle: TextStyle(color: Colors.blue[200]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.blue[900]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (value) {
                query = value;
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    query = value;
                    search = WikiSearch(query, language_rus);
                  });
                }
              },
            ),
          ),
        ),
        Expanded(
          child: search == null
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Search for a topic to create a crossword',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : FutureBuilder<Map<String, int>>(
                  future: search,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[900]!),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Searching...',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red[200]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                              color: Colors.red[900],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.blue[200]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'No results found',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    } else {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          String title = snapshot.data!.keys.elementAt(index);
                          int pageId = snapshot.data!.values.elementAt(index);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.blue[200]!,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                title,
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontSize: 16,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.blue[900],
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CrosswordSettingsRoute(
                                      pageid: pageId,
                                      title: title,
                                      language: language_rus,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }
}

Future <Map<String, int>> SearchWiki(String query, bool is_rus) async
{
  Uri url = Uri.parse(is_rus
                      ?'https://ru.wikipedia.org/w/api.php?action=query&list=search&srsearch=$query&srlimit=10&srnamespace=0&format=json&origin=*'
                      :'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=$query&srlimit=10&srnamespace=0&format=json&origin=*');
  http.Response response = await http.get(url);
  if (response.statusCode != 200)
  {
    throw(Error());
  }
  var json_result = jsonDecode(response.body);
  if (json_result['query'] == null)
  {
    throw Error();
  }
  List<dynamic> results = json_result['query']['search'] as List<dynamic>;
  if (results.isEmpty)
  {
    return <String,int>{};
  }
  Map<String,int> final_res = {};
  for (int i = 0; i < results.length; i++)
  {
    final_res.putIfAbsent(results[i]['title'], () => results[i]['pageid']);
  }
  return final_res;
}

Future <Map<String, int>> SearchRandom(bool is_rus) async
{
  Uri url = Uri.parse(is_rus
                      ?'https://ru.wikipedia.org/w/api.php?action=query&list=random&rnlimit=10&rnnamespace=0&format=json&origin=*'
                      :'https://en.wikipedia.org/w/api.php?action=query&list=random&rnlimit=10&rnnamespace=0&format=json&origin=*');
  http.Response response = await http.get(url);
  if (response.statusCode != 200)
  {
    throw(Error());
  }
  var json_result = jsonDecode(response.body);
  if (json_result['query'] == null)
  {
    throw Error();
  }
  List<dynamic> results = json_result['query']['random'] as List<dynamic>;
  if (results.isEmpty)
  {
    return <String,int>{};
  }
  Map<String,int> final_res = {};
  for (int i = 0; i < results.length; i++)
  {
    final_res.putIfAbsent(results[i]['title'], () => results[i]['id']);
  }
  return final_res;
}

Future<Map<String, int>> WikiSearch(String query, bool is_rus) async {
  // This is just a wrapper around SearchWiki for better naming
  return SearchWiki(query, is_rus);
}