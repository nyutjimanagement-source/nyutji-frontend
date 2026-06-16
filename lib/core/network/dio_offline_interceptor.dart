import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_queue_db.dart';

class DioOfflineInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    
    // Periksa apakah list connectivityResult mengandung 'none'
    final isOffline = connectivityResult.contains(ConnectivityResult.none) || connectivityResult.isEmpty;
    
    // Rute yang dilarang diantrekan saat offline
    final skipQueuePaths = ['/login', 'login'];

    if (isOffline) {
      // Jika request adalah GET atau termasuk dalam skip list, lempar koneksi error
      final isSkipPath = skipQueuePaths.any((path) => options.path.contains(path));
      
      if (options.method.toUpperCase() != 'GET' && !isSkipPath) {
        // Simpan ke offline queue
        await OfflineQueueDB.addRequest({
          'path': options.path,
          'method': options.method,
          'data': options.data,
          'headers': options.headers,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        // Return fake response agar form tidak error, tapi pengguna tahu datanya di-queue
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Anda sedang offline. Data disimpan dan akan dikirim saat koneksi pulih.',
            'queued': true,
            'exists': false, // Untuk antisipasi check-phone
          },
        ));
      } else {
        // GET Request -> lempar error untuk ditangkap retry/UI
        return handler.reject(DioException(
          requestOptions: options,
          error: "Tidak ada koneksi internet",
          type: DioExceptionType.connectionError,
        ));
      }
    }

    return handler.next(options);
  }
}
