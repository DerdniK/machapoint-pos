import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth.dart';

class ZCutService {
  static const String _baseUrl =
      'https://2v34s2xxn4rxq6utaxaaoawpb40soivi.lambda-url.us-east-1.on.aws/api/cut/zcuts';

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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error al consultar cortes (${response.statusCode}): ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is List) return decoded;
    if (decoded is! Map) {
      throw const FormatException('Formato de respuesta de cortes inválido.');
    }

    if (decoded['success'] == false) {
      throw Exception(
        decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            'No se pudieron consultar los cortes.',
      );
    }

    final dynamic cuts =
        decoded['cuts'] ?? decoded['data'] ?? decoded['results'];
    if (cuts is List) return cuts;
    if (cuts == null) return [];
    throw const FormatException(
      'La respuesta no contiene una lista de cortes.',
    );
  }
}
