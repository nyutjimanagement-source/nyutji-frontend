import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/nyutji_location_picker.dart';
import '../../../providers/auth_provider.dart';
import 'customer_payment_screen.dart';

class CustomerOrderScreen extends StatefulWidget {
  final String orderType;

  const CustomerOrderScreen({
    super.key,
    this.orderType = 'pickup',
  });

  @override
  State<CustomerOrderScreen> createState() => _CustomerOrderScreenState();
}

class _CustomerOrderScreenState extends State<CustomerOrderScreen> {
  String _pickupAddress = 'Jl. Kebayoran No 12, Jakarta';
  String _serviceSpeed = 'regular';
  final Map<String, int> _items = {'baju': 0, 'jaket': 0, 'selimut': 0, 'helm': 0};
  final Map<String, int> _prices = {'baju': 8000, 'jaket': 15000, 'selimut': 25000, 'helm': 30000};
  
  // STATE UNTUK MAPS & LOKASI
  // REMOVAL: Google LatLng depends on google_maps_flutter which we are removing
  // We'll use simple strings or the result from our new picker.
  String _currentGpsAddress = 'Menyesuaikan GPS...'; 
  double? _selectedLat;
  double? _selectedLng;  
  final Color primaryTeal = const Color(0xFF1E5655);
  final Color bgColor = const Color(0xFFF3F4F6);

  int get _totalItems => _items.values.reduce((a, b) => a + b);
  int get _totalPrice {
    int baseTotal = _items.entries.fold(0, (sum, entry) => sum + (entry.value * _prices[entry.key]!));
    return _serviceSpeed == 'fast' ? (baseTotal * 1.2).round() : baseTotal;
  }

