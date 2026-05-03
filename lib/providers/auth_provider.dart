import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../core/utils/formatters.dart';
import '../data/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _role;
  bool _isLoading = false;
  String _lang = 'id'; // Default Language
  Map<String, dynamic>? _user;
  List<dynamic> _pendingApprovals = [];
  List<dynamic> _allUsers = [];
  String? _lastErrorMessage;

  Map<String, dynamic>? _homeAddress;
  List<dynamic> _addressHistory = [];
  List<dynamic> _couriers = [];
  List<dynamic> _mitras = [];
  String? _temporaryLocalPhoto;
  dynamic _temporaryWebBytes; // Simpan Uint8List untuk Web preview

  bool get isLoading => _isLoading;
  String? get temporaryLocalPhoto => _temporaryLocalPhoto;
  dynamic get temporaryWebBytes => _temporaryWebBytes;
  String? get role => _role;
  String? get token => _token;
  String get lang => _lang;
  Map<String, dynamic>? get user => _user;
  List<dynamic> get pendingApprovals => _pendingApprovals;
  List<dynamic> get allUsers => _allUsers;
  List<dynamic> get couriers => _couriers;
  List<dynamic> get mitras => _mitras;
  Map<String, dynamic>? get homeAddress => _homeAddress;
  List<dynamic> get addressHistory => _addressHistory;
  String? get lastErrorMessage => _lastErrorMessage;

  Future<void> fetchCouriers() async {
    try {
      if (_role == 'ML') {
        _couriers = await ApiService().getMitraCouriers();
      } else {
        final all = await ApiService().getAllUsers();
        _couriers = all.where((u) => u['role']?.toString().toUpperCase() == 'KL').toList();
      }
      debugPrint("Fetched ${_couriers.length} couriers from database");
      notifyListeners();
    } catch (e) {
      debugPrint("Gagal fetch kurir: $e");
    }
  }

  Future<void> fetchMitras() async {
    try {
      final all = await ApiService().getPublicMitras();
      _mitras = all;
      debugPrint("Fetched ${_mitras.length} mitras from database");
      notifyListeners();
    } catch (e) {
      debugPrint("Gagal fetch mitra: $e");
    }
  }

  Future<void> saveHomeAddress(Map<String, dynamic> addr) async {
    _homeAddress = addr;
    
    // 1. Simpan di Database PostgreSQL backend
    try {
      final res = await ApiService().updateLocation(addr);

      if (res['status'] == 'success' || res['message'] != null) {
        // Update global user state with address
        if (_user != null) {
          final newData = res['data'] ?? {};
          _user!['address'] = newData['address'] ?? addr['address'];
          _user!['address_detail'] = newData['detail'] ?? addr['detail'];
          _user!['lat'] = newData['lat'] ?? addr['lat'];
          _user!['lng'] = newData['lng'] ?? addr['lng'];
          _user!['district_name'] = newData['district_name'] ?? addr['district'];
          _user!['city_name'] = newData['city_name'] ?? addr['city'];

          // HANDLE IDENTITY CHANGE (Baptisan PL)
          if (res['new_token'] != null) {
            _token = res['new_token'];
          }
          if (res['new_identifier'] != null) {
            _user!['identifier'] = res['new_identifier'];
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(_user));
          if (res['new_token'] != null) {
            await prefs.setString('token', _token!);
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal sinkronisasi alamat ke server: $e");
    }

    // 2. Tetap sinkronkan ke SharedPreferences Lokal HP untuk Fast Load
    final prefs = await SharedPreferences.getInstance();
    final key = _user?['identifier'] ?? _user?['email'] ?? 'unknown';
    await prefs.setString('home_address_$key', jsonEncode(addr));
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
      final key = _user?['identifier'] ?? _user?['email'];
      final homeAddrStr = prefs.getString('home_address_$key');
      if (homeAddrStr != null) {
        _homeAddress = jsonDecode(homeAddrStr);
      } else if (_user != null && _user!['address'] != null) {
        // RESTORE DARI DATABASE: Jika di HP baru alamat kosong, ambil dari SQL
        _homeAddress = {
          'address': _user!['address'],
          'detail': _user!['address_detail'],
          'lat': _user!['lat'],
          'lng': _user!['lng'],
          'district': _user!['district_name'],
          'city': _user!['city_name'],
        };
      }
      
      final historyStr = prefs.getString('address_history_$key');
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
      _temporaryWebBytes = null;
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
          final key = _user?['identifier'] ?? _user?['email'];
          final homeAddrStr = prefs.getString('home_address_$key');
          if (homeAddrStr != null) {
            _homeAddress = jsonDecode(homeAddrStr);
          } else if (_user != null && _user!['address'] != null) {
            // RESTORE DARI DATABASE
            _homeAddress = {
              'address': _user!['address'],
              'detail': _user!['address_detail'],
              'lat': _user!['lat'],
              'lng': _user!['lng'],
              'district': _user!['district_name'],
              'city': _user!['city_name'],
            };
          } else {
            _homeAddress = null;
          }
          
          final historyStr = prefs.getString('address_history_$key');
          if (historyStr != null) {
            _addressHistory = jsonDecode(historyStr);
          } else {
            _addressHistory = [];
          }

          // LOAD LOCAL PHOTO PATH PERSISTENCE AFTER LOGIN
          _temporaryLocalPhoto = prefs.getString('local_photo_$email');
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      if (e is DioException) {
        _lastErrorMessage = e.response?.data?['message']?.toString() ?? e.message;
      } else {
        _lastErrorMessage = e.toString();
      }
      notifyListeners();
      debugPrint("Login Error: $e");
    }
    return false;
  }

  // Versi trial: Mengirim data Kecamatan manual dan Referensi Mitra
  Future<String?> register(Map<String, dynamic> regData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().register(regData);
      
      if (response['message'] != null) {
        _isLoading = false; 
        notifyListeners();
        return null; // Success
      }
    } on DioException catch (e) {
      debugPrint("Register Error: ${e.response?.data}");
      _isLoading = false;
      notifyListeners();
      return e.response?.data?['error'] ?? e.response?.data?['message'] ?? 'Gagal menghubungi server';
    } catch (e) {
      debugPrint("Register Error: $e");
      _isLoading = false;
      notifyListeners();
      return 'Terjadi kesalahan internal. Coba lagi.';
    }
    return 'Terjadi kesalahan tidak terduga';
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
  Future<bool> processUserApproval(dynamic targetIdentifier, String action) async {
    try {
      final res = await ApiService().processApproval(targetIdentifier, action);
      return res['message'] != null;
    } catch (e) {
      debugPrint("Process Approval Error: $e");
      return false;
    }
  }

  // Ambil SEMUA daftar user (Khusus Admin)
  Future<List<dynamic>> fetchAllUsers() async {
    try {
      final data = await ApiService().getAllUsers();
      _allUsers = data;
      notifyListeners();
      return data;
    } catch (e) {
      debugPrint("Fetch All Users Error: $e");
      return [];
    }
  }

  Future<bool> approveUser(dynamic identifier, String action) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService().processApproval(identifier, action);
      if (res['status'] == 'success') {
        // Hapus dari list pending lokal
        _pendingApprovals.removeWhere((u) => u['identifier'] == identifier);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Approve Error: $e");
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> bulkDeleteUsers(List<dynamic> identifiers) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final res = await ApiService().bulkDeleteUsers(identifiers);
      if (res['status'] == 'success') {
        // Hapus dari list lokal agar UI update otomatis menggunakan identifier
        _allUsers.removeWhere((u) => identifiers.contains(u['identifier']));
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Bulk Delete Error: $e");
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Upload & Update Foto Profil
  Future<bool> updateProfilePhoto(dynamic fileSource) async {
    // fileSource bisa berupa String path (Mobile) atau XFile (Web/Mobile)
    if (fileSource is String) {
      _temporaryLocalPhoto = fileSource;
    } else {
      // Asumsi XFile
      _temporaryLocalPhoto = fileSource.path;
      try {
        _temporaryWebBytes = await fileSource.readAsBytes();
      } catch (e) {
        debugPrint("Gagal baca bytes untuk preview: $e");
      }
    }
    
    notifyListeners();

    try {
      final res = await ApiService().uploadProfilePhoto(fileSource);
      if (res['photo_url'] != null) {
        // Update data user lokal
        if (_user != null) {
          _user!['profile_photo'] = res['photo_url'];
          
          final prefs = await SharedPreferences.getInstance();
          final email = _user!['email'] ?? "unknown";
          await prefs.setString('cached_photo_$email', res['photo_url']);
          
          if (fileSource is String) {
             await prefs.setString('local_photo_$email', fileSource);
          }
          
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

  // UPDATE LOKASI (UMUM UNTUK PL/ML/KL)
  Future<bool> updateLocation(Map<String, dynamic> locData) async {
    try {
      // 1. Update ke Backend
      final res = await ApiService().updateLocation({
        'address': locData['address'],
        'district_name': locData['district_name'],
        'district_code': Formatters.generateDistrictCode(locData['district_name']),
        'city_name': locData['city_name'],
        'lat': locData['lat'],
        'lng': locData['lng'],
      });

      if (res['status'] == 'success' || res['message'] != null) {
        // 2. Update Local State _user
        if (_user != null) {
          final newData = res['data'] ?? {};
          _user!['address'] = newData['address'] ?? locData['address'];
          _user!['district_name'] = newData['district_name'] ?? locData['district_name'];
          _user!['district_code'] = newData['district_code'] ?? Formatters.generateDistrictCode(locData['district_name']);
          _user!['city_name'] = newData['city_name'] ?? locData['city_name'];
          _user!['lat'] = newData['lat'] ?? locData['lat'];
          _user!['lng'] = newData['lng'] ?? locData['lng'];
          
          // HANDLE IDENTITY CHANGE (Baptisan PL)
          if (res['new_token'] != null) {
            _token = res['new_token'];
          }
          if (res['new_identifier'] != null) {
            _user!['identifier'] = res['new_identifier'];
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(_user));
          if (res['new_token'] != null) {
            await prefs.setString('token', _token!);
          }
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Gagal update lokasi di AuthProvider: $e");
    }
    return false;
  }
  Future<bool> forceTopup(double amount, String targetIdentifier) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService().forceTopup(amount, targetIdentifier: targetIdentifier);
      _isLoading = false;
      notifyListeners();
      return res['message'] != null;
    } catch (e) {
      debugPrint("Force Topup Error: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
