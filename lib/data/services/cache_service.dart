import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class CacheService {
  static const String boxName = 'nyutji_cache';

  static Box get _box => Hive.box(boxName);

  /// Menyimpan data JSON ke cache
  static Future<void> set(String key, dynamic value) async {
    try {
      final jsonStr = jsonEncode(value);
      await _box.put(key, jsonStr);
    } catch (e) {
      debugPrint("Error writing to cache: $e");
    }
  }

  /// Mengambil data JSON dari cache
  static dynamic get(String key) {
    try {
      final cached = _box.get(key);
      if (cached != null) {
        return jsonDecode(cached);
      }
    } catch (e) {
      debugPrint("Error reading cache: $e");
    }
    return null;
  }

  /// Menghapus cache berdasarkan key
  static Future<void> delete(String key) async {
    try {
      await _box.delete(key);
    } catch (e) {
      debugPrint("Error deleting cache: $e");
    }
  }

  /// Membersihkan seluruh cache
  static Future<void> clear() async {
    try {
      await _box.clear();
    } catch (e) {
      debugPrint("Error clearing cache: $e");
    }
  }
}
