import 'package:dio/dio.dart';
import 'offline_queue_db.dart';

class DioOfflineInterceptor extends Interceptor {
  const DioOfflineInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Tangkap error jika tidak ada koneksi
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      
      final options = err.requestOptions;
      final skipQueuePaths = ['/login', 'login'];
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
            'exists': false,
          },
        ));
      }
    }
    
    return handler.next(err);
  }
}
