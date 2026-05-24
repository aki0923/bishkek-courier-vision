import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _courierId;
  String? _aggregator;
  Map<String, dynamic>? _userData;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  final ApiService _apiService = ApiService();

  String? get courierId => _courierId;
  String? get aggregator => _aggregator;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  int get balance => _userData?['balance'] ?? 0;
  double get multiplier => (_userData?['multiplier'] ?? 1.0).toDouble();
  int get weeklyContributions => _userData?['weekly_contributions'] ?? 0;

  Future<bool> login(String courierId, String aggregator) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(courierId, aggregator);

      if (response['status'] == 'success') {
        _courierId = courierId;
        _aggregator = aggregator;
        _userData = response['data']['user'];
        _isAuthenticated = true;

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('courier_id', courierId);
        await prefs.setString('aggregator', aggregator);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (!_isAuthenticated) return;

    try {
      final response = await _apiService.getProfile();

      if (response['status'] == 'success') {
        _userData = response['data']['user'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Profile refresh error: $e');
    }
  }

  void updateBalance(int newBalance) {
    if (_userData != null) {
      _userData!['balance'] = newBalance;
      notifyListeners();
    }
  }

  void incrementWeeklyContributions() {
    if (_userData != null) {
      _userData!['weekly_contributions'] =
          (_userData!['weekly_contributions'] ?? 0) + 1;
      notifyListeners();
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

