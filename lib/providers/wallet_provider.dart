import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/api_service.dart';
import '../data/services/cache_service.dart';
import 'package:dio/dio.dart';

class WalletProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _balance = 0.0;
  double get balance => _balance;

  List<dynamic> _mutasiList = [];
  List<dynamic> get mutasiList => _mutasiList;

  List<dynamic> _withdrawalsList = [];
  List<dynamic> get withdrawalsList => _withdrawalsList;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;

  final ApiService _api = ApiService();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  DateTime? _lastWalletFetch;

  Future<void> fetchWallet({bool force = false}) async {
    // Throttling: Jika tidak dipaksa (force), batasi request ke server maksimal tiap 15 detik
    if (!force && _lastWalletFetch != null && DateTime.now().difference(_lastWalletFetch!) < const Duration(seconds: 15)) {
      debugPrint("[fetchWallet] Throttled (kurang dari 15 detik).");
      return;
    }

    // 1. Coba baca dari cache dulu agar UI ter-render instan
    final cachedData = CacheService.get('nyutji_wallet');
    if (cachedData != null && cachedData is Map) {
      _balance = double.parse(cachedData['balance']?.toString() ?? '0');
      _mutasiList = cachedData['logs'] ?? [];
      _withdrawalsList = cachedData['withdrawals'] ?? [];
      _isLoading = false;
      _safeNotifyListeners();
    } else {
      _isLoading = true;
      _errorMessage = null;
      _safeNotifyListeners();
    }

    _lastWalletFetch = DateTime.now();

    try {
      final data = await _api.getWalletData();
      debugPrint('[fetchWallet] data: $data');
      
      // Simpan hasil sukses ke cache
      await CacheService.set('nyutji_wallet', data);
      
      _balance = double.parse(data['balance']?.toString() ?? '0');
      _mutasiList = data['logs'] ?? [];
      _withdrawalsList = data['withdrawals'] ?? [];
    } catch (e) {
      debugPrint('[fetchWallet] ERROR: $e');
      _errorMessage = 'Gagal memuat saldo dompet: $e';
      // Jika cache kosong baru di-reset ke default
      if (_mutasiList.isEmpty && _withdrawalsList.isEmpty) {
        _balance = 0.0;
        _mutasiList = [];
        _withdrawalsList = [];
      }
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> requestTopup(double amount) async {
    _isLoading = true;
    _safeNotifyListeners();
    try {
      await _api.requestTopupMember(amount);
      await fetchWallet();
      return true;
    } catch (e) {
      _errorMessage = "Gagal memproses Top Up";
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> forceTopup(double amount) async {
    _isLoading = true;
    _safeNotifyListeners();
    try {
      await _api.forceTopup(amount);
      await fetchWallet();
      return true;
    } catch (e) {
      _errorMessage = "Gagal memproses Force Top Up";
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> requestWithdraw(double amount, String pin) async {
    if (amount > _balance) {
      _errorMessage = "Saldo tidak mencukupi";
      _safeNotifyListeners();
      return false;
    }
    
    _isLoading = true;
    _safeNotifyListeners();
    try {
      await _api.requestWithdraw(amount, pin);
      await fetchWallet();
      return true;
    } on DioException catch (e) {
      _errorMessage = (e.response?.data is Map ? (e.response?.data is Map ? e.response?.data['message'] : null) : null) ?? "Gagal memproses Penarikan";
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Gagal memproses Penarikan";
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> updatePin(String pin) async {
    _isLoading = true;
    _safeNotifyListeners();
    try {
      await _api.updateWalletPin(pin);
      return true;
    } catch (e) {
      _errorMessage = "Gagal memperbarui PIN";
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }
}

final walletProvider = ChangeNotifierProvider<WalletProvider>((ref) => WalletProvider());
