import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth.dart';

class ShiftService {
  static const String _baseUrl = 'https://hdkp6ejncitdyw5yfwyxc4sj4i0srjxb.lambda-url.us-east-1.on.aws/api/shift';

  static Future<bool> openShift({required String cashierId, required double openingAmount}) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/open'),
      headers: {
        'Content-Type': 'json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'cashierid': cashierId,
        'openingamount': openingAmount,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<bool> closeShift({
    required int shiftId,
    required String cashierId,
    required double actualCash,
    String notes = '',
  }) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/close'),
      headers: {
        'Content-Type': 'json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'shiftid': shiftId,
        'cashierid': cashierId,
        'actualcash': actualCash,
        'notes': notes,
      }),
    );
    return response.statusCode == 200;
  }
}