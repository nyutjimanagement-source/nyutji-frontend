import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/api_service.dart';
import '../data/services/cache_service.dart';

class SentimentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _sentiments = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;
  DateTime? _lastSentimentsFetch;

  List<dynamic> get sentiments => _sentiments;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  Future<void> fetchSentiments({bool force = false}) async {
    // Throttling: Batasi request ke server maksimal tiap 15 detik
    if (!force && _lastSentimentsFetch != null && DateTime.now().difference(_lastSentimentsFetch!) < const Duration(seconds: 15)) {
      debugPrint('[fetchSentiments] Throttled (kurang dari 15 detik).');
      return;
    }

    // Cache-first: Tampilkan data cache instan sebelum fetch ke server
    const cacheKey = 'sentiments_data';
    final cached = CacheService.get(cacheKey);
    if (cached != null && cached is Map) {
      _sentiments = (cached['sentiments'] as List?) ?? [];
      _summary = (cached['summary'] as Map<String, dynamic>?) ?? {};
      _safeNotifyListeners();
    }

    _lastSentimentsFetch = DateTime.now();
    _error = null;

    try {
      final response = await _apiService.getSocialSentiments();
      if (response['status'] == 'success') {
        _sentiments = response['data'] ?? [];
        _summary = response['summary'] ?? {};
        await CacheService.set(cacheKey, {
          'sentiments': _sentiments,
          'summary': _summary,
        });
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('[fetchSentiments] Error: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }
}

final sentimentProvider = ChangeNotifierProvider<SentimentProvider>((ref) => SentimentProvider());
