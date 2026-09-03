import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/produtos.dart';
import 'auth.dart';

class ProductService {
  static const String _baseUrl = 'https://4upkj2tafvod2ubwcsbnagviyu0feljy.lambda-url.us-east-1.on.aws';

  static Future<List<Product>> getProducts() async {
    try {
      final supabase = Supabase.instance.client;
      
      String? token = supabase.auth.currentSession?.accessToken;
      token ??= await AuthService.getToken();

      print('--> ProductService: Token = ${token != null ? "ENCONTRADO" : "NULO"}');

      if (token == null || token.isEmpty) {
        throw Exception('No se encontró token de sesión.');
      }

      final url = Uri.parse('$_baseUrl/api/products/product/get');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('--> API Status Code: ${response.statusCode}');
      print('--> Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        List<dynamic> jsonList = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('product')) {
          jsonList = decoded['product'] as List<dynamic>;
        } else if (decoded is List) {
          jsonList = decoded;
        }

        return jsonList.map((json) => Product.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await AuthService.logout();
        throw Exception('Sesión expirada (401).');
      } else {
        throw Exception('Error del servidor (${response.statusCode}): ${response.body}');
      }
    } catch (e, stack) {
      print('--> Error en ProductService: $e');
      print('--> Stacktrace: $stack');
      rethrow;
    }
  }
}