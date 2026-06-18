import 'package:hive_flutter/hive_flutter.dart';

class OfflineQueueDB {
  static const String boxName = 'offline_queue';

  static Box get box => Hive.box(boxName);

  /// Menambahkan request ke dalam antrean offline
  static Future<void> addRequest(Map<String, dynamic> requestData) async {
    await box.add(requestData);
  }

  /// Mengambil semua antrean request beserta key aslinya
  static List<Map<String, dynamic>> getAllRequests() {
    final List<Map<String, dynamic>> requests = [];
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null) {
        final data = Map<String, dynamic>.from(item as Map);
        data['hive_key'] = key; 
        requests.add(data);
      }
    }
    return requests;
  }

  /// Menghapus request berdasarkan key
  static Future<void> removeRequest(dynamic key) async {
    await box.delete(key);
  }

  /// Mengosongkan semua antrean
  static Future<void> clearQueue() async {
    await box.clear();
  }
}
