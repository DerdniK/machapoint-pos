import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth.dart';

class CartItem {
  final int productId;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  CartItem({
    required this.productId,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'unit_price': unitPrice,
        'quantity': quantity,
        'subtotal': subtotal,
      };
}

class SaleService {
  static const String _url = 'https://6uxm3jz7xwth5cliak6zk6dudi0iseih.lambda-url.us-east-1.on.aws/api/sale';

  static Future<bool> processSale({
    required int shiftId,
    required String cashierId,
    required double total,
    required String paymentMethod,
    required double amountGiven,
    required double changeGiven,
    required String transactionReference,
    required List<CartItem> products,
  }) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'json',
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

    return response.statusCode == 201 || response.statusCode == 200;
  }
}