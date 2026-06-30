import 'dart:convert';

class ChatUtils {
  /// Mengekstrak nama dari string JSON atau Map
  static String extractName(dynamic val, {String fallback = 'Kurir'}) {
    if (val == null) return fallback;
    if (val is Map) return val['name']?.toString() ?? fallback;
    if (val is String) {
      if (val.trim().startsWith('{')) {
        try {
          // Coba parse sebagai strict JSON terlebih dahulu
          // Jika formatnya seperti '{"name": "Budi", "identifier": "KL-123"}'
          final parsed = jsonDecode(val);
          return parsed['name']?.toString() ?? fallback;
        } catch (_) {
          // Fallback parsing manual untuk JSON tidak valid seperti '{name: Budi, identifier: KL-123}'
          final match = RegExp(r'name:\s*([^,}]+)').firstMatch(val);
          if (match != null) return match.group(1)?.trim() ?? fallback;
        }
      }
      if (val.trim() == '-' || val.trim() == 'null' || val.trim() == 'Belum Ada') {
        return fallback;
      }
      return val;
    }
    return fallback;
  }

  /// Mengekstrak URL foto dari string JSON atau Map
  static String? extractPhoto(dynamic val) {
    if (val == null) return null;
    if (val is Map) return val['photo']?.toString() ?? val['photo_url']?.toString();
    if (val is String) {
      if (val.trim().startsWith('{')) {
        try {
          final parsed = jsonDecode(val);
          return parsed['photo']?.toString() ?? parsed['photo_url']?.toString();
        } catch (_) {
          // Fallback parsing manual untuk photo: URL
          final match = RegExp(r'photo(?:_url)?:\s*([^,}]+)').firstMatch(val);
          if (match != null) {
            String url = match.group(1)?.trim() ?? '';
            if (url.startsWith("'") && url.endsWith("'")) url = url.substring(1, url.length - 1);
            if (url.startsWith('"') && url.endsWith('"')) url = url.substring(1, url.length - 1);
            return url.isNotEmpty && url != 'null' ? url : null;
          }
        }
      }
    }
    return null;
  }

  /// Menentukan apakah chat kurir perlu dimunculkan berdasarkan tipe pengiriman dan status
  static bool isCourierNeeded(String deliveryType, String status) {
    final del = deliveryType.toUpperCase();
    if (del == 'SELFDROP_SELFDELIVERY' || del == 'SELF_SERVICE') return false;
    
    // Jika SELF_DROP, pelanggan antar sendiri ke mitra, kurir tidak ada saat penjemputan
    if (del == 'SELF_DROP' && (status == 'WAITING_PICKUP' || status == 'PICKUP')) {
      return false;
    }

    // Jika SELFDELIVERY, pelanggan ambil sendiri di mitra, kurir tidak ada saat pengantaran
    if (del == 'SELFDELIVERY' && (status == 'DELIVERING' || status == 'WAITING_DELIVERY')) {
      return false;
    }

    return true;
  }
}
