import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Используйте ваш реальный API URL
  // Для Android эмулятора: http://10.0.2.2:8000
  // Для iOS симулятора: http://localhost:8000
  // Для реального устройства: http://YOUR_IP:8000
  static const String baseUrl = 'http://localhost:8000/api';

  String? _token;

  Future<void> _loadToken() async {
    if (_token != null) return;

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<Map<String, String>> _getHeaders({bool needsAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (needsAuth) {
      await _loadToken();
      if (_token != null) {
        headers['Authorization'] = 'Bearer $_token';
      }
    }

    return headers;
  }

  // Authentication
  Future<Map<String, dynamic>> login(String courierId, String aggregator) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'courier_id': courierId,
          'aggregator': aggregator,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        // Save token
        await _saveToken(data['data']['token']);
        return data;
      }

      return {'status': 'error', 'message': data['message'] ?? 'Login failed'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: await _getHeaders(needsAuth: true),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Addresses
  Future<Map<String, dynamic>> getNearbyAddresses({
    double lat = 42.8746,
    double lng = 74.5698,
    int radius = 2000,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/addresses/nearby').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'radius': radius.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAddressDetails(int addressId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/addresses/$addressId'),
        headers: await _getHeaders(),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> searchAddresses(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/addresses/search').replace(
        queryParameters: {'q': query},
      );

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Contributions
  Future<Map<String, dynamic>> submitContribution({
    required int addressId,
    required String type,
    String? photoData,
    String? hintText,
    String? code,
    int? entranceNumber,
    String? gateNumber,
  }) async {
    try {
      final body = <String, dynamic>{
        'address_id': addressId,
        'type': type,
      };

      if (type == 'photo' && photoData != null) {
        body['photo_data'] = photoData;
      } else if (type == 'hint' && hintText != null) {
        body['hint_text'] = hintText;
      } else if (type == 'code' && code != null) {
        body['code'] = code;
      }

      if (entranceNumber != null) {
        body['entrance_number'] = entranceNumber;
      }

      if (gateNumber != null) {
        body['gate_number'] = gateNumber;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/contributions'),
        headers: await _getHeaders(needsAuth: true),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 120)); // 2 minutes for AI processing

      return jsonDecode(response.body);
    } on SocketException {
      return {
        'status': 'error',
        'message': 'Нет подключения к интернету'
      };
    } on http.ClientException {
      return {
        'status': 'error',
        'message': 'Ошибка подключения к серверу'
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getContributionHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/contributions').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: await _getHeaders(needsAuth: true),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}

