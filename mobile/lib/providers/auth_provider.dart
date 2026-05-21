import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _courierId;
  String? _aggregator;
  Map<String, dynamic>? _userData;
  bool _isAuthenticated = false;

  String? get courierId => _courierId;
  String? get aggregator => _aggregator;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String courierId, String aggregator) async {
    try {
      final apiService = ApiService();
      final response = await apiService.login(courierId, aggregator);

      if (response['status'] == 'success') {
        _courierId = courierId;
        _aggregator = aggregator;
        _userData = response['data'];
        _isAuthenticated = true;

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('courier_id', courierId);
        await prefs.setString('aggregator', aggregator);

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _courierId = null;
    _aggregator = null;
    _userData = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final courierId = prefs.getString('courier_id');
    final aggregator = prefs.getString('aggregator');

    if (courierId != null && aggregator != null) {
      await login(courierId, aggregator);
    }
  }
}
