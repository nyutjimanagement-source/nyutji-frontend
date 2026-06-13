import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class OrderProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _activeOrders = [];
  List<dynamic> get activeOrders => _activeOrders;
  
  List<dynamic> _historyOrders = [];
  List<dynamic> get historyOrders => _historyOrders;

  List<dynamic> _recommendedMitras = [];
  List<dynamic> get recommendedMitras => _recommendedMitras;

  List<dynamic> _searchedMitras = [];
  List<dynamic> get searchedMitras => _searchedMitras;

  // Order tersedia untuk Kurir (marketplace KL)
  List<dynamic> _availableOrders = [];
  List<dynamic> get availableOrders => _availableOrders;

  List<dynamic> _draftOrders = [];
  List<dynamic> get draftOrders => _draftOrders;

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

  static const String _seenOrdersKey = 'nyutji_seen_orders';

  Future<void> checkPLNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> seenData = prefs.getStringList(_seenOrdersKey) ?? [];
      
      final Map<String, Map<String, dynamic>> seenMap = {};
      for (var item in seenData) {
        try {
          final parts = item.split('|');
          if (parts.length >= 3) {
            seenMap[parts[0]] = {
              'status': parts[1],
              'proofsCount': int.tryParse(parts[2]) ?? 0,
            };
          }
        } catch (e) {
          debugPrint("Error parsing seen order item: $e");
        }
      }

      int unseenCount = 0;

      for (var order in _activeOrders) {
        final orderNum = (order['order_number'] ?? order['id'] ?? '').toString();
        if (orderNum.isEmpty) continue;

        final currentStatus = (order['order_status'] ?? order['status'] ?? '').toString().toUpperCase();
        final currentProofs = (order['proofs'] as List?)?.length ?? 0;

        if (seenMap.containsKey(orderNum)) {
          final lastSeen = seenMap[orderNum]!;
          final lastSeenStatus = lastSeen['status'].toString().toUpperCase();
          final lastSeenProofs = lastSeen['proofsCount'] as int;

          // Dot merah active if status changed OR if there are new proofs
          if (currentStatus != lastSeenStatus || currentProofs > lastSeenProofs) {
            unseenCount++;
          }
        } else {
          // If never seen at all (e.g. newly created order), trigger the dot merah
          unseenCount++;
        }
      }

      _notifCountPL = unseenCount;
      notifyListeners();
    } catch (e) {
      debugPrint("Error checking PL notifications: $e");
    }
  }

  Future<void> markAllPLOrdersAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> newSeenData = [];

      for (var order in _activeOrders) {
        final orderNum = (order['order_number'] ?? order['id'] ?? '').toString();
        if (orderNum.isEmpty) continue;

        final currentStatus = (order['order_status'] ?? order['status'] ?? '').toString().toUpperCase();
        final currentProofs = (order['proofs'] as List?)?.length ?? 0;

        newSeenData.add("$orderNum|$currentStatus|$currentProofs");
      }

      await prefs.setStringList(_seenOrdersKey, newSeenData);
      _notifCountPL = 0;
      notifyListeners();
    } catch (e) {
      debugPrint("Error marking PL orders as seen: $e");
    }
  }

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

  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> orders = await _api.getOrders();
      debugPrint("Nyutji API Data: Diterima ${orders.length} pesanan");
      if (orders.isNotEmpty) debugPrint("Nyutji API Sample: ${orders.first}");

      // Ambil role aktif dari lokal storage
      final prefs = await SharedPreferences.getInstance();
      final role = (prefs.getString('role') ?? 'PL').toUpperCase();

      // SMART FILTER: Sesuai role user
      if (role == 'PL') {
        // Untuk Pelanggan (PL): DONE tetap aktif agar bisa ulasan/review
        _activeOrders = orders.where((o) {
          if (o is! Map) return false;
          final status = (o['order_status'] ?? o['status'] ?? '').toString().toLowerCase();
          return status != 'selesai' && status != 'completed' && status != 'paid';
        }).toList();
        
        _historyOrders = orders.where((o) {
          if (o is! Map) return false;
          final status = (o['order_status'] ?? o['status'] ?? '').toString().toLowerCase();
          return status == 'selesai' || status == 'completed' || status == 'paid';
        }).toList();

        await checkPLNotifications();
      } else {
        // Untuk Mitra (ML) & Kurir (KL): DONE sudah masuk riwayat / selesai!
        _activeOrders = orders.where((o) {
          if (o is! Map) return false;
          final status = (o['order_status'] ?? o['status'] ?? '').toString().toLowerCase();
          return status != 'done' && status != 'paid' && status != 'selesai' && status != 'completed';
        }).toList();
        
        _historyOrders = orders.where((o) {
          if (o is! Map) return false;
          final status = (o['order_status'] ?? o['status'] ?? '').toString().toLowerCase();
          return status == 'done' || status == 'paid' || status == 'selesai' || status == 'completed';
        }).toList();
      }
      
      debugPrint("Nyutji State untuk role $role: ${_activeOrders.length} aktif, ${_historyOrders.length} riwayat");
    } catch (e) {
      _errorMessage = 'Gagal memuat data pesanan';
      debugPrint("Nyutji Data Error: $e");
      // Fallback dummy hanya jika benar-benar kosong dan error
      if (_activeOrders.isEmpty && _historyOrders.isEmpty) {
        _activeOrders = [
          {'order_number': 'NYJ-DEBUG-001', 'order_status': 'Proses Cuci', 'grand_total': 21000.0},
        ];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecommendedMitras({String? cityName}) async {
    try {
      final List<dynamic> mitras = await _api.getRecommendedMitras(cityName: cityName);
      _recommendedMitras = mitras.take(5).toList();
      notifyListeners();

      // Fetch items proactively to populate services_text for search accuracy
      for (var m in _recommendedMitras) {
        if (m['id'] != null) {
          try {
            final items = await _api.getMitraItems(m['id']);
            if (items.isNotEmpty) {
              m['services_text'] = items.map((i) => i['name'] ?? '').join(' ');
              notifyListeners();
            }
          } catch (e) {
            debugPrint("Error fetching items for mitra ${m['id']}: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching mitras: $e");
      notifyListeners();
    }
  }

  Future<void> searchGlobal(String query) async {
    if (query.trim().isEmpty) {
      _searchedMitras = [];
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> results = await _api.searchMitras(query);
      _searchedMitras = results;
    } catch (e) {
      debugPrint("Error searching mitras: $e");
      _searchedMitras = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdminOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final List<dynamic> orders = await _api.getAdminOrders();
      // TANPA FILTER SESUAI INSTRUKSI JENDERAL: Tarik Semua order_number
      _activeOrders = orders;
      _historyOrders = []; // Kosongkan history agar tidak terjadi duplikasi saat penjumlahan
    } catch (e) {
      _errorMessage = 'Gagal memuat data admin pesanan';
      debugPrint("Nyutji Admin Data Error: $e");
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
        final aPrice = int.tryParse(a['total_price']?.toString() ?? '0') ?? 0;
        final bPrice = int.tryParse(b['total_price']?.toString() ?? '0') ?? 0;
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

  // Map Status String ke Progress Int (0-8)
  int getProgressFromStatus(String status) {
    final s = status.toLowerCase();
    if (s.contains('jemput') || s.contains('pickup')) return 0;
    if (s.contains('cuci') || s.contains('wash')) return 3;
    if (s.contains('jemur') || s.contains('dry')) return 4;
    if (s.contains('setrika') || s.contains('iron')) return 5;
    if (s.contains('packing')) return 6;
    if (s.contains('antar') || s.contains('delivery')) return 7;
    if (s.contains('selesai') || s.contains('completed')) return 8;
    return 1; // Default
  }

  void selectOrder(Map<String, dynamic> order) {
    _trackingTimer?.cancel();
    _trackingOrder = Map<String, dynamic>.from(order);
    // Pastikan field progress ada untuk UI
    _trackingOrder!['progress'] = getProgressFromStatus(_trackingOrder!['order_status'] ?? _trackingOrder!['status'] ?? '');
    notifyListeners();
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

  Future<void> fetchDraftOrders() async {
    try {
      final response = await _api.getDraftOrders();
      _draftOrders = response['data'] ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching drafts: $e");
    }
  }

  Future<bool> deleteDraft(String orderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.deleteDraftOrder(orderId);
      _draftOrders.removeWhere((o) => (o['order_number'] ?? o['id']) == orderId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error deleting draft: $e");
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
      // Gunakan order_number sebagai prioritas identitas pesanan
      _availableOrders.removeWhere((o) => (o['order_number'] ?? o['id']) == orderId);
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

  Future<bool> assignCourier(String orderId, dynamic courierId) async {
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

  Future<bool> submitReview(String orderId, int ratingMitra, int ratingCourier, String comment) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _api.submitReview(orderId, ratingMitra, ratingCourier, comment);
      await fetchOrders();
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Gagal menyimpan ulasan';
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

  Future<bool> uploadPOWImage(String orderId, XFile image, String step) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _api.uploadPOWImage(orderId, image, step);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Gagal upload foto POW';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("Error uploading POW: $e");
      _errorMessage = "Terjadi kesalahan saat upload foto";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadOrderAttachment(String orderId, dynamic file, String step, String customFileName) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.uploadOrderAttachment(orderId, file, step, customFileName);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error uploading attachment: $e");
      _errorMessage = "Gagal upload foto";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

final orderProvider = ChangeNotifierProvider<OrderProvider>((ref) => OrderProvider());
