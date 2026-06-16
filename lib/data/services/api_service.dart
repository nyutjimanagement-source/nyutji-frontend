import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/dio_offline_interceptor.dart';

class ApiService {
  late final Dio _dio;

  Dio get dio => _dio;

  static final ApiService _singleton = ApiService._internal();

  factory ApiService() {
    return _singleton;
  }

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    
    // Add Retry Mechanism (Khusus GET)
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        if (e.requestOptions.method.toUpperCase() == 'GET' && 
           (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout || 
            e.type == DioExceptionType.connectionError)) {
          
          int retryCount = e.requestOptions.extra['retry_count'] ?? 0;
          if (retryCount < 3) {
            e.requestOptions.extra['retry_count'] = retryCount + 1;
            try {
              await Future.delayed(Duration(seconds: retryCount + 1));
              final newDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
              final response = await newDio.fetch(e.requestOptions);
              return handler.resolve(response);
            } catch (retryError) {
              // Lanjut throw
            }
          }
        }
        return handler.next(e);
      }
    ));

    // Offline Interceptor untuk Queue Mechanism
    _dio.interceptors.add(DioOfflineInterceptor());

    // Add Interceptors for automatic Auth Token handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Jangan kirim token untuk rute login atau register!
        if (options.path == ApiConstants.login || options.path == "/register") {
          return handler.next(options);
        }

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Global error tracking / token expiry handling could go here
        return handler.next(e);
      }
    ));
  }
  
  // --- SYSTEM STATUS ---
  Future<Map<String, dynamic>> getSystemStatus() async {
    // Tarik status dari ROOT URL: https://api.nyutji.com/
    final response = await _dio.get(ApiConstants.rootUrl);
    return response.data;
  }

  // --- AUTH ENDPOINTS ---
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await _dio.post(ApiConstants.login, data: {
      'identifier': identifier, 
      'password': password
    });
    
    if (response.data is String) {
      throw Exception("Gangguan jaringan (kemungkinan koneksi terhalang Wi-Fi/paket data tidak stabil).");
    }
    
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    // data berisi: name, email, phone_number, password, role, districtName, cityName, mitraRefName
    final response = await _dio.post("/register", data: data);
    return response.data;
  }

  // --- APPROVAL ENDPOINTS ---
  Future<List<dynamic>> getPendingApprovals() async {
    final response = await _dio.get("/approvals");
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getMitraCouriers() async {
    final response = await _dio.get("/mitra/couriers");
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getPublicMitras() async {
    final response = await _dio.get("/public/mitras");
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getAllUsers() async {
    final response = await _dio.get("/admin/users");
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> bulkDeleteUsers(List<dynamic> identifiers) async {
    final response = await _dio.post("/admin/users/bulk-delete", data: {'identifiers': identifiers});
    return response.data;
  }

  Future<Map<String, dynamic>> resetUserPassword(String targetIdentifier, String newPassword) async {
    final response = await _dio.post("/admin/users/reset-password", data: {
      'target_identifier': targetIdentifier,
      'new_password': newPassword
    });
    return response.data;
  }

  Future<Map<String, dynamic>> processApproval(dynamic targetIdentifier, String action) async {
    // action: 'APPROVED' or 'REJECTED'
    final response = await _dio.post("/approvals/process", data: {
      'targetIdentifier': targetIdentifier, // Gunakan identifier, bukan ID integer
      'action': action
    });
    return response.data;
  }

  // --- ORDER ENDPOINTS ---
  Future<List<dynamic>> getOrders() async {
    final response = await _dio.get("/orders");
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data.containsKey('data')) return data['data'] ?? [];
    return [];
  }

  Future<List<dynamic>> getAdminOrders() async {
    final response = await _dio.get("/admin/orders");
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data.containsKey('data')) return data['data'] ?? [];
    return [];
  }

  // GET order tersedia di kecamatan KL (untuk marketplace kurir)
  Future<List<dynamic>> getAvailableOrders(String districtName) async {
    final response = await _dio.get("/orders/available", queryParameters: {
      'district_name': districtName,
    });
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getRevenueSplits() async {
    final response = await _dio.get("/admin/revenue-splits");
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data.containsKey('data')) return data['data'] ?? [];
    return [];
  }

  Future<Map<String, dynamic>> getRevenueSplitSummary() async {
    final response = await _dio.get("/admin/revenue-splits/summary");
    final data = response.data;
    return (data is Map && data.containsKey('data')) ? data['data'] : (data ?? {});
  }

  Future<Map<String, dynamic>> getPriceQuote(double distance, bool isFastTrack, double lat, double lng, String orderType) async {
    final response = await _dio.post("/orders/quote", data: {
      'distance': distance,
      'is_fast_track': isFastTrack,
      'lat': lat,
      'lng': lng,
      'orderType': orderType
    });
    return response.data;
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    final response = await _dio.post("/courier/pickup", data: {'orderId': orderId});
    return response.data;
  }

  Future<Map<String, dynamic>> assignCourier(String orderId, dynamic courierId) async {
    final response = await _dio.post("/orders/assign-courier", data: {
      'orderId': orderId,
      'courier_id': courierId, // Gunakan identifier
      'courierId': courierId
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String newStatus) async {
    // Khusus Kurir/Mitra
    final response = await _dio.patch("/orders/$orderId/status", data: {'status': newStatus});
    return response.data;
  }

  Future<Map<String, dynamic>> uploadPOWImage(String orderNumber, XFile image, String step) async {
    final formData = FormData.fromMap({
      'step': step,
      'pow': await MultipartFile.fromFile(image.path, filename: image.name),
    });
    
    final response = await _dio.post("/orders/$orderNumber/pow", data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> submitReview(String orderId, int ratingMitra, int ratingCourier, String comment) async {
    final response = await _dio.post("/orders/$orderId/review", data: {
      'ratingMitra': ratingMitra,
      'ratingCourier': ratingCourier,
      'comment': comment
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final response = await _dio.post("/orders", data: orderData);
    return response.data;
  }

  Future<Map<String, dynamic>> getDraftOrders() async {
    final response = await _dio.get("/orders/drafts");
    return response.data;
  }

  Future<Map<String, dynamic>> deleteDraftOrder(String orderId) async {
    final response = await _dio.delete("/orders/drafts/$orderId");
    return response.data;
  }

  Future<Map<String, dynamic>> getCourierPricing() async {
    final response = await _dio.get("/admin/courier-pricing");
    return response.data;
  }

  Future<Map<String, dynamic>> updateCourierPricing(List<Map<String, dynamic>> pricings) async {
    final response = await _dio.post("/admin/courier-pricing", data: {'pricings': pricings});
    return response.data;
  }

  Future<Map<String, dynamic>> deleteCourierPricing(dynamic id) async {
    final response = await _dio.delete("/admin/courier-pricing/$id");
    return response.data;
  }

  // --- WALLET & MITRA ENDPOINTS ---
  Future<Map<String, dynamic>> getWalletData() async {
    final response = await _dio.get("/wallet/balance");
    // Asumsi backend mereturn { balance: 250000, logs: [...] }
    return response.data;
  }

  Future<Map<String, dynamic>> requestTopupMember(double amount) async {
    final response = await _dio.post("/wallet/topup", data: {'amount': amount});
    return response.data;
  }

  Future<Map<String, dynamic>> updateWalletPin(String pin) async {
    final response = await _dio.post("/wallet/pin", data: {'pin': pin});
    return response.data;
  }


  Future<Map<String, dynamic>> forceTopup(double amount, {String? targetIdentifier}) async {
    final response = await _dio.post("/wallet/force-topup", data: {
      'amount': amount,
      'targetIdentifier': targetIdentifier, // Disamakan dengan backend
    });
    return response.data;
  }

  Future<Map<String, dynamic>> requestWithdraw(double amount, String pin) async {
    final response = await _dio.post(ApiConstants.withdraw, data: {'amount': amount, 'pin': pin});
    return response.data;
  }

  // --- OPERATIONAL ISSUES (MITRA & ADMIN) ---
  Future<Map<String, dynamic>> reportIssue(String issueType, String description, String priority) async {
    final response = await _dio.post("/issues/report", data: {
      'issueType': issueType,
      'description': description,
      'priority': priority,
    });
    return response.data;
  }

  Future<List<dynamic>> getIssues() async {
    final response = await _dio.get("/issues");
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> updateIssueStatus(int issueId, String newStatus) async {
    final response = await _dio.patch("/issues/$issueId/status", data: {'status': newStatus});
    return response.data;
  }

  // --- SOCIAL SENTIMENTS (ADMIN) ---
  Future<Map<String, dynamic>> getSocialSentiments() async {
    final response = await _dio.get("/sentiments");
    return response.data; // returns { status: 'success', summary: {...}, data: [...] }
  }

  // --- PROFILE ENDPOINTS ---
  Future<Map<String, dynamic>> updateLocation(Map<String, dynamic> data) async {
    final response = await _dio.put("/users/location", data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put("/users/profile", data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(dynamic fileSource) async {
    // fileSource bisa berupa String (path) atau XFile
    FormData formData;
    
    if (fileSource is String) {
      // Legacy support for Mobile path
      String fileName = fileSource.split('/').last;
      formData = FormData.fromMap({
        "photo": await MultipartFile.fromFile(fileSource, filename: fileName),
      });
    } else {
      // Modern support for XFile (Works on Web & Mobile)
      final xFile = fileSource;
      final bytes = await xFile.readAsBytes();
      formData = FormData.fromMap({
        "photo": MultipartFile.fromBytes(bytes, filename: xFile.name),
      });
    }

    final response = await _dio.post("/users/profile-photo", data: formData);
    return response.data;
  }

  // --- LIVE MITRA & PRICING ENDPOINTS ---
  Future<List<dynamic>> getRecommendedMitras({String? cityName}) async {
    // Menarik daftar mitra terdekat/rekomendasi dari DB
    final response = await _dio.get("/mitras/recommended", queryParameters: {
      if (cityName != null && cityName.isNotEmpty) 'city_name': cityName
    });
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> searchMitras(String query) async {
    final response = await _dio.get("/mitras/search", queryParameters: {
      'q': query
    });
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getMitraItems(dynamic mitraId) async {
    // Menarik daftar harga asli mitra tertentu dari DB
    final response = await _dio.get("/mitras/$mitraId/items");
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> updateMitraPricing(dynamic mitraId, List<Map<String, dynamic>> items) async {
    // Mengirim pembaruan harga ke backend (Sinkronisasi Database SQL)
    try {
      final response = await _dio.post("/mitras/items", data: {
        'mitra_id': mitraId,
        'items': items
      });
      return response.data;
    } catch (e) {
      debugPrint("API Error Detail: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadOrderAttachment(String orderId, dynamic fileSource, String step, String customFileName) async {
    FormData formData;
    
    if (fileSource is File) {
      formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(fileSource.path, filename: customFileName),
        "orderId": orderId,
        "step": step
      });
    } else {
      // XFile support
      final xFile = fileSource;
      final bytes = await xFile.readAsBytes();
      formData = FormData.fromMap({
        "image": MultipartFile.fromBytes(bytes, filename: customFileName),
        "orderId": orderId,
        "step": step
      });
    }

    final response = await _dio.post("/orders/$orderId/proof", data: formData);
    return response.data;
  }

  // --- RESCHEDULER ENDPOINTS ---
  Future<Map<String, dynamic>> createRescheduler(Map<String, dynamic> data) async {
    final response = await _dio.post("/reschedulers", data: data);
    return response.data;
  }

  Future<List<dynamic>> getCustomerSchedules() async {
    final response = await _dio.get("/reschedulers");
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> updateRescheduler(String id, Map<String, dynamic> data) async {
    final response = await _dio.put("/reschedulers/$id", data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteRescheduler(String id) async {
    final response = await _dio.delete("/reschedulers/$id");
    return response.data;
  }
}
