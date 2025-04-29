// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:skillGenie/crosswordgame/error.dart';
import 'crossword.dart';
import 'search.dart';
import 'final.dart';
import 'package:skillGenie/crosswordgame/cross_settings.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'wiki.dart';
import 'crossgen.dart';

void main() {
  runApp(MaterialApp(
    title: 'Wiki Crossword',
    theme: ThemeData(
      primaryColor: Colors.grey[350],
      scaffoldBackgroundColor: ColorTheme.BackgroundColor
    ),
    darkTheme: ThemeData(
      textTheme: Typography.material2014().white,
      scaffoldBackgroundColor: ColorTheme.dBackgroundColor,
      brightness: Brightness.dark,
    ),
    themeMode: ThemeMode.system,
    initialRoute: '/',

    routes: {
      '/': (context) => const SearchRoute(),
    },
    onGenerateRoute: (settings) {
      switch (settings.name)
      {
        case '/crossword':
          final res = settings.arguments as GenSettings;
          return MaterialPageRoute(
            builder: (BuildContext context) {
              return CrosswordRoute(
                pageid: res.pageid,
                size: res.size,
                diff: res.difficulty,
                lang_rus: res.lang_rus,
              );
            }
          );
        case '/cross_settings':
          final selection = settings.arguments as List<dynamic>;
          return MaterialPageRoute(
            builder: (BuildContext context) {
              return CrosswordSettingsRoute(
                pageid: selection[0],
                title: selection[1],
                language: selection[2],
              );
            }
          );
        case '/final':
          final result = settings.arguments as List<dynamic>;
          return MaterialPageRoute(builder: (BuildContext context) {return FinalRoute(hints:result[0], words: result[1]);});
        default:
          return MaterialPageRoute(builder: (BuildContext context) {return ErrorRoute(error: "Navigation Error");});
      }
    },
    localizationsDelegates: GlobalMaterialLocalizations.delegates + [AppLocalizations.delegate],
    supportedLocales: const [
      Locale('en', ''),
      Locale('ru', '')
    ],
    locale: const Locale('en', ''),
    localeResolutionCallback: (locale, supportedLocales) {
      for (var supportedLocale in supportedLocales) {
        if (supportedLocale.languageCode == locale?.languageCode &&
            supportedLocale.countryCode == locale?.countryCode) {
          return supportedLocale;
        }
      }
      return supportedLocales.first;
    },
  ));
}

class ColorTheme
{
  //Светлая тема
  static const Color TextColor = Colors.black;  //Цвет текста
  static Color BackgroundColor = Colors.grey[50]!;  //Цвет фона
  static Color LoadingColor = Colors.grey[600]!; //Цвет индикаторов загрзуки
  static const Color AppBarColor = Colors.white;  //Цвет appbar'ов

  static const Color CellColor = Colors.white;  //Цвет ячейки
  static Color ReadOnlyColor = Colors.grey[200]!;  //Цвет ячейки с неизменяемым содержимым
  static Color FocusedCellColor = Colors.green[100]!; //Цвет выбранной ячейки
  static Color HighlightedColor = Colors.lightGreen[50]!; //Цвет подсвеченного слова

  static Color WrongCellColor = Colors.red[200]!;   //Цвет ошибочной ячейки (при использовании подсказки)
  static Color WrongCellHlColor = Colors.red[300]!;  //Цвет ошибочной выбранной ячейки

  static const Color AvailableHintColor = Colors.black; //Цвет иконки доступной подсказки
  static Color UnavailableHintColor = Colors.grey[200]!; //Цвет иконки недоступной подсказки
  static Color UsedColor = Colors.green[400]!;  //Цвет иконки для уже использованной подсказки

  //Темная тема
  static Color dTextColor = Colors.grey[100]!;  //Цвет текста
  static Color dBackgroundColor = Colors.black;  //Цвет фона
  static Color dLoadingColor = Colors.grey[100]!; //Цвет индикаторов загрзуки
  static Color dAppBarColor = Colors.grey[900]!;  //Цвет appbar'ов

  static Color dCellColor = Colors.grey[800]!;  //Цвет ячейки
  static Color dReadOnlyColor = Colors.grey[850]!;  //Цвет ячейки с неизменяемым содержимым
  static const Color dFocusedCellColor = Color(0xFF9CA59A); //Цвет выбранной ячейки 
  static const Color dHighlightedColor = Colors.grey; //Цвет подсвеченного слова

  static const Color dWrongCellColor = Color(0xFF775F5F);   //Цвет ошибочной ячейки (при использовании подсказки)
  static const Color dWrongCellHlColor = Color(0xFFBF7C7C);  //Цвет ошибочной выбранной ячейки

  static const Color dAvailableHintColor = Colors.white; //Цвет иконки доступной подсказки
  static Color dUnavailableHintColor = Colors.grey[800]!; //Цвет иконки недоступной подсказки
  static Color dUsedColor = Colors.green[200]!;  //Цвет иконки для уже использованной подсказки

  static Color GetTextColor(BuildContext context)
  {
    final theme = Theme.of(context).brightness;
    return theme == Brightness.dark?dTextColor:TextColor; //Если тема темная
  }

  static Color GetBackColor(BuildContext context)
  {
    final theme = Theme.of(context).brightness;
    return theme == Brightness.dark?dBackgroundColor:BackgroundColor; //Если тема темная
  }

  static Color GetLoadColor(BuildContext context)
  {
    final theme = Theme.of(context).brightness;
    return theme == Brightness.dark?dLoadingColor:LoadingColor; //Если тема темная
  }

  static Color GetAppBarColor(BuildContext context)
  {
    final theme = Theme.of(context).brightness;
    return theme == Brightness.dark?dAppBarColor:AppBarColor; //Если тема темная
  }

