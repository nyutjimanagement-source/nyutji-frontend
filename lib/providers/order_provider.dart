import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../data/services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _activeOrders = [];
  List<dynamic> get activeOrders => _activeOrders;
  
  List<dynamic> _historyOrders = [];
  List<dynamic> get historyOrders => _historyOrders;

  // Order tersedia untuk Kurir (marketplace KL)
  List<dynamic> _availableOrders = [];
  List<dynamic> get availableOrders => _availableOrders;

  Map<String, dynamic>? _trackingOrder;
  Map<String, dynamic>? get trackingOrder => _trackingOrder;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final ApiService _api = ApiService();
  Timer? _trackingTimer;

  // --- NOTIF BADGE SYSTEM ---
  int _notifCountPL = 0;
  int _notifCountML = 0;
  int _notifCountKL = 0;

  int get notifCountPL => _notifCountPL;
  int get notifCountML => _notifCountML;
  int get notifCountKL => _notifCountKL;

  void addNotif(String role) {
    if (role == 'PL') _notifCountPL++;
    if (role == 'ML') _notifCountML++;
    if (role == 'KL') _notifCountKL++;
    notifyListeners();
  }

  void resetNotif(String role) {
    if (role == 'PL') _notifCountPL = 0;
    if (role == 'ML') _notifCountML = 0;
    if (role == 'KL') _notifCountKL = 0;
    notifyListeners();
  }

  final List<String> _statusSteps = [
    'Menunggu Kurir',
    'Kurir Menuju Lokasi',
    'Pesanan Diambil',
    'Proses Cuci',
    'Proses Jemur',
    'Proses Setrika',
    'Proses Packing',
    'Sedang Diantar',
    'Selesai'
  ];

  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> orders = await _api.getOrders();
      _activeOrders = orders.where((o) => o['status'] != 'selesai').toList();
      _historyOrders = orders.where((o) => o['status'] == 'selesai').toList();
    } catch (e) {
      _errorMessage = 'Gagal memuat data pesanan';
      _activeOrders = [
        {'id': 'KBY-040426-001', 'status': 'Proses Cuci', 'total': 21000.0},
      ];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch order tersedia di kecamatan KL dari backend
  // Jika backend belum siap (endpoint belum ada), fallback ke dummy agar UI tidak crash
  Future<void> fetchAvailableOrders(String districtName) async {
    try {
      final List<dynamic> data = await _api.getAvailableOrders(districtName);
      // Sort by total_price tertinggi
      data.sort((a, b) {
        final aPrice = (a['total_price'] as num?)?.toInt() ?? 0;
        final bPrice = (b['total_price'] as num?)?.toInt() ?? 0;
        return bPrice.compareTo(aPrice);
      });
      _availableOrders = data;
    } catch (e) {
      // Backend belum siap? Tetap tampilkan dummy agar UI tidak kosong
      debugPrint('[fetchAvailableOrders] Endpoint belum aktif, gunakan dummy: $e');
      _availableOrders = []; // kosongkan agar dummy di UI tetap tampil
    }
    notifyListeners();
  }

  // Simulasi WebSocket Tracking
  void startTrackingSimulation(String orderId) {
    _trackingTimer?.cancel();
    int currentStep = 0;
    
    _trackingOrder = {
      'id': orderId,
      'status': _statusSteps[currentStep],
      'progress': currentStep,
      'courier': 'Budi Santoso',
      'plate': 'B 3912 XYZ',
      'items': 'Laundry Kiloan (3 Kg)',
      'total': 21000.0,
    };
    notifyListeners();

    _trackingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_trackingOrder == null) {
        timer.cancel();
        return;
      }
      if (currentStep < _statusSteps.length - 1) {
        currentStep++;
        _trackingOrder!['status'] = _statusSteps[currentStep];
        _trackingOrder!['progress'] = currentStep;
        
        // Trigger Notif PL tiap ada update status
        addNotif('PL'); 
        
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void clearTracking() {
    _trackingTimer?.cancel();
    _trackingOrder = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  Future<bool> createOrder(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _api.createOrder(data);
      await fetchOrders(); 
      addNotif('ML'); // Notif buat Mitra ada order baru
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      debugPrint('[createOrder] DioException: status=${e.response?.statusCode} data=$data');
      final msg = data?['message']?.toString();
      final detail = data?['error']?.toString();
      if (msg != null && detail != null && msg != detail) {
        _errorMessage = '$msg\n↳ $detail';
      } else {
        _errorMessage = msg ?? detail ?? 'Gagal menghubungi server (${e.response?.statusCode}).';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _api.acceptOrder(orderId);
      // Refresh data
      await fetchOrders();
      // Reset available orders locally or fetch again
      _availableOrders.removeWhere((o) => o['id'] == orderId);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Gagal mengambil order';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignCourier(String orderId, int courierId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _api.assignCourier(orderId, courierId);
      // Refresh data agar status berubah di UI
      await fetchOrders();
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Gagal menunjuk kurir';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _api.updateOrderStatus(orderId, status);
      await fetchOrders();
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Gagal update status';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
