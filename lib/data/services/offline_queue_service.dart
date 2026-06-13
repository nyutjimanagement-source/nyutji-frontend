import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class OfflineQueueService {
  static final OfflineQueueService _singleton = OfflineQueueService._internal();

  factory OfflineQueueService() {
    return _singleton;
  }

  OfflineQueueService._internal();

  final String _boxName = 'offline_queue';

  /// Menyimpan request yang gagal karena koneksi ke dalam antrean (Hive)
  Future<void> enqueue(RequestOptions options) async {
    try {
      final box = Hive.box(_boxName);
      
      // Hanya simpan request bertipe mutasi (POST, PUT, DELETE, PATCH)
      final method = options.method.toUpperCase();
      if (method == 'GET') return;

      final requestData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'path': options.path,
        'method': method,
        'data': options.data, // pastikan data ini bisa di-serialize ke JSON oleh Hive
        'queryParameters': options.queryParameters,
      };

      await box.add(requestData);
      debugPrint("OfflineQueueService: Request ke ${options.path} dimasukkan ke antrean offline.");
    } catch (e) {
      debugPrint("OfflineQueueService Error enqueue: $e");
    }
  }

  /// Menjalankan dan membersihkan semua request di antrean saat internet kembali
  Future<void> syncQueue() async {
    try {
      final box = Hive.box(_boxName);
      if (box.isEmpty) return;

      debugPrint("OfflineQueueService: Memulai sinkronisasi ${box.length} request...");

      final dio = ApiService().dio; // Pastikan ApiService mengekspos _dio
      
      // Ambil semua isi box
      final keys = box.keys.toList();

      for (var key in keys) {
        final requestData = box.get(key) as Map<dynamic, dynamic>;
        final path = requestData['path'] as String;
        final method = requestData['method'] as String;
        final data = requestData['data'];
        final queryParams = requestData['queryParameters'] != null 
            ? Map<String, dynamic>.from(requestData['queryParameters']) 
            : null;

        try {
          // Eksekusi ulang request
          if (method == 'POST') {
            await dio.post(path, data: data, queryParameters: queryParams);
          } else if (method == 'PUT') {
            await dio.put(path, data: data, queryParameters: queryParams);
          } else if (method == 'DELETE') {
            await dio.delete(path, data: data, queryParameters: queryParams);
          } else if (method == 'PATCH') {
            await dio.patch(path, data: data, queryParameters: queryParams);
          }

          // Jika berhasil (tidak lempar exception), hapus dari antrean
          await box.delete(key);
          debugPrint("OfflineQueueService: Berhasil sinkronisasi $method $path");

        } on DioException catch (e) {
          // Jika masih error karena jaringan, biarkan di antrean
          if (_isNetworkError(e)) {
            debugPrint("OfflineQueueService: Jaringan masih terputus saat sinkronisasi $path");
            break; // Stop sinkronisasi, coba lagi nanti
          } else {
            // Error lain (400, 401, 500 dll), hapus dari antrean agar tidak nyangkut selamanya
            await box.delete(key);
            debugPrint("OfflineQueueService: Sinkronisasi gagal permanen (Server Error/Invalid) $path: ${e.message}");
          }
        }
      }
    } catch (e) {
      debugPrint("OfflineQueueService Error syncQueue: $e");
    }
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
           e.type == DioExceptionType.sendTimeout ||
           e.type == DioExceptionType.receiveTimeout ||
           e.type == DioExceptionType.connectionError ||
           e.type == DioExceptionType.unknown; // Biasanya SocketException
  }
}
