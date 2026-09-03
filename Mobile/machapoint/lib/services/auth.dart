import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  
  static const String _baseUrl =
      'https://tmvksz56enigo6ojk25lfvg6x40vigzo.lambda-url.us-east-1.on.aws/api/users';

  // Login contra la API Lambda
  static Future<bool> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Username': username,
          'Password': password,
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? token = data['authData']?['token'] ?? data['token'];

        if (token != null && token.isNotEmpty) {
          await _storage.write(key: 'jwt_token', value: token);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error en Login: $e');
      return false;
    }
  }

  // Google OAuth
  static Future<bool> signInWithGoogle() async {
    try {
      final supabase = Supabase.instance.client;
      final sessionFuture = supabase.auth.onAuthStateChange
          .where((state) => state.session != null)
          .map((state) => state.session!)
          .first;

      final launched = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'machapoint://login-callback',
      );
      if (!launched) return false;

      final session = await sessionFuture.timeout(const Duration(minutes: 2));
      await _storage.write(key: 'jwt_token', value: session.accessToken);
      return true;
    } catch (e) {
      debugPrint('Error en Google OAuth: $e');
      return false;
    }
  }

  // Obtener Token de sesión
  static Future<String?> getToken() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) return session.accessToken;
    return await _storage.read(key: 'jwt_token');
  }

  // Cerrar Sesión
  static Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await Supabase.instance.client.auth.signOut();
  }
}