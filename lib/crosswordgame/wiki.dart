// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:skillGenie/crosswordgame/crossgen.dart';

import 'package:skillGenie/crosswordgame/parser.dart';

class WikiPage
{
  WikiPage({required this.title, required this.content, required this.links, required this.priority, this.ext_content = '', this.picture = ''});
  String title;
  String content;
  String ext_content;
  String picture;
  List <int> links;
  bool priority;
}

Stream<List <Gen_Word>> RequestPool(int pageid, int target, int recursive_target, bool russian, int max_len, {List<int> start_pool = const []}) async*
{
  List <Gen_Word> result = [];
  http.Client client = http.Client();
  List <int> pool = [];
  if (pageid != -1)
  {
    var original_page = await GetArticleWithRetry(client, pageid, true, russian, max_len);
    pool.addAll(original_page.links);
  }
  pool += start_pool;
  pool.shuffle();
  for (int i = 0; i < recursive_target && i < pool.length; i++)
  {
    var new_page = await GetArticleWithRetry(client, pool[i], true, russian, max_len);
    pool.addAll(new_page.links);
  }
  pool.shuffle();
  List <int> final_pool = [];
  final_pool.add(pageid);
  for (int i = 0; i < target && i < pool.length; i++)
  {
    if (final_pool.contains(pool[i]))
    {
      pool.removeAt(i);
      i--;
      continue;
    }
    var new_page = await GetArticleWithRetry(client, pool[i], false, russian, max_len);
    bool add = true;
    for (var p in result)
    {
      if (p.word == new_page.title)
      {
        add = false;
      }
    }
    if (new_page.priority && add)
    {
      var new_word = Gen_Word(word: new_page.title, weight: 0, definition: new_page.content, ext_definition: new_page.ext_content, pic_url: new_page.picture);
      result.add(new_word);
      final_pool.add(pool[i]);
      yield result;
    }
    else
    {
      pool.removeAt(i);
      i--;
      continue;
    }
  }
  // if (pool.length < target)
  // {
  //   client.close();

  //   throw Exception('Chosen articles don\' have enough words to build crossword.');
  // }
  client.close();
}

Future<WikiPage> GetArticleWithRetry(
  http.Client client,
  int pageid,
  bool recursive,
  bool russian,
  int max_len,
  {int retries = 3}
) async {
  for (int attempt = 0; attempt < retries; attempt++) {
    try {
      return await GetArticle(client, pageid, recursive, russian, max_len);
    } catch (e) {
      if (attempt == retries - 1) rethrow;
      await Future.delayed(const Duration(seconds: 1));
    }
  }
  throw Exception('Failed to fetch article after $retries attempts');
}

