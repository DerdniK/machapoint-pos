import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'auth.dart';

class UserService {
  static const String baseUrl = 'https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws';

  // 1. Método exclusivo para registrar
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
      throw Exception('Error al registrar: ${response.body}');
    }
  }

  // 2. Método exclusivo para actualizar usuario
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
      throw Exception('Error al actualizar: ${response.statusCode} - ${response.body}');
    }
  }

  // 3. Método exclusivo para eliminar usuario
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
      throw Exception('Error al eliminar: ${response.statusCode} - ${response.body}');
    }
  }
}