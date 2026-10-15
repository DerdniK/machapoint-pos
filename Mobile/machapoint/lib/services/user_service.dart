import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'auth.dart';

class UserService {
  static const String baseUrl =
      'https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws';

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

  static Future<bool> updateUser({
    required String userId,
    String? username,
    String? firstname,
    String? lastname,
    int? roleId,
  }) async {
    final token = await AuthService.getToken();
    final payload = <String, dynamic>{'userid': userId};
    if (username != null && username.trim().isNotEmpty) {
      payload['username'] = username.trim();
    }
    if (firstname != null && firstname.trim().isNotEmpty) {
      payload['firstname'] = firstname.trim();
    }
    if (lastname != null && lastname.trim().isNotEmpty) {
      payload['lastname'] = lastname.trim();
    }
    if (roleId != null) payload['roleid'] = roleId;

    final response = await http.patch(
      Uri.parse('$baseUrl/api/users/auth/update'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _responseSucceeded(response.body);
    } else {
      final errorMessage = _extractMessage(response.body, response.statusCode);
      throw Exception(errorMessage);
    }
  }

  static Future<List<UserRecord>> getUsers({String? userId}) async {
    final token = await AuthService.getToken();
    final baseUri = Uri.parse('$baseUrl/api/users/auth/view');
    final uri = userId == null || userId.trim().isEmpty
        ? baseUri
        : baseUri.replace(queryParameters: {'userid': userId.trim()});
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    final responseBody = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(responseBody, response.statusCode));
    }
    if (responseBody.trim().isEmpty) return [];

    final dynamic decoded = jsonDecode(responseBody);
    if (decoded == null) return [];
    dynamic records = decoded;
    if (decoded is Map) {
      final normalized = {
        for (final entry in decoded.entries)
          entry.key.toString().toLowerCase().replaceAll('_', ''): entry.value,
      };
      final hasEnvelope = const [
        'users',
        'user',
        'data',
        'results',
      ].any(normalized.containsKey);
      if (hasEnvelope) {
        records =
            normalized['users'] ??
            normalized['user'] ??
            normalized['data'] ??
            normalized['results'];
        if (records == null) return [];
      } else if (normalized.containsKey('userid') ||
          normalized.containsKey('id')) {
        records = decoded;
      } else {
        throw const FormatException('La respuesta no contiene usuarios.');
      }
    }
    if (records is Map) {
      records = [records];
    }
    if (records is! List) {
      throw const FormatException('Formato de respuesta de usuarios inválido.');
    }
    return records
        .whereType<Map>()
        .map((record) => UserRecord.fromJson(Map<String, dynamic>.from(record)))
        .toList();
  }

  static bool _responseSucceeded(String body) {
    if (body.trim().isEmpty) return true;
    final dynamic decoded = jsonDecode(body);
    if (decoded is bool) return decoded;
    if (decoded is Map && decoded['success'] is bool) {
      return decoded['success'] as bool;
    }
    return true;
  }

  static Future<bool> deleteUser({required String userId}) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/api/users/auth/delete'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'Userid': userId}),
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
