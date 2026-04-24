import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  late final Dio _dio;

  static final ApiService _singleton = ApiService._internal();

  factory ApiService() {
    return _singleton;
  }

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
    
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

  // --- AUTH ENDPOINTS ---
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await _dio.post(ApiConstants.login, data: {
      'identifier': identifier, 
      'password': password
    });
    return response.data;
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

  Future<List<dynamic>> getAllUsers() async {
    final response = await _dio.get("/admin/users");
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> bulkDeleteUsers(List<int> userIds) async {
    final response = await _dio.delete("/admin/users/bulk", data: {'userIds': userIds});
    return response.data;
  }

  Future<Map<String, dynamic>> processApproval(int targetId, String action) async {
    // action: 'APPROVED' or 'REJECTED'
    final response = await _dio.post("/approvals/process", data: {
      'targetId': targetId,
      'action': action
    });
    return response.data;
  }

  // --- ORDER ENDPOINTS ---
  Future<List<dynamic>> getOrders() async {
    // Akan otomatis menyertakan token dari interceptor
    // Endpoint ini harusnya return list array di backend, bisa di sesuaikan.
    final response = await _dio.get("/orders");
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final response = await _dio.post("/orders", data: orderData);
    return response.data;
  }
  
  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String newStatus) async {
    // Khusus Kurir/Mitra
    final response = await _dio.patch("/orders/$orderId/status", data: {'status': newStatus});
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

  Future<Map<String, dynamic>> requestWithdraw(double amount) async {
    final response = await _dio.post(ApiConstants.withdraw, data: {'amount': amount});
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
  Future<List<dynamic>> getRecommendedMitras() async {
    // Menarik daftar mitra terdekat/rekomendasi dari DB
    final response = await _dio.get("/mitras/recommended");
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getMitraItems(int mitraId) async {
    // Menarik daftar harga asli mitra tertentu dari DB
    final response = await _dio.get("/mitras/$mitraId/items");
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> updateMitraPricing(int mitraId, List<Map<String, dynamic>> items) async {
    // Mengirim pembaruan harga ke backend
    // Menggunakan POST /mitras/items sesuai rute yang didaftarkan di backend api.js
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
}
