import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StatusHelper {
  /// Mendapatkan label status berdasarkan role (PL, ML, KL)
  static String getLabel(String status, String role) {
    final s = status.toUpperCase();
    
    // Mapping default (biasanya digunakan untuk PL atau fallback)
    final Map<String, String> labels = {
      'SEARCHING': role == 'KL' ? 'ORDER TERSEDIA' : (role == 'ML' ? 'MENCARI KURIR' : 'Mencari Kurir'),
      'COURIER_ACCEPTED': role == 'KL' ? 'TUGAS DIAMBIL' : (role == 'ML' ? 'KURIR DIAMBIL' : 'Kurir Diperjalanan'),
      'WAITING_DROPOFF': role == 'KL' ? 'JEMPUT CUCIAN' : (role == 'ML' ? 'MENUNGGU DROP' : 'Menunggu Drop-off'),
      'PICKING_UP': role == 'KL' ? 'SEDANG JEMPUT' : (role == 'ML' ? 'DIJEMPUT' : 'Sedang Dijemput'),
      'WEIGHING': role == 'KL' ? 'CUCIAN DITERIMA' : (role == 'ML' ? 'TIMBANGAN' : 'Timbangan'),
      'WASH_START': role == 'KL' ? 'SEDANG PROSES' : (role == 'ML' ? 'DICUCI' : 'Sedang Dicuci'),
      'IRONING': role == 'KL' ? 'SEDANG PROSES' : (role == 'ML' ? 'SETRIKA' : 'Sedang Disetrika'),
      'PACKING': role == 'KL' ? 'SIAP ANTAR' : (role == 'ML' ? 'PACKING' : 'Sedang Dikemas'),
      'DELIVERING': role == 'KL' ? 'SEDANG ANTAR' : (role == 'ML' ? 'DIANTAR' : 'Sedang Diantar'),
      'DONE': 'SELESAI',
      'PAID': 'SELESAI',
    };

    return labels[s] ?? s;
  }

  /// Mendapatkan warna tema untuk status tertentu
  static Color getColor(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'SEARCHING': return Colors.orange;
      case 'COURIER_ACCEPTED': return Colors.indigo;
      case 'WAITING_DROPOFF': return Colors.blue;
      case 'PICKING_UP': return Colors.teal;
      case 'WEIGHING': return Colors.amber;
      case 'WASH_START': return Colors.blue;
      case 'IRONING': return Colors.deepOrange;
      case 'PACKING': return Colors.purple;
      case 'DELIVERING': return Colors.teal;
      case 'DONE':
      case 'PAID':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Mendapatkan icon untuk status tertentu
  static IconData getIcon(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'SEARCHING':
      case 'COURIER_ACCEPTED':
      case 'WAITING_DROPOFF':
      case 'PICKING_UP':
        return LucideIcons.truck;
      case 'WEIGHING':
        return LucideIcons.scale;
      case 'WASH_START':
      case 'IRONING':
        return LucideIcons.droplets;
      case 'PACKING':
        return LucideIcons.package;
      case 'DELIVERING':
        return LucideIcons.navigation;
      default:
        return LucideIcons.helpCircle;
    }
  }

  /// Mendapatkan deskripsi bantuan untuk pelanggan (PL)
  static String getCustomerDescription(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'SEARCHING': return 'Sistem sedang mencarikan kurir terbaik untuk Anda.';
      case 'COURIER_ACCEPTED': return 'Kurir telah menerima pesanan dan akan segera berangkat.';
      case 'WAITING_DROPOFF': return 'Kurir sedang dalam perjalanan menuju lokasi jemput.';
      case 'PICKING_UP': return 'Cucian Anda sedang diambil oleh kurir.';
      case 'WEIGHING': return 'Cucian sudah sampai di Mitra dan sedang ditimbang.';
      case 'WASH_START': return 'Cucian Anda sedang diproses (Cuci & Dry).';
      case 'IRONING': return 'Cucian Anda sedang dalam tahap setrika.';
      case 'PACKING': return 'Cucian sudah bersih dan sedang dikemas rapi.';
      case 'DELIVERING': return 'Kurir sedang mengantar cucian kembali ke lokasi Anda.';
      case 'DONE': return 'Pesanan selesai. Terima kasih telah menggunakan Nyutji!';
      default: return 'Pesanan Anda sedang dalam proses.';
    }
  }
}
