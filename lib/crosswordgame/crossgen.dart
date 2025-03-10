// ignore_for_file: camel_case_types, non_constant_identifier_names

import '../crosswordgame/cells.dart';
import 'dart:math';
import 'package:flutter/material.dart';

class Math {
  static bool interserct(int a, int b, int c, int d)
  {
    return (max(a, b) <= min (c, d));
  }
  static bool between(int a, int b, int c)
  {
    return a <= b && b < c;
  }
}

class Gen_Crossword {
  var field_words = <Field_Word>[];
  var intersec = <Intersection>[];
  int width = 0, height = 0;
  int word_count = 0;

  Gen_Crossword(List <Gen_Word> words, int target, int buf_inc) {
    const String letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZАБВГДЕЁЖЗИКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ';
    target = target>words.length?words.length:target;
    var let_count = List<int>.filled(59, 0);
    int all_count = 0;
    for (int i = 0; i < words.length; i++)
    {
      words[i].word = words[i].word.toUpperCase();
    }
    for(var word in words)
    {
      for (int i = 0; i < word.word.length; i++)
      {
        var ind = letters.indexOf(word.word.substring(i,i+1));
        if (ind > -1 && ind < 60)
        {
          let_count[ind]++;
          all_count++;
        }
      }
    }
    for(var word in words)
    {
      double weight = 0;
      for (int i = 0; i < word.word.length; i++)
      {
        var ind = letters.indexOf(word.word.substring(i,i+1));
        if (ind != -1)
        {
          weight += let_count[ind].toDouble() / all_count.toDouble();
        }
      }
      word.weight = weight;
    }
    words.sort((a,b) => b.weight.compareTo(a.weight));
    Random rng = Random();
    int buffer = 5;
    int ind = rng.nextInt(buffer);
    bool first_hor = rng.nextBool();
    field_words.add(Field_Word(hor: first_hor, word: words[ind].word, x: 0, y: 0, num: 0, definition:words[ind].definition, 
      ext_definition: words[ind].ext_definition, picture_url: words[ind].pic_url));
    int min_x = 0, min_y = 0, max_x = first_hor?words[ind].word.length:1, max_y = !first_hor?words[ind].word.length:1;
    words.removeAt(ind);
    bool dead_end = false;
    int tries = 0;
    while (!dead_end && field_words.length < target)
    {
      buffer = buffer + buf_inc < words.length ? buffer + buf_inc : words.length; 
      if (words.isEmpty)
      {
        break;
      }
      ind = rng.nextInt(buffer);
      bool word_added = false;
      for (var fword in field_words)
      {
        for (int i = 0; i < words[ind].word.length; i++)
        {
          int lastFound = 0;
          lastFound = fword.word.indexOf(words[ind].word.substring(i, i+1), lastFound);
          if (lastFound == -1)
          {
            continue;
          }
          else
          {
            if (CheckPlacement(words[ind].word,
              fword.hor? fword.x + lastFound : fword.x - i, 
              fword.hor? fword.y - i : fword.y + lastFound, !fword.hor))
            {
              int new_ind = field_words.length;
              field_words.add(Field_Word(
                hor: !fword.hor, 
                word: words[ind].word, 
                x: fword.hor? fword.x + lastFound : fword.x - i, 
                y: fword.hor? fword.y - i : fword.y + lastFound,
                num: new_ind,
                definition: words[ind].definition,
                ext_definition: words[ind].ext_definition,
                picture_url: words[ind].pic_url));
              GetIntersections(field_words.length-1);
              if (fword.hor)
              {
                min_y = min(min_y, field_words.last.y);
                max_y = max(max_y, field_words.last.y + field_words.last.length);
              }
              else
              {
                min_x = min(min_x, field_words.last.x);
                max_x = max(max_x, field_words.last.x + field_words.last.length);
              }
              words.removeAt(ind);
              word_added = true;
              break;
            }
          }  
        }
        if (word_added)
        {
          break;
        }
      }
      if (!word_added)
      {
        tries++;
        if (tries > 10)
        {
          dead_end = true;
        }
      }
    }
    word_count = field_words.length;
    for (var inter in intersec)
    {
      field_words[inter.source].inters.add(Intersection(source: inter.source, source_index:inter.source_index, word: inter.word, word_index: inter.word_index));
      field_words[inter.word].inters.add(Intersection(source: inter.word, source_index:inter.word_index, word: inter.source, word_index: inter.source_index));
    }
    for (int i = 0; i < field_words.length; i++)
    {
      field_words[i].x -= min_x;
      field_words[i].y -= min_y;
    }
    width = (max_x - min_x) * 80;
    height = (max_y - min_y) * 80;
  }
  
