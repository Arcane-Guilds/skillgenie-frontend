// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:skillGenie/crosswordgame/error.dart';
import 'package:skillGenie/crosswordgame/maincross.dart';
import 'wiki.dart' as wiki;
import 'crossgen.dart';
import 'definition.dart';
import 'dart:math';


class CrosswordRoute extends StatefulWidget {
  const CrosswordRoute({
    super.key,
    required this.pageid,
    required this.size,
    required this.diff,
    required this.lang_rus,
    this.target = 15,
    this.recursive_target = 3,
    this.max_len = 15,
  });

  final int pageid;
  final bool lang_rus;
  final int size;
  final int diff;
  final int target;
  final int recursive_target;
  final int max_len;

  @override
  State<CrosswordRoute> createState() => CrosswordRouteState();
}

class CrosswordRouteState extends State<CrosswordRoute>
{
  late Stream<List<Gen_Word>> pool;
  late int pool_size;
  late int recursive_links;
  late int max_length;
  late int buffer_inc;
  late int help_count;

  @override
  void initState()
  {
    super.initState();

    // Set parameters based on difficulty
    switch (widget.diff) {
      case 1: // Easy
        pool_size = 3 * widget.size;
        recursive_links = (widget.size >= 15) ? 2 : 1;
        max_length = 12;
        buffer_inc = 1;
        help_count = (widget.size/2).ceil();
        break;
      case 2: // Medium
        pool_size = (2.5 * widget.size).ceil();
        recursive_links = 3;
        max_length = 16;
        buffer_inc = 3;
        help_count = 2 * (widget.size/2).ceil();
        break;
      case 3: // Hard
        pool_size = 2 * widget.size;
        recursive_links = 5;
        max_length = 20;
        buffer_inc = 5;
        help_count = (widget.size / 5).round();
        break;
      default: // Default to medium
        pool_size = (2.5 * widget.size).ceil();
        recursive_links = 3;
        max_length = 16;
        buffer_inc = 3;
        help_count = 2 * (widget.size/2).ceil();
    }

    pool = wiki.RequestPool(widget.pageid, pool_size, recursive_links, widget.lang_rus, max_length);
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: pool,
        builder:(BuildContext context, AsyncSnapshot<List<Gen_Word>> snapshot) {
          if (snapshot.hasError)
          {
            return ErrorRoute(error: snapshot.error.toString());
          }
          else if (snapshot.connectionState == ConnectionState.done) //Если поток завершен
              {
            // Check if data is null or empty
            if (snapshot.data == null || snapshot.data!.isEmpty) {
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
                        'No results found',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return CrosswordPage(words: snapshot.data!, size: widget.size, buf_inc: buffer_inc, help_count: help_count);
          }
          else if (snapshot.connectionState == ConnectionState.active)
          {
            return Scaffold(
              body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: ColorTheme.GetLoadColor(context),),
                      // Check if data is null before accessing its length
                      Text('Downloading definitions ${snapshot.data?.length ?? 0}/$pool_size'),
                    ],
                  )
              ),
            );
          }
          else
          {
            return Scaffold(
              body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: ColorTheme.GetLoadColor(context),),
                      const Text('Getting links'),
                    ],
                  )
              ),
            );
          }
        }
    );
  }
}

class CrosswordPage extends StatefulWidget {
  const CrosswordPage({UniqueKey? key, required this.words, required this.size, required this.buf_inc, required this.help_count}) : super(key: key);
  final List <Gen_Word> words;
  final int size, buf_inc, help_count;
  @override
  State<CrosswordPage> createState() => CrosswordPageState();

  static CrosswordPageState? of (BuildContext context)
  {
    var res = context.findAncestorStateOfType<CrosswordPageState>();
    return res;
  }
}

class CrosswordPageState extends State<CrosswordPage> {
  List <Field_Word> Words = [];
  int chosen = 0;  //Выбранное слово
  int chosen_let = -1;  //Выбранная буква
  int helper_used = 0;
  int help_let_count = 0;
  int help_err_count = 0;
  int help_pic_count = 0;
  int help_desc_count = 0;

  late Gen_Crossword crossword;

  // Helper method to safely get a property from Gen_Word or provide a default
  String _safeGetProperty(Gen_Word word, String property) {
    try {
      switch (property) {
        case 'definition':
          return word.definition;
        case 'word':
          return word.word;
        default:
          return '';
      }
    } catch (e) {
      print('Error accessing property $property: $e');
      return '';
    }
  }

