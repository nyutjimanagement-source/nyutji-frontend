import 'package:flutter/material.dart';
import '../data/services/api_service.dart';

class SentimentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _sentiments = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _error;

  List<dynamic> get sentiments => _sentiments;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSentiments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getSocialSentiments();
      if (response['status'] == 'success') {
        _sentiments = response['data'] ?? [];
        _summary = response['summary'] ?? {};
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
