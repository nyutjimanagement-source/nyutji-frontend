/// NyutjiParser: Utilitas 'Genius' untuk menangani ketidakkonsistenan tipe data 
/// antara database (Postgres), API (JSON), dan UI (OSM/Google Maps).
class NyutjiParser {
  
  /// Mengonversi data apapun (String, int, double, num, null) menjadi double yang aman.
  static double toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      // Hilangkan spasi jika ada
      return double.tryParse(value.trim()) ?? defaultValue;
    }
    return defaultValue;
  }

  static String toCoordString(dynamic lat, dynamic lng) {
    double dLat = toDouble(lat);
    double dLng = toDouble(lng);
    return "$dLat,$dLng";
  }
}

/// Extension agar penggunaan di kodingan lebih elegan
extension NyutjiDoubleExtension on Object? {
  double toSafeDouble({double defaultValue = 0.0}) {
    return NyutjiParser.toDouble(this, defaultValue: defaultValue);
  }
}
