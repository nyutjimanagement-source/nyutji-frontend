import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/api_service.dart';

class RevenueSplitProvider with ChangeNotifier {
  List<dynamic> _revenueSplits = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = false;

  List<dynamic> get revenueSplits => _revenueSplits;
  Map<String, dynamic>? get summary => _summary;
  bool get isLoading => _isLoading;

  Future<void> fetchRevenueData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final summaryRes = await ApiService().getRevenueSplitSummary();
      final splitsRes = await ApiService().getRevenueSplits();
      
      _summary = summaryRes;
      _revenueSplits = splitsRes;
    } catch (e) {
      debugPrint("Error fetching revenue data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

final revenueSplitProvider = ChangeNotifierProvider<RevenueSplitProvider>((ref) => RevenueSplitProvider());