  static Color GetCellColor(BuildContext context)
  {
    final theme = Theme.of(context).brightness;
    return theme == Brightness.dark?dCellColor:CellColor; //Если тема темная
  }

  static Color GetROCellColor(BuildContext context)
  {
    final theme = Theme.of(context).brightness;
    return theme == Brightness.dark?dReadOnlyColor:ReadOnlyColor; //Если тема темная
  }

  static Color GetHLCellColor(BuildContext context)
  {
    final theme = Theme.of(context).brightness;
    return theme == Brightness.dark?dFocusedCellColor:FocusedCellColor; //Если тема темная
  }

  static Color GetLightHLCellColor(BuildContext context)
  {
    final theme = Theme.of(context).brightness;
    return theme == Brightness.dark?dHighlightedColor:HighlightedColor; //Если тема темная
  }

  static Color GetWrongCellColor(BuildContext context)
  {
    final theme = Theme.of(context).brightness;
    return theme == Brightness.dark?dWrongCellColor:WrongCellColor; //Если тема темная
  }

  static Color GetHLWrongCellColor(BuildContext context)
  {
    final theme = Theme.of(context).brightness;
    return theme == Brightness.dark?dWrongCellHlColor:WrongCellHlColor; //Если тема темная
  }

  static Color GetAvailHintColor(BuildContext context)
  {
    final theme = Theme.of(context).brightness;
    return theme == Brightness.dark?dAvailableHintColor:AvailableHintColor; //Если тема темная
  }

  static Color GetUnavailHintColor(BuildContext context)
  {
    final theme = Theme.of(context).brightness;
    return theme == Brightness.dark?dUnavailableHintColor:UnavailableHintColor; //Если тема темная
  }

  static Color GetUsedHintColor(BuildContext context)
  {
    final theme = Theme.of(context).brightness;
    return theme == Brightness.dark?dUsedColor:UsedColor; //Если тема темная
  } 
}

class MainCrosswordScreen extends StatelessWidget {
  const MainCrosswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate to the search route which is the entry point for the crossword game
    return const SearchRoute();
  }
}

class CrosswordRoute extends StatefulWidget {
  final int pageid;
  final int size;
  final int diff;
  final bool lang_rus;

  const CrosswordRoute({
    super.key,
    required this.pageid,
    required this.size,
    required this.diff,
    required this.lang_rus,
  });

  @override
  _CrosswordRouteState createState() => _CrosswordRouteState();
}

class _CrosswordRouteState extends State<CrosswordRoute> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Gen_Word>? _words;

  @override
  void initState() {
    super.initState();
    _generateCrossword();
  }

  Future<void> _generateCrossword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Calculate parameters based on difficulty
      int pool_size;
      int recursive_links;
      int max_length;
      
      switch (widget.diff) {
        case 1: // Easy
          pool_size = 3 * widget.size;
          recursive_links = (widget.size >= 15) ? 2 : 1;
          max_length = 12;
          break;
        case 2: // Medium
          pool_size = (2.5 * widget.size).ceil();
          recursive_links = 3;
          max_length = 16;
          break;
        case 3: // Hard
          pool_size = 2 * widget.size;
          recursive_links = 5;
          max_length = 20;
          break;
        default: // Default to medium
          pool_size = (2.5 * widget.size).ceil();
          recursive_links = 3;
          max_length = 16;
      }
      
      // Generate the crossword words
      final wordStream = RequestPool(
        widget.pageid,
        pool_size,
        recursive_links,
        widget.lang_rus,
        max_length,
      );

      List<Gen_Word> words = [];
      await for (final batch in wordStream) {
        words = batch;
        if (words.length >= pool_size) {
          break;
        }
      }

      if (mounted) {
        setState(() {
          _words = words;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wiki Crossword'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_errorMessage',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _generateCrossword,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _words == null || _words!.isEmpty
                  ? const Center(child: Text('No words found for crossword'))
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Crossword Generated!',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Text('Words found: ${_words!.length}'),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              // Make sure words is not null before navigating
                              if (_words != null && _words!.isNotEmpty) {
                                try {
                                  // Navigate directly to CrosswordPage instead of using the route
                                  try {
                                    // Calculate help count based on size
                                    final helpCount = (widget.size / 2).ceil();
                                    const bufInc = 3; // Medium difficulty buffer increment
                                    
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CrosswordPage(
                                          words: _words!,
                                          size: widget.size,
                                          buf_inc: bufInc,
                                          help_count: helpCount,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    // Show error if navigation fails
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // Show error if words is null or empty
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No words available for crossword'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                // Show error if words is null or empty
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No words available for crossword'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            ),
                            child: const Text('Start Playing'),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

// Update the CrosswordDisplay class
class CrosswordDisplay extends StatelessWidget {
  final List<Gen_Word> words;
  final int size;

  const CrosswordDisplay({
    super.key,
    required this.words,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Check if words list is valid
    if (words.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'No words available for crossword. Please try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Generate crossword directly here instead of navigating
    try {
      // Calculate help count based on size
      final helpCount = (size / 2).ceil();
      const bufInc = 3; // Medium difficulty buffer increment
      
      return Scaffold(
        appBar: AppBar(
          title: const Text('Crossword'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Crossword Ready!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text('Words found: ${words.length}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Navigate directly to CrosswordPage instead of using the route
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CrosswordPage(
                          words: words,
                          size: size,
                          buf_inc: bufInc,
                          help_count: helpCount,
                        ),
                      ),
                    );
                  } catch (e) {
                    // Show error if navigation fails
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('Start Playing'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Handle any exceptions during crossword generation
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Error generating crossword: ${e.toString()}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
