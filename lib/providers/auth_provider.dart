import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _role;
  bool _isLoading = false;
  String _lang = 'id'; // Default Language
  Map<String, dynamic>? _user;
  List<dynamic> _pendingApprovals = [];

  String? _temporaryLocalPhoto; // Memori agar foto tidak hilang saat pindah screen
  
  bool get isLoading => _isLoading;
  String? get temporaryLocalPhoto => _temporaryLocalPhoto;
  String? get role => _role;
  String? get token => _token;
  String get lang => _lang;
  Map<String, dynamic>? get user => _user;
  List<dynamic> get pendingApprovals => _pendingApprovals;

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
    await prefs.clear();
    _token = null;
    _role = null;
    _user = null;
    _temporaryLocalPhoto = null; // BERSIHKAN FOTO LAMA!
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
          if (realIdentifier.contains('kl')) {
            _role = 'KL';
          } else if (realIdentifier.contains('ml')) _role = 'ML';
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
      final data = await ApiService().getPendingApprovals();
      _pendingApprovals = data;
      notifyListeners();
      return data;
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

  // Upload & Update Foto Profil
  Future<bool> updateProfilePhoto(String filePath) async {
    _temporaryLocalPhoto = filePath; // Simpan di memori pusat segera!
    notifyListeners();

    try {
      final res = await ApiService().uploadProfilePhoto(filePath);
      if (res['photo_url'] != null) {
        // Update data user lokal
        if (_user != null) {
          _user!['profile_photo'] = res['photo_url'];
          // _temporaryLocalPhoto = null; <-- Jangan dihapus dulu agar tidak flicker!
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint("Update Profile Photo Error: $e");
    }
    return false;
  }
}
