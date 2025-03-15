// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'package:flag/flag.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'maincross.dart';
import 'cross_settings.dart';

class SearchRoute extends StatelessWidget {
  const SearchRoute({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wiki Crossword'),
          backgroundColor: Colors.transparent,
        ),
        body: SearchScreen(),
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

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
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Wikipedia',
              hintText: 'Enter a topic to create a crossword',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  if (query.isNotEmpty) {
                    setState(() {
                      search = WikiSearch(query, language_rus);
                    });
                  }
                },
              ),
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
        Expanded(
          child: search == null
              ? const Center(child: Text('Search for a topic to create a crossword'))
              : FutureBuilder<Map<String, int>>(
                  future: search,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No results found'));
                    } else {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          String title = snapshot.data!.keys.elementAt(index);
                          int pageId = snapshot.data!.values.elementAt(index);
                          return ListTile(
                            title: Text(title),
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