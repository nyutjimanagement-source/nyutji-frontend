import 'package:flutter/material.dart';
import '../data/services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _activeOrders = [];
  List<dynamic> get activeOrders => _activeOrders;
  
  List<dynamic> _historyOrders = [];
  List<dynamic> get historyOrders => _historyOrders;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final ApiService _api = ApiService();

  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> orders = await _api.getOrders();
      // Pemisahan Sederhana: Status selesai vs belum
      _activeOrders = orders.where((o) => o['status'] != 'selesai').toList();
      _historyOrders = orders.where((o) => o['status'] == 'selesai').toList();
    } catch (e) {
      _errorMessage = 'Gagal memuat data pesanan';
      // Menyuntikkan Dummy Data sementara jika Backend mati
      _activeOrders = [
        {'id': 'KBY-040426-001', 'status': 'dicuci', 'total': 21000},
        {'id': 'KBY-040426-002', 'status': 'diambil', 'total': 45000},
      ];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.createOrder(data);
      await fetchOrders(); // Segarkan data
      return true;
    } catch (e) {
      _errorMessage = 'Gagal membuat pesanan baru';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