  @override
  void initState()
  {
    super.initState();

    // Initialize help counts
    help_let_count = widget.help_count;
    help_err_count = widget.help_count;
    help_pic_count = widget.help_count;
    help_desc_count = widget.help_count;

    // Safely initialize crossword
    try {
      crossword = Gen_Crossword(widget.words, widget.size, widget.buf_inc);
      Words = crossword.GetWordList();

      // Ensure we have at least one word
      if (Words.isEmpty) {
        print("Warning: No words returned from crossword generator. Creating fallback words.");
        // Create a fallback list of Field_Word objects with all required parameters
        Words = [];
        for (var word in widget.words) {
          Words.add(Field_Word(
            word: _safeGetProperty(word, 'word'),
            definition: _safeGetProperty(word, 'definition'),
            ext_definition: _safeGetProperty(word, 'definition'), // Use definition as ext_definition
            picture_url: "", // Empty string for picture_url
            x: 0, // Default x position
            y: 0, // Default y position
            hor: true, // Default horizontal orientation
            num: Words.length, // Use current length as the number
          ));
        }
      }
    } catch (e) {
      // Handle initialization error
      print('Error initializing crossword: $e');
      
      // Create a fallback list of Field_Word objects with all required parameters
      Words = [];
      for (var word in widget.words) {
        Words.add(Field_Word(
          word: _safeGetProperty(word, 'word'),
          definition: _safeGetProperty(word, 'definition'),
          ext_definition: _safeGetProperty(word, 'definition'), // Use definition as ext_definition
          picture_url: "", // Empty string for picture_url
          x: 0, // Default x position
          y: 0, // Default y position
          hor: true, // Default horizontal orientation
          num: Words.length, // Use current length as the number
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely get definition
    var def = Definition(
      source: Words.isEmpty ?
        Field_Word(
          word: "error",
          definition: "Error loading crossword",
          ext_definition: "",
          picture_url: "",
          x: 0,
          y: 0,
          hor: true,
          num: 0,
        ) :
        (chosen < 0 || chosen >= Words.length ? Words[0] : Words[chosen]),
      index: chosen_let,
      num: Words.isEmpty ? 0 : Words.length // Use Words.length instead of crossword.word_count
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorTheme.GetAppBarColor(context),
        leading: IconButton(  //Подведение итогов
          onPressed: () {
            Navigator.popAndPushNamed(context, '/final', arguments: [helper_used, Words]);
          },
          icon: Icon(Icons.close, color: ColorTheme.GetTextColor(context),),
        ),
        actions: [  //Подсказки
          IconButton(  //Вывод первого изображения из статьи
            onPressed: () {
              if (Words.isNotEmpty && chosen >= 0 && chosen < Words.length &&
                  Words[chosen].picture_url != '' && !Words[chosen].pic_showed && help_pic_count > 0)
              {
                setState(() {
                  helper_used++;
                  Words[chosen].pic_showed = true;
                  help_pic_count--;
                });
              }
              HelperShowPic(context);
            },
            color: (Words.isEmpty || chosen < 0 || chosen >= Words.length ||
                Words[chosen].picture_url == '' || (help_pic_count <= 0 && !Words[chosen].pic_showed)) ?
            ColorTheme.GetUnavailHintColor(context) :
            (Words[chosen].pic_showed ? ColorTheme.GetUsedHintColor(context) : ColorTheme.GetAvailHintColor(context)),
            tooltip: "Hints left $help_pic_count",
            icon: const Icon(Icons.photo),
          ),
          IconButton(  //Расширение описания
            onPressed: () {
              if (Words.isNotEmpty && chosen >= 0 && chosen < Words.length &&
                  Words[chosen].ext_definition != '' && help_desc_count > 0)
              {
                setState(() {
                  helper_used++;
                  help_desc_count--;
                  HelperExtendDef();
                });
              }
            },
            color: (Words.isEmpty || chosen < 0 || chosen >= Words.length ||
                Words[chosen].ext_definition == '' || help_desc_count <= 0) ?
            ColorTheme.GetUnavailHintColor(context) :
            ColorTheme.GetAvailHintColor(context),
            tooltip: "Hints left $help_desc_count",
            icon: const Icon(Icons.text_snippet),
          ),
          IconButton(  //Раскраска кроссворда - неправильные буквы будут помечены красным, пока не будут изменены
            onPressed: () {
              if (Words.isNotEmpty && help_err_count > 0)
              {
                setState(() {
                  helper_used++;
                  help_err_count--;
                });
                HelperShowErrors();
              }
            },
            color: (Words.isEmpty || help_err_count <= 0) ?
            ColorTheme.GetUnavailHintColor(context) :
            ColorTheme.GetAvailHintColor(context),
            tooltip: "Hints left $help_err_count",
            icon: const Icon(Icons.color_lens),
          ),
          IconButton(  //Вставка правильной буквы в рандомную пустую клетку
            onPressed: () {
              if (Words.isNotEmpty && help_let_count > 0)
              {
                setState(() {
                  help_let_count--;
                  helper_used++;
                });
                HelperRandomLetters(3);
              }
            },
            color: (Words.isEmpty || help_let_count <= 0) ?
            ColorTheme.GetUnavailHintColor(context) :
            ColorTheme.GetAvailHintColor(context),
            tooltip: "Hints left $help_let_count",
            icon: const Icon(Icons.font_download),
          ),
        ],
      ),
      bottomSheet: def,
      body: Builder(
          builder: (BuildContext context) {
            if (Words.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Error: No words available for crossword',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back'),
                    ),
                  ],
                ),
              );
            }

            try {
              return crossword.ToWidgetsHighlight(chosen, chosen_let, Words);
            } catch (e) {
              print('Error rendering crossword: $e');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Error rendering crossword: ${e.toString()}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back'),
                    ),
                  ],
                ),
              );
            }
          }
      ),
    );
  }

  void HelperExtendDef()  //Расширение описания для выбранного слова
  {
    if (Words.isEmpty || chosen < 0 || chosen >= Words.length) {
      return;
    }

    if (Words[chosen].ext_definition != '')
    {
      setState(() {
        Words[chosen].definition = Words[chosen].ext_definition;
        Words[chosen].ext_definition = '';
      });
    }
  }

  void HelperShowPic(BuildContext context)
  {
    if (Words.isEmpty || chosen < 0 || chosen >= Words.length ||
        Words[chosen].picture_url == '' || (help_pic_count <= 0 && !Words[chosen].pic_showed))
    {
      return;
    }
    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (context) {
          return Dialog(
              child: Stack(
                  children: [
                    Image.network(
                      Words[chosen].picture_url,
                    ),
                    PositionedDirectional(
                      top: 5,
                      end: 5,
                      child: IconButton(
                        onPressed: () {Navigator.of(context).pop();},
                        icon: const Icon(Icons.close, color: Colors.white,),
                      ),
                    )
                  ]
              )
          );
        }
    );
  }

  void HelperShowErrors()
  {
    if (Words.isEmpty) {
      return;
    }

    setState(() {
      for (int i = 0; i < Words.length; i++) {
        if (i >= 0 && i < Words.length) {
          for (int j = 0; j < Words[i].word.length; j++) {
            if (Words[i].word.substring(j, j+1).contains(RegExp(r"[^a-zA-Zа-яА-ЯёЁ]"))) {
              continue;
            }
            else if (Words[i].word.substring(j, j+1) == Words[i].in_word.substring(j, j+1) || Words[i].in_word.substring(j, j+1) == '_') {
              continue;
            }
            else {
              Words[i].mistakes.add(j);  //Добавляем ошибку
            }
          }
        }
      }

      // Only check intersections if chosen is valid
      if (chosen >= 0 && chosen < Words.length) {
        for (var inter in Words[chosen].inters) {
          if (inter.source >= 0 && inter.source < Words.length &&
              inter.word >= 0 && inter.word < Words.length) {
            if (inter.source == chosen &&
                Words[chosen].in_word.substring(inter.source_index, inter.source_index+1) != '_' &&
                !Words[chosen].word.substring(inter.source_index, inter.source_index+1).contains(RegExp(r"[^a-zA-Zа-яА-ЯёЁ]")) &&
                Words[chosen].word.substring(inter.source_index, inter.source_index+1) != Words[chosen].in_word.substring(inter.source_index, inter.source_index+1)) {
              Words[inter.word].mistakes.add(inter.word_index);
            }
            else if (inter.word == chosen &&
                Words[chosen].in_word.substring(inter.word_index, inter.word_index+1) != '_' &&
                !Words[chosen].word.substring(inter.word_index, inter.word_index+1).contains(RegExp(r"[^a-zA-Zа-яА-ЯёЁ]")) &&
                Words[chosen].word.substring(inter.word_index, inter.word_index+1) != Words[chosen].in_word.substring(inter.word_index, inter.word_index+1)) {
              Words[inter.source].mistakes.add(inter.source_index);
            }
          }
        }
      }
    });
  }

  void HelperRandomLetters(int count) //Вставка count букв в случайные пустые либо неправильные места
  {
    if (Words.isEmpty || chosen < 0 || chosen >= Words.length) {
      return;
    }

    setState(() {
      //Поиск пустых и неправильных мест
      List<int> empty = [];
      List<int> wrong = [];
      for (int i = 0; i < Words[chosen].word.length; i++)
      {
        if (Words[chosen].word.substring(i, i+1).contains(RegExp(r"[^a-zA-Zа-яА-ЯёЁ]")))
        {
          continue;
        }
        else if (Words[chosen].word.substring(i, i+1) != Words[chosen].in_word.substring(i, i+1)) //Неправильная ячейка
            {
          wrong.add(i);
        }
        else if (Words[chosen].in_word.substring(i, i+1) == '_')  //Пустая ячейка
            {
          empty.add(i);
        }
      }
      Random rng = Random();
      for (int i = 0; i < count; i++)
      {
        int ind;
        if (empty.isNotEmpty)
        {
          ind = empty[rng.nextInt(empty.length)];
          empty.remove(ind);
        }
        else if (wrong.isNotEmpty)
        {
          ind = wrong[rng.nextInt(wrong.length)];
          wrong.remove(ind);
        }
        else
        {
          break;
        }
        //Непосредственно сама замена
        ChangeLetter(Words[chosen].word.substring(ind, ind+1), chosen, ind);
        for(var inter in Words[chosen].inters)
        {
          if (inter.source >= 0 && inter.source < Words.length &&
              inter.word >= 0 && inter.word < Words.length) {
            if (inter.source == chosen && inter.source_index == ind)
            {
              ChangeLetter(Words[chosen].word.substring(ind, ind+1), inter.word, inter.word_index);
            }
            else if (inter.word == chosen && inter.word_index == ind)
            {
              ChangeLetter(Words[chosen].word.substring(ind, ind+1), inter.source, inter.source_index);
            }
          }
        }
      }
    });
  }

  void ChooseWord(int value, int second)
  {
    if (value < 0 || value >= Words.length) {
      return;
    }

    setState(() {
      chosen = value;
      chosen_let = second;
    });
  }

  void ChangeFocus(bool value, int word_ind, int let_ind) //Подсветка ячейки
  {
    if (word_ind < 0 || word_ind >= Words.length) {
      return;
    }

    if (!value && Words[word_ind].highlighted != let_ind)
    {
      return;
    }
    Words[word_ind].highlighted = value?let_ind:-1;
  }

  void ChangeTrueFocus(int word_ind, int let_ind)  //Запрос фокуса для ячейки
  {
    if (word_ind < 0 || word_ind >= Words.length) {
      return;
    }

    ChooseWord(word_ind, let_ind);
  }

  void ChangeLetter(String value, int word_ind, int let_ind)
  {
    if (word_ind < 0 || word_ind >= Words.length) {
      return;
    }

    setState(() {
      if (value != '')
      {
        Words[word_ind].in_word = Words[word_ind].in_word.replaceRange(let_ind, let_ind + 1, value);
      }
      else
      {
        Words[word_ind].in_word = Words[word_ind].in_word.replaceRange(let_ind, let_ind + 1, '_');
      }
      if (Words[word_ind].mistakes.contains(let_ind))
      {
        Words[word_ind].mistakes.remove(let_ind);
      }
      if (word_ind == chosen) //Переход к следующей букве
          {
        Words[word_ind].highlighted++;
      }
      if (Words[word_ind].highlighted > Words[word_ind].length)
      {
        Words[word_ind].highlighted = -1;
      }
      crossword.field_words.setAll(0, Words);
    });
    if (checkForWin() == Words.length)  //Победа
        {
      Navigator.popAndPushNamed(context, '/final', arguments: [helper_used, Words]);
    }
  }

  void EraseWord(int word_ind)  //Заменить все буквы на пробелы
  {
    if (word_ind < 0 || word_ind >= Words.length) {
      return;
    }

    setState(() {
      for (int i = 0; i < Words[word_ind].length; i++)
      {
        if (Words[word_ind].in_word.substring(i, i+1).contains(RegExp(r"[^a-zA-Zа-яА-ЯёЁ]")))  //Посторонние символы
            {
          continue;
        }
        else
        {
          ChangeLetter('', word_ind, i);
        }
      }
    });
  }

  int checkForWin()  //Проверка на выигрыш
  {
    if (Words.isEmpty) {
      return 0;
    }

    int right = 0;
    for (var word in Words)
    {
      if (word.word == word.in_word)
      {
        right++;
      }
    }
    return right;
  }
}