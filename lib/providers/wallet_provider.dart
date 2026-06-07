import 'package:flutter/material.dart';
import '../data/services/api_service.dart';
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

  final ApiService _api = ApiService();

  Future<void> fetchWallet() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.getWalletData();
      debugPrint('[fetchWallet] data: $data');
      _balance = double.parse(data['balance'].toString());
      _mutasiList = data['logs'] ?? [];
      _withdrawalsList = data['withdrawals'] ?? [];
    } catch (e) {
      debugPrint('[fetchWallet] ERROR: $e');
      _errorMessage = 'Gagal memuat saldo dompet: $e';
      _balance = 0.0;
      _mutasiList = [];
      _withdrawalsList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestTopup(double amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.requestTopupMember(amount);
      await fetchWallet();
      return true;
    } catch (e) {
      _errorMessage = "Gagal memproses Top Up";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forceTopup(double amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.forceTopup(amount);
      await fetchWallet();
      return true;
    } catch (e) {
      _errorMessage = "Gagal memproses Force Top Up";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestWithdraw(double amount, String pin) async {
    if (amount > _balance) {
      _errorMessage = "Saldo tidak mencukupi";
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    notifyListeners();
    try {
      await _api.requestWithdraw(amount, pin);
      await fetchWallet();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? "Gagal memproses Penarikan";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Gagal memproses Penarikan";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePin(String pin) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.updateWalletPin(pin);
      return true;
    } catch (e) {
      _errorMessage = "Gagal memperbarui PIN";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
