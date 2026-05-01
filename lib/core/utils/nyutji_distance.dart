import 'dart:math' show cos, sqrt, asin;

class NyutjiDistance {
  /// Menghitung jarak antara dua koordinat menggunakan rumus Haversine (Satuan: KM)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    if (lat1 == 0 || lon1 == 0 || lat2 == 0 || lon2 == 0) return 0.0;
    
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    
    double distance = 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
    
    return distance;
  }

  /// Format jarak ke string cantik (Contoh: 1.2 km)
  static String formatDistance(double km) {
    if (km < 1) {
      return "${(km * 1000).toStringAsFixed(0)} m";
    }
    return "${km.toStringAsFixed(2)} km";
  }
}
