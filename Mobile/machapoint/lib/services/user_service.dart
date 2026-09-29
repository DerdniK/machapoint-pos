import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'auth.dart';

class UserService {
  static const String baseUrl = 'https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws';

  static Future<bool> registerUser(UserModel user) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/users/auth/register'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty && response.body != 'null') {
        final data = jsonDecode(response.body);
        return data['success'] ?? true;
      }
      return true;
    } else {
      final errorMessage = _extractMessage(response.body, response.statusCode);
      throw Exception(errorMessage);
    }
  }

  static Future<bool> updateUser({required String userId, required String username}) async {
    final token = await AuthService.getToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/api/users/auth/update'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'Userid': userId,
        'Username': username,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else {
      final errorMessage = _extractMessage(response.body, response.statusCode);
      throw Exception(errorMessage);
    }
  }

  static Future<bool> deleteUser({required String userId}) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/api/users/auth/delete'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'Userid': userId,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else {
      final errorMessage = _extractMessage(response.body, response.statusCode);
      throw Exception(errorMessage);
    }
  }
  static String _extractMessage(String body, int statusCode) {
    try {
      if (body.isNotEmpty) {
        final data = jsonDecode(body);
        if (data is Map) {
          if (data.containsKey('message')) return data['message'].toString();
          if (data.containsKey('error')) return data['error'].toString();
          if (data.containsKey('detail')) return data['detail'].toString();
        }
      }
    } catch (_) {}
    return 'Status $statusCode: $body';
  }
}