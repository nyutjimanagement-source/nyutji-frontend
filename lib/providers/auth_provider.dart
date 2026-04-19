import 'dart:convert';
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

  Map<String, dynamic>? _homeAddress;
  List<dynamic> _addressHistory = [];
  String? _temporaryLocalPhoto;

  bool get isLoading => _isLoading;
  String? get temporaryLocalPhoto => _temporaryLocalPhoto;
  String? get role => _role;
  String? get token => _token;
  String get lang => _lang;
  Map<String, dynamic>? get user => _user;
  List<dynamic> get pendingApprovals => _pendingApprovals;
  Map<String, dynamic>? get homeAddress => _homeAddress;
  List<dynamic> get addressHistory => _addressHistory;

  Future<void> saveHomeAddress(Map<String, dynamic> addr) async {
    _homeAddress = addr;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('home_address_${_user?['email']}', jsonEncode(addr));
    notifyListeners();
  }

  Future<void> addToAddressHistory(Map<String, dynamic> addr) async {
    // Hindari duplikasi yang sama persis
    if (_addressHistory.any((element) => element['address'] == addr['address'])) return;
    
    _addressHistory.insert(0, addr);
    if (_addressHistory.length > 5) _addressHistory = _addressHistory.sublist(0, 5); // Limit 5 history
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('address_history_${_user?['email']}', jsonEncode(_addressHistory));
    notifyListeners();
  }

  void setLanguage(String newLang) {
    _lang = newLang;
    notifyListeners();
  }

  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    
    if (_token != null && _role != null) {
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        try {
          _user = jsonDecode(userDataStr);
        } catch (e) {
          debugPrint("Error decoding user data: $e");
        }
      }
      // Load Addresses
      final homeAddrStr = prefs.getString('home_address_${_user?['email']}');
      if (homeAddrStr != null) _homeAddress = jsonDecode(homeAddrStr);
      
      final historyStr = prefs.getString('address_history_${_user?['email']}');
      if (historyStr != null) _addressHistory = jsonDecode(historyStr);
      
      // LOAD LOCAL PHOTO PATH PERSISTENCE
      if (_user?['email'] != null) {
        _temporaryLocalPhoto = prefs.getString('local_photo_${_user!['email']}');
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // JANGAN GUNAKAN prefs.clear() karena akan menghapus cache foto lokal!
    // Hapus hanya data yang berkaitan dengan sesi aktif
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('user_data');
    
    _token = null;
    _role = null;
    _homeAddress = null;
    _addressHistory = [];
    notifyListeners();

    // Hapus data detail setelah jeda singkat agar navigasi smooth
    Future.delayed(const Duration(milliseconds: 500), () {
      _user = null;
      _temporaryLocalPhoto = null;
      notifyListeners();
    });
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();

    String realIdentifier = identifier.trim();
    if (realIdentifier.isEmpty) {
      realIdentifier = "${password.trim().toLowerCase()}@nyutji.com";
    }

    try {
      final response = await ApiService().login(realIdentifier, password);

      if (response['token'] != null) {
        _token = response['token'];
        _role = response['role'] ?? 'PL';
        _user = response['user']; 
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('role', _role!);
        
        // PERSISTENCE FIX: Jika server tidak punya foto, cek cache lokal berdasarkan email
        if (_user != null) {
          final email = _user!['email'] ?? realIdentifier;
          if (_user!['profile_photo'] == null || _user!['profile_photo'].toString().isEmpty) {
            String? cached = prefs.getString('cached_photo_$email');
            if (cached != null) _user!['profile_photo'] = cached;
          } else {
            // Jika server punya foto, update cache lokal
            await prefs.setString('cached_photo_$email', _user!['profile_photo'].toString());
          }
          await prefs.setString('user_data', jsonEncode(_user));

          // Load Addresses after login
          final homeAddrStr = prefs.getString('home_address_${_user?['email']}');
          if (homeAddrStr != null) _homeAddress = jsonDecode(homeAddrStr); else _homeAddress = null;
          
          final historyStr = prefs.getString('address_history_${_user?['email']}');
          if (historyStr != null) _addressHistory = jsonDecode(historyStr); else _addressHistory = [];

          // LOAD LOCAL PHOTO PATH PERSISTENCE AFTER LOGIN
          _temporaryLocalPhoto = prefs.getString('local_photo_$email');
        }

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
          
          final prefs = await SharedPreferences.getInstance();
          final email = _user!['email'] ?? "unknown";
          await prefs.setString('cached_photo_$email', res['photo_url']);
          await prefs.setString('local_photo_$email', filePath); // SIMPAN PERMANEN DI HP
          await prefs.setString('user_data', jsonEncode(_user));
          
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
