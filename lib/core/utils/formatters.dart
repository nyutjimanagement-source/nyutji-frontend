import 'package:intl/intl.dart';

class Formatters {
  static String currencyIdr(dynamic amount) {
    double val = 0;
    if (amount is double) {
      val = amount;
    } else if (amount is int) {
      val = amount.toDouble();
    } else if (amount is String) {
      // Hapus karakter non-angka kecuali titik desimal
      String clean = amount.replaceAll(RegExp(r'[^0-9.]'), '');
      val = double.tryParse(clean) ?? 0;
    }
    
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(val);
  }

  static String formatPrice(dynamic amount) {
    // Sama seperti currencyIdr tapi tanpa simbol Rp
    double val = 0;
    if (amount is double) {
      val = amount;
    } else if (amount is int) {
      val = amount.toDouble();
    } else if (amount is String) {
      String clean = amount.replaceAll(RegExp(r'[^0-9.]'), '');
      val = double.tryParse(clean) ?? 0;
    }

    final NumberFormat formatter = NumberFormat.decimalPattern('id');
    return formatter.format(val);
  }

  static String generateDistrictCode(String? districtName, {String? districtCode}) {
    if (districtCode != null && districtCode.length == 3) return districtCode.toUpperCase();
    if (districtName == null || districtName.trim().isEmpty) return "NYC";
    
    String cleanName = districtName.trim().toUpperCase();
    String consonants = cleanName.replaceAll(RegExp(r'[aeiouAEIOU\s]'), '');
    if (consonants.length >= 3) {
      return consonants.substring(0, 3);
    } else {
      String clean = cleanName.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      return clean.padRight(3, 'X').substring(0, 3);
    }
  }
}
