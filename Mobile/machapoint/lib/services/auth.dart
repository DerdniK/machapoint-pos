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

  static Future<Map<String, String>?> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');

    try {
      // NOTA: Se removió "await logout();" para evitar limpiar almacenamiento durante la petición
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        debugPrint('RESPUESTA RAW DEL BACKEND: $data');

        // Extraer Token
        final String? token = data['token'] ?? 
                             data['authData']?['token'] ?? 
                             data['accessToken'];

        // Extraer userId
        String? userId = (data['userId'] ?? 
                          data['user']?['id'] ?? 
                          data['id'] ?? 
                          data['user_id'] ?? 
                          data['cashierId'] ??
                          data['authData']?['userId'])?.toString();

        // Fallback: extraer 'sub' desde el Token JWT si userId viene nulo
        if ((userId == null || userId.isEmpty) && token != null) {
          userId = _getUserIdFromJwt(token);
        }

        final String nameToSave = data['name'] ?? 
                                  data['userName'] ?? 
                                  data['username'] ?? 
                                  username;

        debugPrint('>>> NUEVO USER_ID GUARDADO: $userId');

        if (token != null) await _storage.write(key: 'jwt_token', value: token);
        if (userId != null) await _storage.write(key: 'user_id', value: userId);
        await _storage.write(key: 'user_name', value: nameToSave);
        
        if (token != null) {
          return {
            'token': token,
            'userId': userId ?? '',
            'userName': nameToSave,
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error en Login: $e');
      return null;
    }
  }

  // Método auxiliar para extraer el ID desde el payload del JWT
  static String? _getUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final Map<String, dynamic> data = jsonDecode(payload);
      return data['sub']?.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

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
      await _storage.write(key: 'user_id', value: session.user.id);
      
      final googleName = session.user.userMetadata?['full_name'] ?? session.user.email;
      if (googleName != null) {
        await _storage.write(key: 'user_name', value: googleName);
      }

      return true;
    } catch (e) {
      debugPrint('Error en Google OAuth: $e');
      return false;
    }
  }

  static Future<String?> getToken() async {
    final localToken = await _storage.read(key: 'jwt_token');
    if (localToken != null && localToken.isNotEmpty) return localToken;

    final session = Supabase.instance.client.auth.currentSession;
    return session?.accessToken;
  }

  static Future<String?> getUserId() async {
    final localUserId = await _storage.read(key: 'user_id');
    if (localUserId != null && localUserId.isNotEmpty) return localUserId;

    final user = Supabase.instance.client.auth.currentUser;
    return user?.id;
  }

  static Future<String?> getUserName() async {
    final localName = await _storage.read(key: 'user_name');
    if (localName != null && localName.isNotEmpty) return localName;

    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['full_name'] ?? user?.email;
  }

  static Future<void> logout() async {
    await _storage.deleteAll();
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }
}