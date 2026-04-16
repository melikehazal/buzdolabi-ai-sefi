import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  Future<RecipeResponse> getRecipe(List<String> ingredients) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recipe'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ingredients': ingredients}),
    );

    if (response.statusCode == 200) {
      return RecipeResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Bir hata oluştu');
    }
  }
}
