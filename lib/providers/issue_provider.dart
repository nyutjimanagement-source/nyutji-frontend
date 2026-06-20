import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/api_service.dart';
import '../data/services/cache_service.dart';

class IssueProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _issues = [];
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;
  DateTime? _lastIssuesFetch;

  List<dynamic> get issues => _issues;
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

  Future<void> fetchIssues({bool force = false}) async {
    // Throttling: Batasi request ke server maksimal tiap 15 detik
    if (!force && _lastIssuesFetch != null && DateTime.now().difference(_lastIssuesFetch!) < const Duration(seconds: 15)) {
      debugPrint('[fetchIssues] Throttled (kurang dari 15 detik).');
      return;
    }

    // Cache-first: Tampilkan data cache instan sebelum fetch ke server
    const cacheKey = 'issues_list';
    final cached = CacheService.get(cacheKey);
    if (cached != null && cached is List) {
      _issues = cached;
      _safeNotifyListeners();
    }

    _lastIssuesFetch = DateTime.now();
    _error = null;

    try {
      _issues = await _apiService.getIssues();
      await CacheService.set(cacheKey, _issues);
    } catch (e) {
      _error = e.toString();
      debugPrint('[fetchIssues] Error: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> reportIssue(String issueType, String description, String priority) async {
    try {
      await _apiService.reportIssue(issueType, description, priority);
      await fetchIssues(force: true); // Force refresh setelah mutasi
      return true;
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> updateIssueStatus(int issueId, String newStatus) async {
    try {
      await _apiService.updateIssueStatus(issueId, newStatus);
      await fetchIssues(force: true); // Force refresh setelah mutasi
      return true;
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }
}

final issueProvider = ChangeNotifierProvider<IssueProvider>((ref) => IssueProvider());
