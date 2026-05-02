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