Future <WikiPage> GetArticle(http.Client client, int pageid, bool recursive, bool russian, int max_len) async  //Получить название и содержание статьи
{
  String query = '${russian ? 'https://ru.wikipedia.org' : 'https://en.wikipedia.org'}/w/api.php?format=json&origin=*&action=query&prop=extractsgpllimit&exchars=500&exintro&explaintext&redirects=1&pageids=$pageid&=50';
  var uri = Uri.parse(query);
  var response = await client.get(uri);
  if ((response).statusCode != 200)
  {
    throw Error('Ошибка соединения. Код ошибки: ${(response).statusCode}');
  }
  var json_result = jsonDecode(response.body);
  var res1 = json_result['query'];
  var res2 = res1['pages'];
  var result = res2[(res2 as Map<String, dynamic>).keys.last];
  
  // Null-safe extraction with default values
  String new_title = CheckWord(result['title'] ?? '', max_len);
  String extract = result['extract'] ?? '';

  bool priority = false;
  if (new_title != '')
  {
    priority = true;
  }

  List<int> links = [];
  if (recursive)  //Поиск ссылок
  {
    String link_query = '${russian ? 'https://ru.wikipedia.org' : 'https://en.wikipedia.org'}/w/api.php?action=query&format=json&origin=*&redirects&generator=links&gpllimit=500&gplnamespace=0&prop=info&indexpageids=true&inprop=url&pageids=$pageid';
    var links_map = {};
    do
    {
      uri = Uri.parse(link_query);
      response = await client.get(uri);
      var json_links = jsonDecode(response.body);
      links_map = json_links as Map<String, dynamic>;
      //Получение списка страниц
      var query_map = links_map['query'] as Map <String, dynamic>;
      var pages_list = query_map['pageids'] as List <dynamic>;
      for (var page in pages_list)  //Добавление страниц в список
      {
        int? pageid = int.tryParse(page);
        if (pageid == null)
        {
          continue;
        }
        if (pageid <= 0)
        {
          continue;
        }
        links.add(pageid);
      }
      //Продолжение
      if (links_map.containsKey('continue'))  //Если есть продолжение
      {
        var continue_map = links_map['continue'] as Map <String, dynamic>;
        link_query = '${russian ? 'https://ru.wikipedia.org' : 'https://en.wikipedia.org'}/w/api.php?action=query&format=json&redirects&generator=links&gpllimit=500&gplnamespace=0&prop=info&indexpageids=tru&inprop=url&pageids=$pageid&continue=' + continue_map['continue']! + '&gplcontinue=' + continue_map['gplcontinue']!;
      }
    }
    while (links_map.containsKey('continue'));
  }

  if (!priority)
  {
    return WikiPage(content: '', title: result['title'], links: links, priority: priority);
  }

  var full_description = CleanText(extract, new_title, true);
  if (full_description[0] == 0) //Если в описании нету вхождения названия
  {
   full_description = CleanText((result['title'] ?? '') + ' - ' + full_description[1], new_title, false);
  }
  var full_desc = full_description[1] as String? ?? '';
  String short_desc;
  if (full_desc.indexOf('.') == full_desc.lastIndexOf('.')) //Если описание состоит из всего одного предложения
  {
    short_desc = full_desc;
    full_desc = '';
    if (!short_desc.contains('.'))  //Если предложение не умещается в 500 символов (?)
    {
      short_desc += '...';
    }
  }
  else
  {
    short_desc = full_desc.substring(0, full_desc.indexOf('.'));
  }

  // print(result['title']);
  // print(new_title);
  // print(short_desc);
  // print(full_desc);
  
  String pic_query = '${russian ? 'https://ru.wikipedia.org' : 'https://en.wikipedia.org'}/w/api.php?action=query&format=json&origin=*&prop=pageimages&pilimit=1&piprop=thumbnail&pithumbsize=600&pageids=$pageid';
  uri = Uri.parse(pic_query);
  response = await client.get(uri);
  json_result = jsonDecode(response.body);
  res1 = json_result['query']['pages'];
  res2 = res1[(res1 as Map<String, dynamic>).keys.last];
  var pic_result = res2 as Map<String, dynamic>;
  var picture = '';
  if (pic_result.containsKey('thumbnail'))
  {
    picture = pic_result['thumbnail']['source'] ?? '';
  }
  return WikiPage(title: new_title, content: short_desc, ext_content: full_desc, 
                  links: links, priority: priority, picture: picture);
}

String CheckWord(String word, int max_len) //Проверка слова - оно не должно начинаться с цифр и не быть слишком длинным/коротким
{  
  if (word.startsWith(RegExp('[0-9]'))) //Если начинается с цифр - убираем слово (скорее всего, это дата)
  {
    return '';
  }
  List <String> split_words = [];
  if (word.contains(' ')) //Разделение предложения на слова
  {
    split_words = word.split(' ');
    split_words.shuffle();  //Поиск случайного подходящего слова
  }
  else
  {
    split_words.add(word);
  }
  for (var one_word in split_words)
  {
    if (one_word.length < max_len && one_word.length > 2)
    {
      //Удаление скобок
      if (one_word.startsWith('('))
      {
        one_word = one_word.substring(1);
      }
      if (one_word.endsWith(')') || one_word.endsWith(','))
      {
        one_word = one_word.substring(0, one_word.length-1);
      }
      return one_word.toUpperCase();
    }
  }
  return '';
}

String TrimContent(String str, int target)  //Обрезать определение до первой точки
{
  if (str.length < target)
  {
    return str;
  }
  int i = 0;
  while (i < str.length && str.contains('.', i))
  {
    int ind = str.indexOf('.', i);
    if (ind <= 10 || str.substring(ind-2, ind-1) == ' ' || str.substring(ind-2, ind-1) == '.')  //Если точка принадлежит инициалам
    {
      i = ind+1;
    }
    else if (ind < target)
    {
      return str.substring(0, ind+1);
    }
    else
    {
      break;
    }
  }
  
  var res = str.substring(0, target);
  var end = res.lastIndexOf(' '); //Заканчиваем определение на последнем пробеле
  res = res.replaceRange(end, null, '...');
  return res;
}

class Error { //Ошибка
  Error(this.cause);

  @override
  String toString()
  {
    return cause;
  }
  String cause;
}