  void _updateItemCount(String key, int delta) {
    setState(() => _items[key] = (_items[key]! + delta).clamp(0, 99));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final Map<String, dynamic> t = {
      'id': {
        'title_pickup': 'Penjemputan Kurir',
        'title_drop': 'Antar Sendiri',
        'loc_pickup': 'Lokasi Penjemputan',
        'loc_drop': 'Lokasi Mitra Terpilih',
        'change': 'Ubah',
        'speed_reg': 'Regular',
        'speed_reg_desc': '2-3 Hari',
        'speed_fast': 'Fast Track',
        'speed_fast_desc': 'Same Day (+20%)',
        'items_title': 'Pilih Item Cucian',
        'item_baju': 'Baju/Celana (Kg)',
        'item_jaket': 'Jaket (Pcs)',
        'item_selimut': 'Selimut (Mtr)',
        'item_helm': 'Helm (Pcs)',
        'total': 'Total Estimasi',
        'confirm': 'KONFIRMASI',
        'opt_home': 'Rumah Sendiri',
        'opt_gps': 'Posisi Sekarang',
        'opt_gps_desc': 'Menyesuaikan GPS perangkat',
        'opt_map': 'Order Tempat Lain',
        'opt_map_desc': 'Titik Antar Kustom pada Peta',
      },
      'en': {
        'title_pickup': 'Courier Pickup',
        'title_drop': 'Self Drop-off',
        'loc_pickup': 'Pickup Location',
        'loc_drop': 'Selected Partner Location',
        'change': 'Change',
        'speed_reg': 'Regular',
        'speed_reg_desc': '2-3 Days',
        'speed_fast': 'Fast Track',
        'speed_fast_desc': 'Same Day (+20%)',
        'items_title': 'Select Laundry Items',
        'item_baju': 'Clothes/Pants (Kg)',
        'item_jaket': 'Jacket (Pcs)',
        'item_selimut': 'Blanket (Mtr)',
        'item_helm': 'Helmet (Pcs)',
        'total': 'Estimated Total',
        'confirm': 'CONFIRM',
        'opt_home': 'My Home',
        'opt_gps': 'Current Location',
        'opt_gps_desc': 'Use device GPS',
        'opt_map': 'Other Location',
        'opt_map_desc': 'Custom Point on Map',
      }
    };
    final currentT = t[auth.lang] ?? t['id'];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.orderType == 'pickup' ? currentT['title_pickup'] : currentT['title_drop'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(LucideIcons.shoppingBag, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text("$_totalItems", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDenseLocationCard(currentT),
                const SizedBox(height: 12),
                _buildDenseSpeedSelector(currentT),
                const SizedBox(height: 12),
                _buildDenseItemList(currentT),
              ],
            ),
          ),
          _buildCompactFooter(currentT),
        ],
      ),
    );
  }

  Widget _buildDenseLocationCard(Map<String, dynamic> cT) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.orderType == 'pickup' ? cT['loc_pickup'] : cT['loc_drop'], style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.mapPin, size: 16, color: primaryTeal),
              const SizedBox(width: 8),
              Expanded(child: Text(_pickupAddress, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
              InkWell(
                onTap: () => _showLocationPicker(cT),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(cT['change'], style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showLocationPicker(Map<String, dynamic> cT) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cT['loc_pickup'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Text("Silakan pilih cara penentuan lokasi penjemputan:", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(height: 20),
              
              // Option 1: Rumah Sendiri
              _locOption(cT['opt_home'], "Jl. Kebayoran No 12, Jakarta", LucideIcons.home, () {
                setState(() => _pickupAddress = "Jl. Kebayoran No 12, Jakarta");
                Navigator.pop(context);
              }),
              
              // Option 2 & 3: Use the new NyutjiLocationPicker
              _locOption(cT['opt_gps'], cT['opt_gps_desc'], LucideIcons.crosshair, () async {
                Navigator.pop(context); // Close selection sheet
                _launchMapPicker();
              }),
              
              _locOption(cT['opt_map'], cT['opt_map_desc'], LucideIcons.map, () async {
                Navigator.pop(context); // Close selection sheet
                _launchMapPicker();
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _launchMapPicker() async {
    final NyutjiLocationResult? result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NyutjiLocationPicker(),
    );

    if (result != null) {
      setState(() {
        _pickupAddress = "${result.district}, ${result.city}";
        _selectedLat = result.lat;
        _selectedLng = result.lng;
      });
    }
  }

  Widget _locOption(String title, String desc, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: primaryTeal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text(desc, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDenseSpeedSelector(Map<String, dynamic> cT) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Expanded(child: _speedPill(cT['speed_reg'], cT['speed_reg_desc'], 'regular', primaryTeal)),
          Expanded(child: _speedPill(cT['speed_fast'], cT['speed_fast_desc'], 'fast', Colors.red)),
        ],
      ),
    );
  }

  Widget _speedPill(String title, String desc, String id, Color activeC) {
    bool isSel = _serviceSpeed == id;
    return GestureDetector(
      onTap: () => setState(() => _serviceSpeed = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: isSel ? activeC.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(title, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? activeC : Colors.grey[400])),
            Text(desc, style: GoogleFonts.montserrat(fontSize: 9, color: isSel ? activeC.withOpacity(0.8) : Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildDenseItemList(Map<String, dynamic> cT) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cT['items_title'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          const Divider(height: 24),
          _itemRow(cT['item_baju'], 'baju', 8000),
          _itemRow(cT['item_jaket'], 'jaket', 15000),
          _itemRow(cT['item_selimut'], 'selimut', 25000),
          _itemRow(cT['item_helm'], 'helm', 30000),
        ],
      ),
    );
  }

  Widget _itemRow(String label, String key, int price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
              Text("Rp ${price/1000}k", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
          Container(
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
            child: Row(
              children: [
                _ctrBtn(LucideIcons.minus, () => _updateItemCount(key, -1)),
                SizedBox(width: 24, child: Center(child: Text("${_items[key]}", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)))),
                _ctrBtn(LucideIcons.plus, () => _updateItemCount(key, 1)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _ctrBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 14, color: Colors.black54)),
    );
  }

  Widget _buildCompactFooter(Map<String, dynamic> cT) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cT['total'], style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_totalPrice), style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, color: primaryTeal)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _totalItems > 0 ? () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerPaymentScreen(totalPrice: _totalPrice, totalItems: _totalItems, address: _pickupAddress, isPickup: widget.orderType == 'pickup')));
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text(cT['confirm'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
