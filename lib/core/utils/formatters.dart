import 'package:intl/intl.dart';

class Formatters {
  static String currencyIdr(double amount) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(amount);
  }

  static String nyutjiId(String prefix, dynamic id, String? districtName, {String? districtCode}) {
    if (id == null) return "$prefix-NYC-000";
    
    // Prioritize real database code (3 CHAR UNIQUE)
    String shortCode = (districtCode != null && districtCode.length == 3) 
        ? districtCode.toUpperCase() 
        : "NYC";

    // Fallback logic if database code is missing
    if (shortCode == "NYC" && districtName != null && districtName.trim().isNotEmpty) {
      String consonants = districtName.replaceAll(RegExp(r'[aeiouAEIOU\s]'), '').toUpperCase();
      if (consonants.length >= 3) {
        shortCode = consonants.substring(0, 3);
      } else {
        String clean = districtName.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
        shortCode = clean.padRight(3, 'X').substring(0, 3);
      }
    }

    String counting = id.toString();
    if (counting.length > 6) {
      // Jika identifier panjang (ML1714...), ambil 6 karakter terakhir saja agar rapi
      counting = counting.substring(counting.length - 6);
    } else {
      counting = counting.padLeft(3, '0');
    }
    
    return "$prefix-$shortCode-$counting";
  }

  static String generateDistrictCode(String? districtName, {String? districtCode}) {
    if (districtCode != null && districtCode.length == 3) return districtCode.toUpperCase();
    if (districtName == null || districtName.trim().isEmpty) return "NYC";
    
    String cleanName = districtName.trim().toUpperCase();
    // Logic: Ambil konsonan utama
    String consonants = cleanName.replaceAll(RegExp(r'[aeiouAEIOU\s]'), '');
    if (consonants.length >= 3) {
      return consonants.substring(0, 3);
    } else {
      // Jika konsonan kurang dari 3, ambil dari nama asli lalu pad dengan X
      String clean = cleanName.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      return clean.padRight(3, 'X').substring(0, 3);
    }
  }
}
