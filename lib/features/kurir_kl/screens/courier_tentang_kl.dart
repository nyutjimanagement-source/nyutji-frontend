import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CourierTentangKl extends StatelessWidget {
  const CourierTentangKl({super.key});

  Widget _buildRuleItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF0D9488),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF4B5563), height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          if (isWarning)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 14, 
                fontWeight: FontWeight.w800, 
                color: isWarning ? Colors.red[700] : const Color(0xFF111827)
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Tentang Nyutji KL",
          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1F2937)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logo.png', // Fallback to icon if logo doesn't exist
                    height: 60,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.water_drop, size: 60, color: Color(0xFF0D9488)),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    "🛵 Ketentuan & Kode Etik Kurir Nyutji",
                    style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Selamat bergabung di keluarga besar Nyutji! Sebagai garda terdepan, pelayanan dan kejujuran Anda adalah kunci kepuasan pelanggan. Mohon pahami dan patuhi aturan berikut:",
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF4B5563), height: 1.5),
                ),
                
                _buildSectionTitle("1. Ketepatan Waktu & Penampilan"),
                _buildRuleItem("Tepat Waktu", "Datanglah untuk mengambil (pickup) atau mengantar (delivery) pakaian sesuai jadwal yang ditentukan di aplikasi."),
                _buildRuleItem("Atribut Resmi", "Selalu gunakan seragam, jaket, dan kartu identitas Nyutji saat bertugas."),
                _buildRuleItem("Sopan & Rapi", "Jaga penampilan tetap bersih dan selalu bersikap ramah serta sopan kepada pelanggan."),

                _buildSectionTitle("2. Standar Pengambilan & Pengantaran Pakaian"),
                _buildRuleItem("Cek Jumlah & Kondisi", "Saat mengambil pakaian, pastikan jumlah kantong/potong pakaian sesuai dengan data di aplikasi."),
                _buildRuleItem("Keamanan Barang", "Pastikan pakaian pelanggan ditaruh di dalam tas/box kurir yang aman, bersih, dan terlindung dari hujan atau debu."),
                _buildRuleItem("Konfirmasi Penerimaan", "Jangan meninggalkan pakaian di pagar, keset, atau dititipkan ke orang lain tanpa konfirmasi dan persetujuan tertulis dari pelanggan melalui fitur chat aplikasi."),

                _buildSectionTitle("3. Penggunaan Aplikasi & Komunikasi"),
                _buildRuleItem("Update Status Real-time", "Selalu perbarui status perjalanan Anda di aplikasi (Contoh: Menuju Lokasi, Pakaian Diambil, Dalam Pengantaran)."),
                _buildRuleItem("Gunakan Fitur Chat Aplikasi", "Semua komunikasi dengan pelanggan wajib dilakukan melalui aplikasi Nyutji untuk menjaga privasi dan keamanan data."),
                _buildRuleItem("Foto Bukti", "Wajib mengambil foto sebagai bukti saat pakaian telah berhasil diambil atau diterima oleh pelanggan."),

                _buildSectionTitle("Larangan Keras (Sanksi Tegas)", isWarning: true),
                _buildRuleItem("Dilarang Membuka/Membongkar Pakaian", "Kurir dilarang keras membuka kantong pakaian pelanggan yang sudah disegel."),
                _buildRuleItem("Dilarang Transaksi di Luar Aplikasi", "Semua pembayaran wajib mengikuti sistem yang ada di aplikasi Nyutji. Dilarang meminta biaya tambahan di luar ketentuan resmi."),
                _buildRuleItem("Dilarang Merusak/Menghilangkan Barang", "Kelalaian yang menyebabkan pakaian kotor, basah, atau hilang akan dikenakan sanksi ganti rugi dan evaluasi akun."),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "Pelanggaran terhadap aturan di atas dapat berakibat pada pembekuan akun (suspend) hingga pemutusan kemitraan.",
                    style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red[800], height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),
                Center(
                  child: Text(
                    "Nyutji Bersihnya, Nyutji Rapinya!",
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF0D9488), fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
