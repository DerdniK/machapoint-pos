import 'package:flutter/material.dart';
import 'package:MachaPoint/services/auth.dart';
import 'package:MachaPoint/providers/shift_provider.dart';

class AuthProvider extends ChangeNotifier {
  String? _cashierName;
  String? _token;
  String? _userUuid;
  int? _roleId;
  bool _isLoading = true;

  String? get token => _token;
  String? get userUuid => _userUuid;
  String? get cashierId => _userUuid;
  String? get userName => _cashierName;
  int? get roleId => _roleId;
  bool get isAdmin => _roleId == 1;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = await AuthService.getToken();
      _userUuid = await AuthService.getUserId();
      _cashierName = await AuthService.getUserName();
      _roleId = await AuthService.getRoleId();
    } catch (e) {
      debugPrint('Error al inicializar sesión en AuthProvider: $e');
      _token = null;
      _userUuid = null;
      _cashierName = null;
      _roleId = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await AuthService.login(username, password);
    if (result != null) {
      _token = result['token'];
      _userUuid = result['userId'];
      _cashierName = result['userName'];
      _roleId = int.tryParse(result['roleId'] ?? '');
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout([ShiftProvider? shiftProvider]) async {
    await AuthService.logout();
    _token = null;
    _userUuid = null;
    _cashierName = null;
    _roleId = null;
    shiftProvider?.resetShift();
    notifyListeners();
  }
}
