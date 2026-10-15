import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth.dart';

class CartItem {
  static const int maximumQuantity = 20;

  final int productId;
  final String? productName;
  final String imageUrl;
  final double unitPrice;
  int? availableStock;
  int quantity;

  CartItem({
    required this.productId,
    this.productName,
    this.imageUrl = '',
    required this.unitPrice,
    this.availableStock,
    this.quantity = 1,
  });

  int get quantityLimit =>
      availableStock != null && availableStock! < maximumQuantity
      ? availableStock!.clamp(0, maximumQuantity)
      : maximumQuantity;

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
  static const String _referenceCharacters =
      'abcdefghijklmnopqrstuvwxyz0123456789';
  static final Random _referenceRandom = Random.secure();

  static String _generateTransactionReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final suffix = List.generate(
      10,
      (_) =>
          _referenceCharacters[_referenceRandom.nextInt(
            _referenceCharacters.length,
          )],
    ).join();
    return 'ref-$timestamp-$suffix';
  }

  static dynamic _normalizedValue(
    Map<String, dynamic> source,
    Iterable<String> keys,
  ) {
    final normalized = {
      for (final entry in source.entries)
        entry.key.toLowerCase().replaceAll(RegExp(r'[_\s-]'), ''): entry.value,
    };
    for (final key in keys) {
      final value =
          normalized[key.toLowerCase().replaceAll(RegExp(r'[_\s-]'), '')];
      if (value != null) return value;
    }
    return null;
  }

  static double cashSalesTotal(Iterable<Map<String, dynamic>> sales) {
    return sales.fold<double>(0, (total, sale) {
      final paymentMethod =
          (_normalizedValue(sale, [
                    'payment_method',
                    'paymentMethod',
                    'paymentmethod',
                  ]) ??
                  '')
              .toString()
              .trim()
              .toLowerCase();
      if (paymentMethod.isEmpty) {
        throw const FormatException(
          'Una venta del turno no incluye su método de pago.',
        );
      }
      if (paymentMethod != 'efectivo' && paymentMethod != 'cash') {
        return total;
      }

      final rawAmount = _normalizedValue(sale, [
        'total',
        'saleTotal',
        'sale_total',
        'totalAmount',
        'amount',
      ]);
      final amount = rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount?.toString() ?? '');
      if (amount == null) {
        throw const FormatException(
          'Una venta en efectivo no incluye un total válido.',
        );
      }
      return total + amount;
    });
  }

  static Future<List<Map<String, dynamic>>> getSales({int? shiftId}) async {
    final uri = shiftId == null
        ? Uri.parse(_url)
        : Uri.parse(
            '$_url/by-shift',
          ).replace(queryParameters: {'shiftId': shiftId.toString()});
    return _getSales(uri);
  }

  static Future<List<Map<String, dynamic>>> getSalesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    String formatDate(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse('$_url/by-date-range').replace(
      queryParameters: {
        'startDate': formatDate(startDate),
        'endDate': formatDate(endDate),
      },
    );
    return _getSales(uri);
  }

  static Future<List<Map<String, dynamic>>> _getSales(Uri uri) async {
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken ??
        await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No se encontró token de sesión.');
    }
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final responseBody = utf8.decode(response.bodyBytes);
    if (response.statusCode == 401) {
      await AuthService.logout();
      throw Exception('Sesión expirada (401).');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Error del servidor (${response.statusCode}): $responseBody',
      );
    }
    final dynamic decoded = jsonDecode(responseBody);
    if (decoded == null) {
      throw const FormatException(
        'La API de ventas respondió null; se esperaba una lista de ventas.',
      );
    }
    dynamic sales = decoded;
    if (decoded is Map<String, dynamic>) {
      sales = decoded['data'] ?? decoded['sales'] ?? decoded['sale'];
    }
    if (sales is! List) {
      throw const FormatException(
        'La respuesta de ventas no contiene una lista de ventas.',
      );
    }
    return sales.map((sale) {
      if (sale is! Map) {
        throw const FormatException(
          'La respuesta de ventas contiene un elemento con formato inválido.',
        );
      }
      return Map<String, dynamic>.from(sale);
    }).toList();
  }

  static Future<Map<String, dynamic>> processSale({
    required int shiftId,
    required String cashierId,
    required double total,
    required String paymentMethod,
    required double amountGiven,
    required double changeGiven,
    required List<CartItem> products,
  }) async {
    try {
      final token = await AuthService.getToken();
      final transactionReference = _generateTransactionReference();
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
