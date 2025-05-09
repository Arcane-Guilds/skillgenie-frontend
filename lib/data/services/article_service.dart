import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';

class ArticleService {
  static const String baseUrl = 'https://dev.to/api';
  
  Future<List<Article>> getArticles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/articles?tag=programming&top=1'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> articlesJson = json.decode(response.body);
        return articlesJson.map((json) => Article.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load articles');
      }
    } catch (e) {
      throw Exception('Error fetching articles: $e');
    }
  }
} 