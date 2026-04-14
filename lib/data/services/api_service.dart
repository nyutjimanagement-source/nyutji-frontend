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

  Future<Map<String, dynamic>> register(String name, String email, String phone, String password, String role) async {
    final response = await _dio.post("/register", data: {
      'name': name,
      'email': email,
      'phone_number': phone,
      'password': password,
      'role': role
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
}
