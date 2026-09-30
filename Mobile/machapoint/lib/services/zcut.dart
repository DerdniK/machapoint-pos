import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth.dart';

class ZCutService {
  static const String _baseUrl = 'https://2v34s2xxn4rxq6utaxaaoawpb40soivi.lambda-url.us-east-1.on.aws/api/cut/zcuts';
  static Future<List<dynamic>> getZCuts({int? shiftId}) async {
    final token = await AuthService.getToken();
  
    final uri = shiftId != null 
        ? Uri.parse('$_baseUrl?shiftId=$shiftId')
        : Uri.parse(_baseUrl);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['cuts'] as List<dynamic>;
      }
    }
    
    return [];
  }
}