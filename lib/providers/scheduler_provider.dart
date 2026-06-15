import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_service.dart';

class SchedulerProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _schedules = [];
  List<dynamic> get schedules => _schedules;

  List<dynamic> _availableMitras = [];
  List<dynamic> get availableMitras => _availableMitras;

  final ApiService _api = ApiService();
  static const String _cacheKey = 'nyutji_cached_schedules';

  SchedulerProvider() {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);
    if (cachedData != null) {
      try {
        _schedules = json.decode(cachedData);
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading cached schedules: $e");
      }
    }
  }

  Future<void> fetchSchedules({String cityName = 'Tangerang Selatan'}) async {
    if (_schedules.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final mitras = await _api.getRecommendedMitras(cityName: cityName);
      _availableMitras = mitras;
      
      final schedulesData = await _api.getCustomerSchedules();
      _schedules = schedulesData;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(_schedules));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching schedules: $e');
    }
  }

  Future<void> createSchedule(Map<String, dynamic> data) async {
    // Optimistic UI Update
    final newSchedule = Map<String, dynamic>.from(data);
    newSchedule['id'] = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    newSchedule['status'] = 'ACTIVE';
    // Dummy mitra data for optimistic rendering
    if (data['mitra_identifier'] != null) {
      newSchedule['mitra'] = {'name': 'Memuat...'}; 
    }
    
    _schedules.insert(0, newSchedule);
    notifyListeners();

    try {
      final result = await _api.createRescheduler(data);
      // Replace temp with actual data
      final index = _schedules.indexWhere((s) => s['id'] == newSchedule['id']);
      if (index != -1 && result['data'] != null) {
        _schedules[index] = result['data'];
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(_schedules));
      
      notifyListeners();
    } catch (e) {
      debugPrint('Schedule created offline / Error: $e');
      // Offline queue is handled by RetryInterceptor automatically
    }
  }

  Future<void> deleteSchedule(String id) async {
    // Optimistic UI Update
    final backupSchedules = List<dynamic>.from(_schedules);
    _schedules.removeWhere((s) => s['id'].toString() == id);
    notifyListeners();

    try {
      await _api.deleteRescheduler(id);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(_schedules));
    } catch (e) {
      debugPrint('Schedule deleted offline / Error: $e');
      // RetryInterceptor handles offline queue
    }
  }
}

final schedulerProvider = ChangeNotifierProvider<SchedulerProvider>((ref) => SchedulerProvider());
