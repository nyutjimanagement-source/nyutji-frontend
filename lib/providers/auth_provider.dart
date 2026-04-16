import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _role;
  bool _isLoading = false;
  String _lang = 'id'; // Default Language
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get role => _role;
  String? get token => _token;
  String get lang => _lang;
  Map<String, dynamic>? get user => _user;

  void setLanguage(String newLang) {
    _lang = newLang;
    notifyListeners();
  }

  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    
    if (_token != null && _role != null) {
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Hapus seluruh memori tanpa sisa (Fokus fix registrasi gagal)
    await prefs.clear();
    _token = null;
    _role = null;
    _user = null;
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();

    // AUTO-INFER IDENTIFIER FOR FAST SOFT LAUNCH LOGIN
    // Jika email kosong, anggap password adalah ID (misal: PL0001)
    String realIdentifier = identifier.trim();
    if (realIdentifier.isEmpty) {
      realIdentifier = "${password.trim().toLowerCase()}@nyutji.com";
    }

    try {
      final response = await ApiService().login(realIdentifier, password);

      if (response['token'] != null) {
        _token = response['token'];
        
        // BACKUP LOGIC: Jika backend belum diredeploy (role null), infer dari identifier
        if (response['role'] != null) {
          _role = response['role'];
        } else {
          // Inferensi dari ID (PL/KL/ML) seandainya server remote belum update
          if (realIdentifier.contains('kl')) _role = 'KL';
          else if (realIdentifier.contains('ml')) _role = 'ML';
          else if (realIdentifier.contains('ad')) _role = 'AD';
          else _role = 'PL';
        }
        
        _user = response['user']; 
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('role', _role!);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Login Error: $e");
    }
    return false;
  }

  // Versi trial: Mengirim data Kecamatan manual dan Referensi Mitra
  Future<bool> register(Map<String, dynamic> regData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().register(regData);
      
      if (response['message'] != null) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Register Error: $e");
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Khusus Admin & Mitra: Ambil antrean approval
  Future<List<dynamic>> fetchPendingApprovals() async {
    try {
      return await ApiService().getPendingApprovals();
    } catch (e) {
      debugPrint("Fetch Approvals Error: $e");
      return [];
    }
  }

  // Proses Approve/Reject
  Future<bool> processUserApproval(int targetId, String action) async {
    try {
      final res = await ApiService().processApproval(targetId, action);
      return res['message'] != null;
    } catch (e) {
      debugPrint("Process Approval Error: $e");
      return false;
    }
  }
}
