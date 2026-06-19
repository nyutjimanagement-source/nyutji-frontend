import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import 'package:image_picker/image_picker.dart';

import 'cache_service.dart';

class ApiService {
  late Dio _dio;

  Dio get dio => _dio;

  static final ApiService _singleton = ApiService._internal();

  factory ApiService() {
    return _singleton;
  }

  ApiService._internal() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Limit concurrent connections & idle timeout 8s (lebih pendek dari keep-alive Apache ~10-15s)
    // agar koneksi tidak menjadi "stale" saat server sudah menutupnya
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.maxConnectionsPerHost = 3;
        client.idleTimeout = const Duration(seconds: 8); // Aman: lebih pendek dari timeout Apache
        return client;
      },
    );

    // 1. Auth Interceptor (Harus pertama agar request sudah memiliki token)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
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
      onResponse: (response, handler) {
        // Jika server mengembalikan HTML/String (misal: Captive Portal wifi) namun kita expect JSON
        if (response.data is String && response.requestOptions.responseType == ResponseType.json) {
          final rawString = response.data.toString().trim();
          if (rawString.isEmpty) {
            response.data = <String, dynamic>{};
            return handler.next(response);
          }

          try {
            // Coba parsing manual, jika berhasil, override data
            final parsed = jsonDecode(rawString);
            response.data = parsed;
            return handler.next(response);
          } catch (_) {
            // Gagal parsing. Coba bersihkan PHP warning/HTML prepended jika ada
            final extracted = _extractJson(rawString);
            if (extracted != null) {
              try {
                final parsed = jsonDecode(extracted);
                response.data = parsed;
                return handler.next(response);
              } catch (_) {}
            }
          }
          
          // Berikan pesan error lebih informatif berdasarkan konten
          String errorMsg = "Format respons server tidak valid (Mungkin karena Wifi Login/Captive Portal)";
          if (rawString.toLowerCase().contains("html") || rawString.startsWith("<!doctype") || rawString.startsWith("<html")) {
            errorMsg = "Server sedang mengalami gangguan atau pembatasan resource (Shared Hosting Error).";
          }
          
          return handler.reject(DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: errorMsg,
            error: errorMsg,
          ));
        }
        return handler.next(response);
      },
    ));

    // 2. Retry Interceptor — Tangani stale connection & error jaringan sementara
    // Hanya retry untuk error transport (bukan 4xx/5xx), maksimal 2x
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        final bool isTransientError =
            error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout;

        final int attemptNumber =
            (error.requestOptions.extra['retryCount'] as int?) ?? 0;

        if (isTransientError && attemptNumber < 2) {
          // Flush koneksi idle dari pool sebelum retry
          // close(force: false) = hanya tutup idle connections, tidak putus koneksi aktif
          // Ini menghilangkan koneksi "stale" yang sudah ditutup server tapi masih di pool kita
          if (error.type == DioExceptionType.connectionError) {
            try {
              _dio.httpClientAdapter.close(force: false);
              // Re-create adapter baru dengan pool kosong
              _dio.httpClientAdapter = IOHttpClientAdapter(
                createHttpClient: () {
                  final client = HttpClient();
                  client.maxConnectionsPerHost = 3;
                  client.idleTimeout = const Duration(seconds: 8);
                  return client;
                },
              );
            } catch (_) {}
          }

          // Jeda sebelum retry: 500ms untuk percobaan pertama, 1.5s untuk kedua
          final delay = attemptNumber == 0
              ? const Duration(milliseconds: 500)
              : const Duration(milliseconds: 1500);
          debugPrint('[Retry] Percobaan ${attemptNumber + 1}/2 setelah ${delay.inMilliseconds}ms — ${error.type.name}');
          await Future.delayed(delay);

          // Tandai percobaan ke-berapa ini
          final options = error.requestOptions;
          options.extra['retryCount'] = attemptNumber + 1;

          try {
            final response = await _dio.fetch(options);
            return handler.resolve(response);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        }

        return handler.next(error);
      },
    ));
  }

  void reset() {
    try {
      _dio.httpClientAdapter.close(force: true);
    } catch (_) {}
    _initDio();
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

  Future<Map<String, dynamic>> saveOrderNotes(String orderId, String notes) async {
    final response = await _dio.patch("/orders/$orderId/notes", data: {'notes': notes});
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
    final cacheKey = 'recommended_mitras_${cityName ?? "default"}';
    try {
      final response = await _dio.get("/mitras/recommended", queryParameters: {
        if (cityName != null && cityName.isNotEmpty) 'city_name': cityName
      });
      final data = response.data['data'] ?? [];
      await CacheService.set(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint("Gagal mengambil recommended mitras dari API, mencoba cache: $e");
      final cached = CacheService.get(cacheKey);
      if (cached != null && cached is List) {
        return cached;
      }
      rethrow;
    }
  }

  Future<List<dynamic>> searchMitras(String query) async {
    final response = await _dio.get("/mitras/search", queryParameters: {
      'q': query
    });
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getMitraItems(dynamic mitraId) async {
    final cacheKey = 'mitra_items_$mitraId';
    try {
      final response = await _dio.get("/mitras/$mitraId/items");
      final data = response.data['data'] ?? [];
      await CacheService.set(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint("Gagal mengambil mitra items dari API, mencoba cache: $e");
      final cached = CacheService.get(cacheKey);
      if (cached != null && cached is List) {
        return cached;
      }
      rethrow;
    }
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

  String? _extractJson(String text) {
    final startBrace = text.indexOf('{');
    final startBracket = text.indexOf('[');
    int start = -1;
    int end = -1;
    
    if (startBrace != -1 && (startBracket == -1 || startBrace < startBracket)) {
      start = startBrace;
      end = text.lastIndexOf('}');
    } else if (startBracket != -1) {
      start = startBracket;
      end = text.lastIndexOf(']');
    }
    
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return null;
  }
}
