import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'offline_queue_db.dart';
import '../constants/api_constants.dart';

class BackgroundSyncService {
  // Gunakan Dio standar tanpa interceptor offline agar tidak terjadi loop infinite
  static final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  static bool _isSyncing = false;

  /// Memulai pendengar perubahan status koneksi
  static void initialize() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (!result.contains(ConnectivityResult.none) && result.isNotEmpty) {
        _syncOfflineQueue();
      }
    });
    
    // Coba sync saat pertama kali initialize juga
    _syncOfflineQueue();
  }

  /// Mengeksekusi semua request yang tertunda
  static Future<void> _syncOfflineQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final requests = OfflineQueueDB.getAllRequests();
      if (requests.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint("Mulai sinkronisasi ${requests.length} antrean offline...");

      for (var req in requests) {
        final path = req['path'];
        final method = req['method'];
        final data = req['data'];
        final headers = req['headers'];
        final hiveKey = req['hive_key'];

        try {
          final response = await _dio.request(
            path,
            data: data,
            options: Options(
              method: method,
              headers: headers != null ? Map<String, dynamic>.from(headers) : null,
            ),
          );

          if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
            debugPrint("Berhasil sinkronisasi request ke $path");
            await OfflineQueueDB.removeRequest(hiveKey);
          } else if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
            // Client error (misal validation error atau auth error) - tidak akan sukses meskipun di-retry. Hapus.
            debugPrint("Gagal sinkronisasi request ke $path: Status ${response.statusCode} (Client Error). Menghapus.");
            await OfflineQueueDB.removeRequest(hiveKey);
          }
        } catch (e) {
          debugPrint("Gagal sinkronisasi request ke $path: $e");
          if (e is DioException) {
            final status = e.response?.statusCode;
            if (status != null && status >= 400 && status < 500) {
              debugPrint("Gagal sinkronisasi karena Client Error ($status). Menghapus dari antrean.");
              await OfflineQueueDB.removeRequest(hiveKey);
            }
          }
          // Server error (5xx) atau Connection error dibiarkan di antrean untuk dicoba lagi nanti
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
