import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/produtos.dart';
import 'auth.dart';

class ProductService {
  static const String _baseUrl =
      'https://4upkj2tafvod2ubwcsbnagviyu0feljy.lambda-url.us-east-1.on.aws';

  static Future<String> _getToken() async {
    final supabase = Supabase.instance.client;
    final token =
        supabase.auth.currentSession?.accessToken ??
        await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No se encontró token de sesión.');
    }
    return token;
  }

  static List<Product> _productsFromResponse(String responseBody) {
    final dynamic decoded = jsonDecode(responseBody);
    dynamic productData = decoded;
    if (decoded is Map<String, dynamic>) {
      final wrappedData =
          decoded['product'] ?? decoded['products'] ?? decoded['data'];
      if (wrappedData != null) {
        productData = wrappedData;
      } else if (decoded.containsKey('productid') ||
          decoded.containsKey('productId')) {
        productData = decoded;
      } else {
        return [];
      }
    }

    if (productData is Map) {
      return [Product.fromJson(Map<String, dynamic>.from(productData))];
    }
    if (productData is List) {
      return productData
          .whereType<Map>()
          .map((json) => Product.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  static Future<List<Product>> _getProductsFrom(Uri url) async {
    final token = await _getToken();
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return _productsFromResponse(response.body);
    }
    if (response.statusCode == 401) {
      await AuthService.logout();
      throw Exception('Sesión expirada (401).');
    }
    throw Exception(
      'Error del servidor (${response.statusCode}): ${response.body}',
    );
  }

  static Future<List<Product>> getProducts({int? productId}) async {
    try {
      final baseUrl = Uri.parse('$_baseUrl/api/products/product/Get');
      final url = productId == null
          ? baseUrl
          : baseUrl.replace(queryParameters: {'productId': '$productId'});
      return await _getProductsFrom(url);
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Product>> searchProductsByName(String name) {
    final url = Uri.parse(
      '$_baseUrl/api/products/product/search',
    ).replace(queryParameters: {'name': name});
    return _getProductsFrom(url);
  }

  static Future<List<Product>> searchProducts(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return getProducts();

    final productId = int.tryParse(normalizedQuery);
    final results = await searchProductsByName(normalizedQuery);
    if (productId != null && productId > 0) {
      results.addAll(await getProducts(productId: productId));
    }

    final productsById = {
      for (final product in results) product.productId: product,
    };
    if (productsById.values.any((product) => product.stock == null)) {
      final catalog = await getProducts();
      final stockById = {
        for (final product in catalog)
          if (product.stock != null) product.productId: product.stock!,
      };
      for (final entry in productsById.entries.toList()) {
        final product = entry.value;
        final stock = stockById[product.productId];
        if (product.stock == null && stock != null) {
          productsById[entry.key] = Product(
            productId: product.productId,
            name: product.name,
            sku: product.sku,
            type: product.type,
            price: product.price,
            imageUrl: product.imageUrl,
            stock: stock,
          );
        }
      }
    }
    return productsById.values.toList();
  }

  static Future<bool> updateProduct({
    required int productId,
    required String name,
    required String sku,
    required String imageUrl,
    required double price,
    required int typeId,
  }) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/products/product/update/$productId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'sku': sku,
        'imageURL': imageUrl,
        'price': price,
        'typeId': typeId,
      }),
    );
    if (response.statusCode == 401) {
      await AuthService.logout();
      throw Exception('Sesión expirada (401).');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error del servidor (${response.statusCode}): ${response.body}',
      );
    }
    if (response.body.isEmpty) return true;
    final dynamic decoded = jsonDecode(response.body);
    return decoded is! Map || decoded['success'] != false;
  }

  static Future<bool> createProduct({
    required String name,
    required String sku,
    required double price,
    required int typeId,
    required String imageUrl,
  }) async {
    try {
      final token = await _getToken();

      final url = Uri.parse('$_baseUrl/api/products/product/create');
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        return decoded['success'] == true;
      } else if (response.statusCode == 401) {
        await AuthService.logout();
        throw Exception('Sesión expirada (401).');
      } else {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        final errorMsg =
            decoded['message'] ?? decoded['error'] ?? response.body;
        throw Exception(errorMsg);
      }
    } catch (e, stack) {
      print('--> Error en ProductService.createProduct: $e');
      print('--> Stacktrace: $stack');
      rethrow;
    }
  }
}
