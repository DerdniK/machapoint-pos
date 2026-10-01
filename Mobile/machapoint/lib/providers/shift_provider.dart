import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:MachaPoint/providers/auth_provider.dart'; 
import 'package:http/http.dart' as http;

class ShiftProvider with ChangeNotifier {
  int? _activeShiftId;
  double _initialCash = 0.0;
  bool _isLoading = false;
  String? _errorMessage;
  double _totalSales = 0.0;
  int _totalSalesCount = 0;
  double _expectedCash = 0.0;
  DateTime? _openedAt;
  DateTime? _closedAt;

  int? get activeShiftId => _activeShiftId;
  bool get hasActiveShift => _activeShiftId != null;
  double get initialCash => _initialCash;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get totalSales => _totalSales;
  int get totalSalesCount => _totalSalesCount;
  double get expectedCash => _expectedCash;
  DateTime? get openedAt => _openedAt;
  DateTime? get closedAt => _closedAt;

  static const String baseUrl =
      'https://hdkp6ejncitdyw5yfwyxc4sj4i0srjxb.lambda-url.us-east-1.on.aws/api';

  void resetShift() {
    _activeShiftId = null;
    _initialCash = 0.0;
    _totalSales = 0.0;
    _totalSalesCount = 0;
    _expectedCash = 0.0;
    _openedAt = null;
    _closedAt = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    if (value is num) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  int? _parseShiftId(dynamic rawId) {
    if (rawId == null) return null;
    if (rawId is int) return rawId;
    return int.tryParse(rawId.toString());
  }

  Future<bool> checkActiveShift({
    required String token,
    required String cashierId,
  }) async {
    if (cashierId.trim().isEmpty) {
      debugPrint('--- CHECK SHIFT SKIPPED: cashierId está vacío ---');
      resetShift();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('$baseUrl/shift/active?cashierid=$cashierId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        final data = _decodeObject(response.body);
        if (data != null) {
          final id = data['shiftid'] ?? data['shift_id'] ?? data['id'] ?? data['shiftId'];
          final parsedId = _parseShiftId(id);

          if (parsedId != null) {
            _activeShiftId = parsedId;
            _initialCash = (data['openingamount'] as num?)?.toDouble() ?? 0.0;
            _expectedCash = (data['expectedcash'] as num?)?.toDouble() ?? _initialCash;
            _openedAt = _parseDate(
              data['openedAt'] ?? data['opened_at'] ?? data['startDate'] ?? data['startedAt'] ?? data['createdAt'],
            );
            _closedAt = _parseDate(
              data['closedAt'] ?? data['closed_at'] ?? data['endDate'] ?? data['endedAt'],
            );
            notifyListeners();
            return true;
          }
        }
        resetShift();
        return false;
      }

      resetShift();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al verificar turno activo: $e';
      resetShift();
      return false;
    }
  }

  Future<bool> openShift({
    required String token,
    required String cashierId,
    required double initialCash,
  }) async {
    if (cashierId.trim().isEmpty) {
      _errorMessage = 'No se pudo identificar al cajero autenticado.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final payload = {
      'cashierid': cashierId,
      'openingamount': initialCash,
    };

    try {
      debugPrint('>>> Abriendo turno con cashierId: $cashierId');
      final response = await http.post(
        Uri.parse('$baseUrl/shift/open'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      _isLoading = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _decodeObject(response.body);
        if (data == null) {
          _errorMessage = 'La API abrió el turno, pero no devolvió un JSON válido.';
          notifyListeners();
          return false;
        }

        final rawId = data['shiftid'] ?? data['shift_id'] ?? data['id'] ?? data['shiftId'];
        _activeShiftId = _parseShiftId(rawId);

        if (_activeShiftId == null) {
          _errorMessage = 'El turno respondió correctamente, pero el backend no devolvió un shiftId numérico.';
          notifyListeners();
          return false;
        }

        _initialCash = initialCash;
        _totalSales = 0.0;
        _totalSalesCount = 0;
        _expectedCash = initialCash;
        _openedAt = DateTime.now();
        _closedAt = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = _readError(response.body, response.statusCode);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error de conexión: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  void _applySummary(Map<String, dynamic> source) {
    final cut = Map<String, dynamic>.from(source);
    _totalSales = _asDouble(
      cut['totalSales'] ?? cut['total_sales'] ?? cut['total'] ?? cut['salesTotal'] ?? cut['totalAmount'],
    );
    _totalSalesCount = _asInt(
      cut['totalSalesCount'] ?? cut['total_sales_count'] ?? cut['salesCount'] ?? cut['count'],
    );
    _expectedCash = _asDouble(
      cut['expectedCash'] ?? cut['expected_cash'] ?? cut['cashExpected'],
      fallback: _initialCash + _totalSales,
    );
  }

  Future<void> refreshSalesSummary(String token) async {
    final shiftId = _activeShiftId;
    if (shiftId == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://2v34s2xxn4rxq6utaxaaoawpb40soivi.lambda-url.us-east-1.on.aws/api/cut/zcuts?shiftId=$shiftId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;

      final cuts = decoded['cuts'];
      if (cuts is List && cuts.isNotEmpty && cuts.first is Map) {
        _applySummary(Map<String, dynamic>.from(cuts.first as Map));
        notifyListeners();
      }
    } catch (_) {}
  }

  String _readError(String body, int statusCode) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        return data['message']?.toString() ?? data['error']?.toString() ?? 'Error ($statusCode)';
      }
    } catch (_) {}
    return 'Error ($statusCode)';
  }

  Map<String, dynamic>? _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> closeShift({
    required String token,
    required String cashierId,
    required double actualCash,
    required String notes,
  }) async {
    if (_activeShiftId == null) {
      return {'success': false, 'message': 'No hay un turno activo para cerrar'};
    }

    final payload = {
      'shiftid': _activeShiftId,
      'cashierid': cashierId,
      'actualcash': actualCash,
      'notes': notes,
    };

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shift/close'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      _isLoading = false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final currentShiftId = _activeShiftId;
        resetShift();
        return {
          'success': true,
          'shiftId': currentShiftId,
        };
      } else {
        notifyListeners();
        return {'success': false, 'message': 'Error al cerrar el turno'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}