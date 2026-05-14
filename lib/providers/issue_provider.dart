import 'package:flutter/material.dart';
import '../data/services/api_service.dart';

class IssueProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _issues = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get issues => _issues;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchIssues() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _issues = await _apiService.getIssues();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reportIssue(String issueType, String description, String priority) async {
    try {
      await _apiService.reportIssue(issueType, description, priority);
      await fetchIssues(); // Refresh list after reporting
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateIssueStatus(int issueId, String newStatus) async {
    try {
      await _apiService.updateIssueStatus(issueId, newStatus);
      await fetchIssues(); // Refresh list after updating
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
