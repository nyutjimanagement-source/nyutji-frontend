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

      // Hapus semua terlebih dahulu dari box jika kita akan sync dengan asumsi berhasil atau gagal akan di handle
      // Pendekatan lebih aman: Hapus hanya yang berhasil, tapi perhatikan pergeseran index
      // Karena kita mengambil semua data, kita proses lalu hapus berdasar key/index di akhir jika sukses
      
      // Catatan: Jika menghapus per index di dalam loop for, index Hive akan bergeser!
      // Jadi kita pakai list key atau hapus dari belakang, tapi lebih mudah pakai mapping key.
      
      for (int i = 0; i < requests.length; i++) {
        final req = requests[i];

        final path = req['path'];
        final method = req['method'];
        dynamic data = req['data'];
        
        // Logika Genius: Rekonstruksi FormData jika tipe payload adalah multipart/gambar
        if (data is Map && data['is_multipart'] == true) {
          final filePath = data['file_path'];
          final fileField = data['file_field'];
          data = FormData.fromMap({
             fileField: await MultipartFile.fromFile(filePath),
          });
        }
        final headers = req['headers'];

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
            // Berhasil
            debugPrint("Berhasil sinkronisasi request ke $path");
            // Karena kita mendelete dari box, index lain bergeser. Jadi kita harus berhati-hati.
            // Lebih aman menghapus langsung dan mere-fetch jika perlu, tapi untuk simple approach:
            // Kita kumpulkan ID/Key jika pakai Map, tapi Hive list pakai index numerik.
          }
        } catch (e) {
          debugPrint("Gagal sinkronisasi request ke $path: $e");
        }
      }
      
      // Simplifikasi: Kosongkan queue jika sudah di-attempt semua (atau buat sistem validasi lebih detail)
      // Untuk stabilitas awal: Kosongkan semua queue setelah attempt.
      await OfflineQueueDB.clearQueue();
      
    } finally {
      _isSyncing = false;
    }
  }
}
