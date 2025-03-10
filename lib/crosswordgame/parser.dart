// ignore_for_file: non_constant_identifier_names

import 'dart:math';
import 'package:characters/characters.dart';

List<dynamic> CleanText (String source, String title, [bool pass_brackets = true])  //Удаление HTML-тегов, сносок, нечитаемых символов и т.д.
{
  int limit = 300;
  Map<String, String> braces = {
    '<' : '>',
    '(' : ')',
    '[' : ']',  //'&#91;' : '&#93;'
  };
  Map<String, String> unicode = {
    '&amp;'   : '&',
    '&#038;'  : '&',
    '&copy;'  : '©',
    '&#169;'  : '©', 
    '&mdash;' : '-',
    '&#8212;' : '-',
    '&sect;'  : '§',
    '&#167;'  : '§',
    '&#8470;' : '№',
    // '&#91;'   : '[',
    // '&#93;'   : ']',
    '&nbsp;'  : ' '
  };
  Map<String, String> symbols = {
    '—' : '-',
  };
  int actual_i = 0;
  String result = '';
  var iter = source.characters.iterator;
  while(iter.moveNext())
  {
    if (iter.current == '&')
    {
      iter.moveNext(6);
      bool found = false;
      for (var str in unicode.keys)
      {
        if (iter.current.startsWith(str.substring(1)))
        {
          result += unicode[str] == null?'':unicode[str]!;
          //Откат итератора
          iter.moveBack(1);
          iter.moveNext(str.length-1);
          found = true;
          break;
        }
      }
      if (found)
      {
        continue;
      }
      else
      {      
        iter.moveBackTo(Characters('&')); //Откат обратно
        //Не найденные в списке специальные символы
        if (!iter.moveNext(1))
        {
          break;  //Если строка кончилась
        }
        if (iter.current == '#')  //Если это точно специальный символ
        {
          if (iter.isFollowedBy(Characters('91;')) && pass_brackets)  //Если это квадратная скобка с неправильным кодированием
          {
            iter = PassBrackets(iter);
          }
          else if (!iter.moveTo(Characters(';'))) //Передвигаемся к концу специального символа
          {
            break;  //Если конец строки
          }
        }
        else  //Просто знак амперсанда
        {
          result+='&';
          iter.moveBack(1);
        }
      }
    }
    else if (braces.keys.contains(iter.current) && pass_brackets)  //Если это начало скобки
    {
      iter = PassBrackets(iter);
    }
    else if (symbols.keys.contains(iter.current))  //Если это один из заменяемых/удаляемых символов
    {
      result+=symbols[iter.current]!; //Завершающая скобка
    }
    else if (iter.current.contains('\u0301'))
    {
      result += iter.current.replaceAll('\u0301', '');
    }
    else//Обычный символ
    {
      result+=(iter.current);
    }
    //Проверка, не является ли это символ скобкой
    
  }
  var second_iter = result.characters.iterator;
  String final_result = '';
  int word_meet = 0;  //Количество вхождений искомого слова в определение
  double target_delta = 3;  //Количество букв, которое может не совпадать в двух словах
  int word_len = 0;
  bool is_first_sentence = true;  //Находится ли итератор в первом предложении
  List <String> end_of_sent = ['.', '!', '?'];
  while(second_iter.moveNext()) //Второй проход - удаление двойных пробелов, удаление из определения искомого слова
  {
    if (second_iter.current == ' ')
    {
      second_iter.expandWhile((p0) => p0==' '); //Поиск всех пробелов
      if (!second_iter.moveNext())
      {
        break;
      }
      if (second_iter.current != '.' && second_iter.current != ',' && second_iter.current != '!' && second_iter.current != '?')
      {
        final_result+=' ';
      }
      second_iter.moveBack();
      word_len = 0; //Обнуление длины слова
    }
    else if (title == '')
    {
      final_result+=second_iter.current;
    }
    else if (end_of_sent.contains(second_iter.current))
    {
      is_first_sentence = false;
      final_result+=second_iter.current;
    }
    else  //Удаление слова
    {
      if (second_iter.current == title.substring(0,1) || second_iter.current == title.substring(0,1).toLowerCase())
      {
        int title_index = 1;
        int uneq_count = word_len; //Количество несовпадающих символов
        String tmp = "_";
        var word_iter = second_iter.copy();
        word_iter.moveUntil(Characters(' ')); //Получаем все слово
        for (int i = 0; i < word_iter.current.length; i++)  //Сравнение слов
        {
          var letter = title.substring(title_index, title_index+1);
          if (word_iter.current.substring(i, i+1) == letter || word_iter.current.substring(i, i+1) == letter.toLowerCase())
          {
            title_index+=1;
            tmp+="_";  
            if (title_index >= title.length)
            {
              uneq_count += word_iter.current.length-i-1;
              tmp += word_iter.current.substring(i+1);
              break;
            }
          }
          else
          {
            uneq_count++;
            tmp += word_iter.current.substring(i, i+1);
          }
        }
        uneq_count+= title.length - title_index;
        if (uneq_count < 3 || uneq_count.toDouble()/(word_iter.current.length+1+word_len) < 0.1) //Несовпадающих символов меньше трех, либо их процент меньше 10 процентов
        {
          final_result += tmp;
          if (is_first_sentence)  //Если слово встречается в первом предложении
          {
            word_meet++;
          }
        }
        else
        {
          final_result += second_iter.current + word_iter.current;
        }
        second_iter = word_iter;
      }
      else
      {
        final_result += second_iter.current;
        word_len++;
      }
    }
    
  }
  final_result = final_result.trim();
  return <dynamic> [word_meet ,final_result];
}

CharacterRange PassBrackets(CharacterRange original)  //Пропуск скобок
{
  List<String> braces_start = ['<', '(', '[' ]; //'&#91;'
  List<String> braces_end = ['>', ')', ']',  ]; //'&#93;'
  int depth = 1;  //Глубина вложенности
  while (original.moveNext(1))
  {
    if (original.startsWith(Characters('&')))
    {
      if (!original.moveNext(4))
      {
        original.moveBackTo(Characters('&'));
      }
      else if (original.current == '#91;')
      {
        depth++;
      }
      else if (original.current == '#93;')
      {
        depth--;
        if (depth <= 0)
        {
          return original;
        }
      }
      else
      {
        original.moveBackTo(Characters('&'));
      }
      continue;
    }

    for(var a in braces_start)
    {
      if (original.startsWith(Characters(a)))
      {
        depth++;
        break;
      }
    }
    for(var a in braces_end)
    {
      if (original.startsWith(Characters(a)))
      {
        depth--;
        if (depth <= 0)
        {
          return original;
        }
        break;
      }
    }
  }
  return original;
}