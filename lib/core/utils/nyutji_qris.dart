class NyutjiQris {
  /// Mengubah payload QRIS Statis menjadi QRIS Dinamis
  /// 
  /// 1. Mengubah Tag 01 (Point of Initiation Method) dari 11 menjadi 12 (jika ada).
  /// 2. Menyisipkan Tag 54 (Transaction Amount).
  /// 3. Menghitung ulang CRC16 CCITT-FALSE.
  static String generateDynamic(String staticPayload, int amount) {
    if (staticPayload.isEmpty || amount <= 0) return staticPayload;

    // Cari posisi Tag 63 (CRC) yang selalu berada di akhir dengan format '6304' + 4 karakter hex
    int crcIndex = staticPayload.lastIndexOf('6304');
    if (crcIndex == -1) {
      // Jika format tidak valid (tidak ada CRC), kembalikan aslinya
      return staticPayload;
    }

    // Potong string dari awal hingga sebelum Tag 6304
    String basePayload = staticPayload.substring(0, crcIndex);

    // Ubah Point of Initiation Method menjadi 12 (Dinamis)
    // Tag: 01, Length: 02, Value: 11 -> 010212
    basePayload = basePayload.replaceFirst('010211', '010212');

    // Siapkan Tag 54 (Transaction Amount)
    String amountStr = amount.toString();
    String amountLen = amountStr.length.toString().padLeft(2, '0');
    String tag54 = '54$amountLen$amountStr';

    // Sisipkan Tag 54 sebelum Tag 63
    String newPayload = basePayload + tag54;

    // Siapkan string untuk dihitung CRC (termasuk tag 6304 tapi tanpa nilai CRC-nya)
    String payloadToCalculate = '${newPayload}6304';

    // Hitung CRC16 CCITT-FALSE
    int crcResult = _calculateCrc16(payloadToCalculate);
    String crcHex = crcResult.toRadixString(16).toUpperCase().padLeft(4, '0');

    // Kembalikan Payload utuh dengan CRC baru
    return '$payloadToCalculate$crcHex';
  }

  /// Implementasi algoritma CRC-16/CCITT-FALSE
  /// Polynomial: 0x1021
  /// Initial value: 0xFFFF
  static int _calculateCrc16(String payload) {
    int crc = 0xFFFF;
    for (int i = 0; i < payload.length; i++) {
      int byte = payload.codeUnitAt(i);
      crc ^= (byte << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc;
  }
}
