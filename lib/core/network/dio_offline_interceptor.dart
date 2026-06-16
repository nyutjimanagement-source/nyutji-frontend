import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_queue_db.dart';

class DioOfflineInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    
    // Periksa apakah list connectivityResult mengandung 'none'
    // connectivityResult sekarang return List<ConnectivityResult> di connectivity_plus >= 6.0
    final isOffline = connectivityResult.contains(ConnectivityResult.none) || connectivityResult.isEmpty;

    if (isOffline) {
      if (options.method.toUpperCase() != 'GET') {
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
