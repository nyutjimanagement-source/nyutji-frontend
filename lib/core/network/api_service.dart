import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import 'dio_offline_interceptor.dart';

class ApiService {
  final Dio dio;

  ApiService() : dio = Dio() {
    dio.options.baseUrl = ApiConstants.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(seconds: 60);
    
    // Interceptor untuk Log (Membantu Debugging)
    dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
    
    // Interceptor untuk Retry Mechanism (Khusus GET)
    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        if (e.requestOptions.method.toUpperCase() == 'GET' && 
           (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout || 
            e.type == DioExceptionType.connectionError)) {
          
          int retryCount = e.requestOptions.extra['retry_count'] ?? 0;
          if (retryCount < 3) {
            e.requestOptions.extra['retry_count'] = retryCount + 1;
            try {
              // Exponential backoff: 1s, 2s, 3s
              await Future.delayed(Duration(seconds: retryCount + 1));
              
              // Resolve dependencies to retry
              final newDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
              final response = await newDio.fetch(e.requestOptions);
              return handler.resolve(response);
            } catch (retryError) {
              // Tetap lanjut throw jika gagal
            }
          }
        }
        return handler.next(e);
      }
    ));

    // Offline Interceptor untuk Queue Mechanism
    dio.interceptors.add(const DioOfflineInterceptor());
  }
}

// Global Provider untuk digunakan di seluruh aplikasi
final apiServiceProvider = Provider<Dio>((ref) {
  return ApiService().dio;
});
