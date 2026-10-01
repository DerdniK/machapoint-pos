import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth.dart';

class CartItem {
  final int productId;
  final String? productName;
  final double unitPrice;
  int quantity;

  CartItem({
    required this.productId,
    this.productName,
    required this.unitPrice,
    this.quantity = 1,
  });

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'unit_price': unitPrice,
    'quantity': quantity,
    'subtotal': subtotal,
  };
}

class SaleService {
  static const String _url =
      'https://6uxm3jz7xwth5cliak6zk6dudi0iseih.lambda-url.us-east-1.on.aws/api/sale';

  static Future<List<Map<String, dynamic>>> getSales({int? shiftId}) async {
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken ??
        await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No se encontró token de sesión.');
    }
    final uri = shiftId == null
        ? Uri.parse(_url)
        : Uri.parse(
            '$_url/by-shift',
          ).replace(queryParameters: {'shiftId': shiftId.toString()});
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 401) {
      await AuthService.logout();
      throw Exception('Sesión expirada (401).');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Error del servidor (${response.statusCode}): ${response.body}',
      );
    }
    final dynamic decoded = jsonDecode(response.body);
    dynamic sales = decoded;
    if (decoded is Map<String, dynamic>) {
      sales = decoded['data'] ?? decoded['sales'] ?? decoded['sale'];
    }
    if (sales is! List) return [];
    return sales
        .whereType<Map>()
        .map((sale) => Map<String, dynamic>.from(sale))
        .toList();
  }

  static Future<Map<String, dynamic>> processSale({
    required int shiftId,
    required String cashierId,
    required double total,
    required String paymentMethod,
    required double amountGiven,
    required double changeGiven,
    required String transactionReference,
    required List<CartItem> products,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'shiftId': shiftId,
          'cashierId': cashierId,
          'total': total,
          'payment_method': paymentMethod,
          'amount_given': amountGiven,
          'change_given': changeGiven,
          'transaction_reference': transactionReference,
          'products': products.map((p) => p.toJson()).toList(),
        }),
      );
      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');

      dynamic responseData;
      if (response.body.isNotEmpty) {
        try {
          responseData = jsonDecode(response.body);
        } catch (_) {
          responseData = null;
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
          'message': 'Venta realizada con éxito',
        };
      } else {
        return {
          'success': false,
          'message': responseData is Map
              ? responseData['message']?.toString() ??
                    responseData['error']?.toString() ??
                    'Error al procesar la venta (${response.statusCode})'
              : 'Error al procesar la venta (${response.statusCode}): ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Error de conexión: ${e.toString().replaceAll('Exception: ', '')}',
      };
    }
  }
}
