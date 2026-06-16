import 'package:hive_flutter/hive_flutter.dart';

class OfflineQueueDB {
  static const String boxName = 'offline_queue';

  static Box get box => Hive.box(boxName);

  /// Menambahkan request ke dalam antrean offline
  static Future<void> addRequest(Map<String, dynamic> requestData) async {
    await box.add(requestData);
  }

  /// Mengambil semua antrean request beserta index-nya (agar bisa dihapus nanti)
  static List<Map<String, dynamic>> getAllRequests() {
    final List<Map<String, dynamic>> requests = [];
    for (int i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item != null) {
        // Simpan index aslinya agar bisa dihapus satu per satu
        final data = Map<String, dynamic>.from(item as Map);
        data['hive_index'] = i; 
        requests.add(data);
      }
    }
    return requests;
  }

  /// Menghapus request berdasarkan index
  static Future<void> removeRequestAt(int index) async {
    await box.deleteAt(index);
  }

  /// Mengosongkan semua antrean
  static Future<void> clearQueue() async {
    await box.clear();
  }
}
