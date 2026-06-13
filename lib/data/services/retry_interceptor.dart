import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'offline_queue_service.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({required this.dio, this.maxRetries = 3});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Mengecek apakah error ini murni karena tidak ada internet/koneksi putus
    if (_isNetworkError(err)) {
      int retryCount = err.requestOptions.extra['retryCount'] ?? 0;

      if (retryCount < maxRetries) {
        retryCount++;
        err.requestOptions.extra['retryCount'] = retryCount;

        // Exponential backoff delay (1s, 2s, 3s)
        final delaySeconds = retryCount;
        debugPrint("Koneksi gagal. Mencoba ulang request ke ${err.requestOptions.path} dalam $delaySeconds detik (Percobaan $retryCount dari $maxRetries)...");
        
        await Future.delayed(Duration(seconds: delaySeconds));

        try {
          // Buat instance Dio terpisah atau request manual untuk re-try
          // agar tidak memicu endless loop dengan interceptor ini jika kita menggunakan dio.fetch()
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (retryErr) {
          // Lempar kembali ke handler ini (rekursif) sampai batas maxRetries
          return onError(retryErr, handler);
        }
      } else {
        debugPrint("Gagal terhubung ke ${err.requestOptions.path} setelah $maxRetries percobaan.");
        
        // Jika retry sudah habis dan jenis request adalah mutasi (POST/PUT/DELETE/PATCH),
        // masukkan ke Offline Queue agar tidak hilang.
        final method = err.requestOptions.method.toUpperCase();
        if (method != 'GET') {
          await OfflineQueueService().enqueue(err.requestOptions);
        }
      }
    }

    // Jika error bukan karena jaringan, atau sudah mencapai limit maxRetries,
    // teruskan error ke UI (seperti biasa)
    return super.onError(err, handler);
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
           e.type == DioExceptionType.sendTimeout ||
           e.type == DioExceptionType.receiveTimeout ||
           e.type == DioExceptionType.connectionError ||
           e.type == DioExceptionType.unknown; // Biasanya socket exception karena Wi-Fi mati
  }
}
