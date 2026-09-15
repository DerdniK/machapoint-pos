import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/produtos.dart';
import 'auth.dart';

class ProductService {
  static const String _baseUrl = 'https://4upkj2tafvod2ubwcsbnagviyu0feljy.lambda-url.us-east-1.on.aws';

  /// Obtiene la lista completa de productos
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

      print('--> API Status Code (Get): ${response.statusCode}');
      print('--> Response Body (Get): ${response.body}');

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
      print('--> Error en ProductService.getProducts: $e');
      print('--> Stacktrace: $stack');
      rethrow;
    }
  }

  /// Crea un nuevo producto enviando la estructura en PascalCase para la Lambda de AWS
  static Future<bool> createProduct({
    required String name,
    required String sku,
    required double price,
    required int typeId,
    required String imageUrl,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      String? token = supabase.auth.currentSession?.accessToken;
      token ??= await AuthService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No se encontró token de sesión.');
      }

      final url = Uri.parse('$_baseUrl/api/products/product/create');

      // Body con llaves en PascalCase como requiere tu API
      final body = jsonEncode({
        "Name": name,
        "SKU": sku,
        "Price": price,
        "TypeId": typeId,
        "ImageURL": imageUrl,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print('--> API Status Code (Create): ${response.statusCode}');
      print('--> Response Body (Create): ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        return decoded['success'] == true;
      } else if (response.statusCode == 401) {
        await AuthService.logout();
        throw Exception('Sesión expirada (401).');
      } else {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        final errorMsg = decoded['message'] ?? decoded['error'] ?? response.body;
        throw Exception(errorMsg);
      }
    } catch (e, stack) {
      print('--> Error en ProductService.createProduct: $e');
      print('--> Stacktrace: $stack');
      rethrow;
    }
  }
}