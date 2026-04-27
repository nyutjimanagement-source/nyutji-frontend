import 'package:flutter/material.dart';

/// SimulasiProvider — Pusat kendali saldo dummy untuk demo flow PL→ML→KL
/// Tidak terhubung ke payment gateway, hanya in-memory simulation.
class SimulasiProvider extends ChangeNotifier {
  // ── Saldo per Role ─────────────────────────────────────────────────────────
  double _saldoPL       = 0.0;
  double _saldoML       = 0.0;
  double _saldoKL       = 0.0;
  double _saldoPlatform = 0.0;

  double get saldoPL       => _saldoPL;
  double get saldoML       => _saldoML;
  double get saldoKL       => _saldoKL;
  double get saldoPlatform => _saldoPlatform;

  // ── Riwayat Mutasi per Role ────────────────────────────────────────────────
  final List<Map<String, dynamic>> _mutasiPL       = [];
  final List<Map<String, dynamic>> _mutasiML       = [];
  final List<Map<String, dynamic>> _mutasiKL       = [];
  final List<Map<String, dynamic>> _mutasiPlatform = [];

  List<Map<String, dynamic>> get mutasiPL       => List.unmodifiable(_mutasiPL);
  List<Map<String, dynamic>> get mutasiML       => List.unmodifiable(_mutasiML);
  List<Map<String, dynamic>> get mutasiKL       => List.unmodifiable(_mutasiKL);
  List<Map<String, dynamic>> get mutasiPlatform => List.unmodifiable(_mutasiPlatform);

  // ── Skema Bagi Hasil ───────────────────────────────────────────────────────
  static const double _pctML       = 0.80; // 80% untuk Mitra
  static const double _pctPlatform = 0.20; // 20% untuk Platform
  static const double _pctKLHalf   = 0.50; // Ongkir KL dibagi 2 tahap

  // ── Data Order Aktif ───────────────────────────────────────────────────────
  String? _activeOrderId;
  double  _totalLaundry = 0.0; // biaya laundry (tanpa ongkir)
  double  _totalOngkir  = 0.0; // biaya pengantaran
  bool    _ongkirPhase1Done = false; // sudah bayar 50% KL di pickup?

  String? get activeOrderId => _activeOrderId;
  double  get totalLaundry  => _totalLaundry;
  double  get totalOngkir   => _totalOngkir;
  bool    get ongkirPhase1Done => _ongkirPhase1Done;

  // ══════════════════════════════════════════════════════════════════════════
  // FASE A — PL Bayar saat membuat pesanan
  // ══════════════════════════════════════════════════════════════════════════
  void bayarOrder({
    required String orderId,
    required double biayaLaundry,
    required double biayaOngkir,
  }) {
    final total = biayaLaundry + biayaOngkir;
    _activeOrderId    = orderId;
    _totalLaundry     = biayaLaundry;
    _totalOngkir      = biayaOngkir;
    _ongkirPhase1Done = false;

    // Potong saldo PL
    _saldoPL -= total;
    _addMutasi(_mutasiPL, 'debit', -total, 'Bayar Pesanan #$orderId');

    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FASE B — KL pickup selesai: KL terima 50% ongkir
  // ══════════════════════════════════════════════════════════════════════════
  void pickupSelesai(String orderId) {
    if (_ongkirPhase1Done) return;
    final halfOngkir = _totalOngkir * _pctKLHalf;

    _saldoKL += halfOngkir;
    _ongkirPhase1Done = true;
    _addMutasi(_mutasiKL, 'kredit', halfOngkir, 'Ongkir Pickup 50% #$orderId');

    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FASE D — PL Konfirm Terima: settlement semua pihak
  // ══════════════════════════════════════════════════════════════════════════
  void konfirmTerima(String orderId) {
    // ML: 80% biaya laundry
    final bagianML       = _totalLaundry * _pctML;
    final bagianPlatform = _totalLaundry * _pctPlatform;
    // KL: 50% ongkir sisanya
    final bagianKL2      = _totalOngkir * _pctKLHalf;

    _saldoML       += bagianML;
    _saldoPlatform += bagianPlatform;
    _saldoKL       += bagianKL2;

    _addMutasi(_mutasiML,       'kredit', bagianML,       'Bagi Hasil 80% #$orderId');
    _addMutasi(_mutasiPlatform, 'kredit', bagianPlatform, 'Fee Platform 20% #$orderId');
    _addMutasi(_mutasiKL,       'kredit', bagianKL2,      'Ongkir Delivery 50% #$orderId');

    // Reset order aktif
    _activeOrderId    = null;
    _totalLaundry     = 0;
    _totalOngkir      = 0;
    _ongkirPhase1Done = false;

    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UTILITY — Top Up saldo PL (untuk simulasi top up wallet)
  // ══════════════════════════════════════════════════════════════════════════
  void topUpPL(double amount, {String? note}) {
    _saldoPL += amount;
    _addMutasi(_mutasiPL, 'kredit', amount, note ?? 'Top Up Wallet');
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER
  // ══════════════════════════════════════════════════════════════════════════
  void _addMutasi(
    List<Map<String, dynamic>> list,
    String type,
    double amount,
    String title,
  ) {
    list.insert(0, {
      'title':  title,
      'amount': amount,
      'type':   type,
      'date':   _nowLabel(),
    });
  }

  String _nowLabel() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')} '
        '${_bulan(now.month)} ${now.year}, '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _bulan(int m) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return months[m - 1];
  }

  /// Reset semua saldo ke 0 (untuk restart simulasi)
  void resetSimulasi() {
    _saldoPL       = 0;
    _saldoML       = 0;
    _saldoKL       = 0;
    _saldoPlatform = 0;
    _mutasiPL.clear();
    _mutasiML.clear();
    _mutasiKL.clear();
    _mutasiPlatform.clear();
    _activeOrderId    = null;
    _totalLaundry     = 0;
    _totalOngkir      = 0;
    _ongkirPhase1Done = false;
    notifyListeners();
  }
}