  bool CheckPlacement(String word, int x, int y, bool hor)
  {
    for (var ex_word in field_words)
    {
      if (ex_word.hor == hor)
      {
        if (hor)
        {
         if (y == ex_word.y)
         {
           if (Math.interserct(x, ex_word.x - 1, x + word.length, ex_word.x + 1 + ex_word.length))
           {
             return false;
           }
         }
         else if (y == ex_word.y-1 || y == ex_word.y+1)
         {
           if (Math.interserct(x, ex_word.x, x + word.length, ex_word.x + ex_word.length))
           {
             return false;
           }
         }
        }
        else
        {
         if (x == ex_word.x)
         {
           if (Math.interserct(y, ex_word.y - 1, y + word.length, ex_word.y + 1 + ex_word.length))
           {
             return false;
           }
         }
         else if (x == ex_word.x-1 || x == ex_word.x+1)
         {
           if (Math.interserct(x, ex_word.x, x + word.length, ex_word.x + ex_word.length))
           {
             return false;
           }
         }
        }
      }
      else
      {
        if (hor)
        {
          if (ex_word.y <= y && y < ex_word.y+ex_word.length)
          {
            if (x <= ex_word.x && ex_word.x < x + word.length)
            {
              if (ex_word.word.substring(y - ex_word.y, y - ex_word.y + 1) !=
                          word.substring(ex_word.x - x, ex_word.x - x + 1))
              {
                return false;
              }
            }
            else if (x == ex_word.x + 1 || x + word.length == ex_word.x)
            {
              return false;
            }  
          }
          else if (y == ex_word.y - 1 || y == ex_word.y + ex_word.length)
          {
            if (x <= ex_word.x && ex_word.x < ex_word.x + ex_word.length)
            {
              return false;
            }
          }
        }
        else
        {
          if (ex_word.x <= x && x < ex_word.x+ex_word.length)
          {
            if (y <= ex_word.y && ex_word.y < y + word.length)
            {
              if (ex_word.word.substring(x - ex_word.x, x - ex_word.x + 1) !=
                          word.substring(ex_word.y - y, ex_word.y - y + 1))
              {
                return false;
              }
            }
            else if (y == ex_word.y + 1 || y + word.length == ex_word.y)
            {
              return false;
            }           
          }
          else if (x == ex_word.x - 1 || x == ex_word.x + ex_word.length)
          {
            if (y <= ex_word.y && ex_word.y < ex_word.y + ex_word.length)
            {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  void GetIntersections(int index)
  {
    for (int i = 0; i < field_words.length; i++)
    {
      if (index == i)
      {
        continue;
      }
      if (field_words[i].hor == field_words[index].hor) 
      {
        continue;
      }
      if (field_words[index].hor)
      {
        if (field_words[i].y <= field_words[index].y && field_words[index].y < field_words[i].y + field_words[i].length && 
            field_words[index].x <= field_words[i].x && field_words[i].x < field_words[index].x + field_words[index].length)
        {
          intersec.add(Intersection(
            source_index: field_words[index].y - field_words[i].y,
            source: i,
            word: index,
            word_index: field_words[i].x - field_words[index].x,
          ));
        }
      }
      else
      {
        if (field_words[i].x <= field_words[index].x && field_words[index].x < field_words[i].x + field_words[i].length && 
            field_words[index].y <= field_words[i].y && field_words[i].y < field_words[index].y + field_words[index].length)
        {
          intersec.add(Intersection(
            source_index: field_words[index].x - field_words[i].x,
            source: i,
            word: index,
            word_index: field_words[i].y - field_words[index].y,
          ));
        }
      }
    }
  }

  Widget ToWidgets()
  {
    var word_inputs = <Word>[];
    var positioned_words = <Positioned>[];
    for (var Field in field_words)
    {
      word_inputs.add(CreateWord(Field, -1));
      positioned_words.add(Positioned(
        child: word_inputs.last,
        top: Field.y.toDouble() * 80,
        left: Field.x.toDouble() * 80,
      ));
    }
    return InteractiveViewer(
        minScale: 0.001,
        maxScale: 8.0,
        boundaryMargin: EdgeInsets.all(max(width.toDouble(), height.toDouble())), //ax(w,h)
        constrained: false,
        child: SizedBox(
          width: width.toDouble(),
          height: height.toDouble(),
          child: Stack(
            //clipBehavior: Clip.none,
            children: positioned_words
            ),
        ) 
      );
  }

  Widget ToWidgetsHighlight(int word_ind, int let_ind, List<Field_Word> source)
  {
    var word_inputs = <Word>[];
    var positioned_words = <Positioned>[];
    for (int i = 0; i < source.length; i++)
    {
      word_inputs.add(CreateWord(source[i], word_ind));
      positioned_words.add(Positioned(
        child: word_inputs.last,
        top: source[i].y.toDouble() * 80,
        left: source[i].x.toDouble() * 80,
      ));
    }
    return InteractiveViewer(
        minScale: 0.001,
        maxScale: 8.0,
        boundaryMargin: EdgeInsets.all(max(width.toDouble(), height.toDouble())), //ax(w,h)
        constrained: false,
        child: SizedBox(
          width: width.toDouble(),
          height: height.toDouble(),
          child: Stack(
            children: positioned_words
            ),
        ) 
      );
  }

  Word CreateWord(Field_Word field, int word_highlight)
  {

    var Cells = <Widget>[];
    for (int i = 0; i < field.length; i++)
    {
      bool mistake = field.mistakes.contains(i);
      bool is_created = false;
      if (field.word.substring(i, i+1).contains(RegExp(r"[^a-zA-Zа-яА-ЯёЁ]")))
      {
        Cells.add(ReadOnlyCell(
          last: i == field.length-1?true:false,
          letter: field.word.substring(i, i+1),)
        );
        is_created = true;
      }
      for (var inters in intersec)
      {
        if (is_created)
        {
          break;
        }
        if (inters.word == field.num && i == inters.word_index)
        {
          Cells.add(CellCross(
            last: i == field.length-1?true:false, 
            clone_ind: inters.source,
            clone_let_ind: inters.source_index,
            letter: field.in_word.substring(i, i+1) == '_'?' ':field.in_word.substring(i, i+1),
            let_ind: i,
            word_ind: field.num,
            light_highlight: field.num == word_highlight || inters.source == word_highlight,
            pseudo_focused: field.highlighted == i,
            mistake: mistake,
          ));
          is_created = true;
        }
        else if (inters.source == field.num && i == inters.source_index)
        {
          Cells.add(CellCross(
            last: i == field.length-1?true:false, 
            clone_ind: inters.word,
            clone_let_ind: inters.word_index,
            letter: field.in_word.substring(i, i+1) == '_'?' ':field.in_word.substring(i, i+1),
            let_ind: i,
            word_ind: field.num,
            light_highlight: field.num == word_highlight || inters.word == word_highlight,
            pseudo_focused: field.highlighted == i,
            mistake: mistake,
          ));
          is_created = true;
        }
      }
      if (!is_created)
      {
        Cells.add(CellCross(
          last: i == field.length-1?true:false,
          letter: field.in_word.substring(i, i+1) == '_'?' ':field.in_word.substring(i, i+1),
          let_ind: i,
          word_ind: field.num,
          pseudo_focused: field.highlighted == i,
          light_highlight: field.num == word_highlight,
          mistake: mistake,
          ),      
        );
      }
    }
    var result = Word (
      index: field.num,
      hor: field.hor,
      children: Cells,
      parent: field,     
    );
    return result;
  }

  List <Field_Word> GetWordList()
  {
    return field_words;
  }
}

class Gen_Word {
  Gen_Word ({required this.word, required this.weight, required this.definition, this.ext_definition = '', this.pic_url = ''});
  double weight = 0;
  String word;
  String definition;
  String ext_definition;
  String pic_url;
}

class Field_Word {
  Field_Word({required this.word, required this.hor, required this.x, required this.y, required this.num,
              required this.definition, this.ext_definition = '', this.picture_url = ''})
  {
    length = word.length;
    in_word = '';
    for (int i = 0; i < length; i++)
    {
      if (word.substring(i, i+1).contains(RegExp(r"[^a-zA-Zа-яА-ЯёЁ]")))
      {
        in_word += word.substring(i, i+1);
      }
      else
      {
        in_word += '_';
      }
    }
  }
  int highlighted = -1;
  String word;
  late String in_word;
  String definition;
  String ext_definition;
  String picture_url;
  bool pic_showed = false;
  Set <int> mistakes = {};
  int x, y;
  int num;
  late int length;
  bool hor;
  List <Intersection> inters = [];
}

class Intersection {
  Intersection({required this.word_index, required this.word, required this.source, required this.source_index});
  int source;
  int source_index;
  int word;
  int word_index;
}
