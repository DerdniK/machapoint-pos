import 'dart:convert';
import 'package:http/http.dart' as http;
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
        'message': 'Error de conexión: ${e.toString().replaceAll('Exception: ', '')}',
      };
    }
  }
}