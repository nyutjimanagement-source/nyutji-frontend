import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/lg_washer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LgWasherService {
  Future<List<Map<String, dynamic>>> getDevicesByUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/lg/washer/user/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(jsonResponse['data']);
    } else {
      throw Exception('Failed to load devices');
    }
  }

  Future<LgWasherModel> getWasherStatus(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/lg/washer/$deviceId/status'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return LgWasherModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Failed to load washer status');
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/lg/washer/available'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(jsonResponse['data']);
    } else {
      throw Exception('Failed to load available devices');
    }
  }

  Future<bool> registerDevice(String userId, String deviceId, String name, String model) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/lg/washer/register'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'deviceId': deviceId,
        'name_machine': name,
        'model': model
      }),
    );

    return response.statusCode == 201;
  }
}

