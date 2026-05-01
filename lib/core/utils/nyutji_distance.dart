import 'dart:math' show cos, sqrt, asin;

class NyutjiDistance {
  /// Menghitung jarak antara dua koordinat menggunakan rumus Haversine (Satuan: KM)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    if (lat1 == 0 || lon1 == 0 || lat2 == 0 || lon2 == 0) return 0.0;
    
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    
    double distance = 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
    
    // ANTI-NaN PROTECTION
    if (distance.isNaN) return 0.1;
    
    return distance;
  }

  /// Menghitung Jarak Jalan Nyutji (NRCF - Nyutji Road-Correction Factor)
  /// Tiered Multiplier untuk fairness kurir & sistem
  static double calculateRoadDistance(double straightDistanceKm) {
    if (straightDistanceKm <= 0) return 0.0;
    
    // TIERED LOGIC
    double multiplier;
    if (straightDistanceKm < 3.0) {
      multiplier = 1.59; // Area perumahan/padat (banyak belokan)
    } else {
      multiplier = 1.48; // Jalan raya/jarak jauh (lebih stabil)
    }
    
    return straightDistanceKm * multiplier;
  }

  /// Format jarak ke string cantik (Contoh: 1.2 km)
  static String formatDistance(double km) {
    if (km <= 0) return "0 m";
    if (km < 1) {
      return "${(km * 1000).toStringAsFixed(0)} m";
    }
    return "${km.toStringAsFixed(2)} km";
  }
}
