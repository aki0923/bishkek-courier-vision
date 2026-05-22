import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Используйте ваш реальный API URL
  static const String baseUrl = 'http://localhost:8000/api';

  Future<Map<String, dynamic>> login(String courierId, String aggregator) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'courier_id': courierId,
          'aggregator': aggregator,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getNearbyAddresses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/addresses/nearby'),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}