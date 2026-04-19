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
  String _pickupNote = '';
  String _serviceSpeed = 'regular';
  String _dropMethod = 'self'; // 'self' atau 'courier'
  
  // STATE UNTUK PESANAN (Item ID -> Count)
  final Map<int, int> _itemCounts = {};
  String _itemSearchQuery = "";
  
  // STATE UNTUK MAPS & LOKASI
  String _currentGpsAddress = 'Menyesuaikan GPS...'; 
  double? _selectedLat;
  double? _selectedLng;  
  
  // STATE MITRA & ITEMS
  Map<String, dynamic>? _selectedMitra;
  final List<Map<String, dynamic>> _mockMitras = [
    {
      'id': 1, 'name': 'Nyutji Mitra Pusat', 'rating': 4.9, 'distance': 0.5, 'address': 'Jl. Arteri Kebayoran', 'district': 'Kebayoran', 
      'image': 'https://images.unsplash.com/photo-1545173168-9f1947eebb7f?w=400',
      'items': [
        {'id': 101, 'name': 'Cuci Setrika (Kg)', 'price': 8000, 'unit': 'Kg', 'is_promo': true, 'category': 'Kiloan'},
        {'id': 102, 'name': 'Setrika Saja (Kg)', 'price': 5000, 'unit': 'Kg', 'is_promo': false, 'category': 'Kiloan'},
        {'id': 103, 'name': 'Bedcover Large', 'price': 35000, 'unit': 'Pcs', 'is_promo': false, 'category': 'Satuan'},
        {'id': 104, 'name': 'Jas Formal', 'price': 50000, 'unit': 'Stel', 'is_promo': true, 'category': 'Satuan'},
      ]
    },
    {
      'id': 2, 'name': 'Laundry Express Pro', 'rating': 4.7, 'distance': 1.2, 'address': 'Jl. Gandaria Tengah', 'district': 'Kebayoran', 
      'image': 'https://images.unsplash.com/photo-1517677208155-237da1f787b1?w=400',
      'items': [
        {'id': 201, 'name': 'Cuci Kilat 6 Jam', 'price': 15000, 'unit': 'Kg', 'is_promo': false, 'category': 'Express'},
        {'id': 202, 'name': 'Cuci Sepatu Premium', 'price': 45000, 'unit': 'Psng', 'is_promo': true, 'category': 'Satuan'},
        {'id': 203, 'name': 'Boneka Jumbo', 'price': 60000, 'unit': 'Pcs', 'is_promo': false, 'category': 'Satuan'},
      ]
    },
    {
      'id': 3, 'name': 'Mitra Berkah Cuci', 'rating': 4.8, 'distance': 1.8, 'address': 'Jl. Haji Nawi', 'district': 'Grogol', 
      'image': 'https://images.unsplash.com/photo-1521656693074-0ef32e80a5d5?w=400',
      'items': [
        {'id': 301, 'name': 'Paket Anak Kos', 'price': 7000, 'unit': 'Kg', 'is_promo': true, 'category': 'Kiloan'},
        {'id': 302, 'name': 'Helm Full Face', 'price': 30000, 'unit': 'Pcs', 'is_promo': false, 'category': 'Satuan'},
      ]
    },
  ];

  // STATE SOURCE LOKASI UNTUK ICON
  IconData _locationIcon = LucideIcons.mapPin;

  final Color primaryTeal = const Color(0xFF1E5655);
  final Color bgColor = const Color(0xFFF3F4F6);

  int get _totalItems => _itemCounts.values.fold(0, (a, b) => a + b);
  int get _totalPrice {
    if (_selectedMitra == null) return 0;
    int baseTotal = 0;
    for (var item in _selectedMitra!['items']) {
      int count = _itemCounts[item['id']] ?? 0;
      baseTotal += count * (item['price'] as int);
    }
    return _serviceSpeed == 'fast' ? (baseTotal * 1.2).round() : baseTotal;
  }

  void _updateItemCount(int itemId, int delta) {
    setState(() {
      _itemCounts[itemId] = (_itemCounts[itemId] ?? 0) + delta;
      if (_itemCounts[itemId]! < 0) _itemCounts[itemId] = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final Map<String, dynamic> t = {
      'id': {
        'title_pickup': 'Penjemputan Kurir',
        'title_drop': 'Antar Sendiri',
        'loc_pickup': 'Lokasi Penjemputan',
        'loc_drop': 'Lokasi Antar Cucian',
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
        'loc_drop': 'Drop-off Location',
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
                if (widget.orderType == 'drop') _buildDropMethodToggle(),
                if (widget.orderType == 'pickup' || (widget.orderType == 'drop' && _dropMethod == 'courier'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDenseLocationCard(currentT, auth),
                  ),
                const SizedBox(height: 12),
                _buildMitraRecommendationCard(currentT),
                const SizedBox(height: 12),
                _buildDenseSpeedSelector(currentT),
                const SizedBox(height: 12),
                _buildDenseItemList(currentT),
              ],
            ),
          ),
          _buildCompactFooter(currentT, auth),
        ],
      ),
    );
  }

  Widget _buildDropMethodToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Expanded(child: _togglePill("Diambil Sendiri", 'self', LucideIcons.userCheck)),
          Expanded(child: _togglePill("Diantar Kurir", 'courier', LucideIcons.truck)),
        ],
      ),
    );
  }

  Widget _togglePill(String label, String id, IconData icon) {
    bool isSel = _dropMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _dropMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: isSel ? primaryTeal : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSel ? Colors.white : Colors.grey[400]),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: isSel ? Colors.white : Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildDenseLocationCard(Map<String, dynamic> cT, AuthProvider auth) {
    bool hasHomeAddress = auth.homeAddress != null;
    
    // Alamat utama: prioritize _pickupAddress if it was changed from default, otherwise use home address
    String displayAddr = _pickupAddress;
    if (_pickupAddress == 'Jl. Kebayoran No 12, Jakarta' && hasHomeAddress) {
      displayAddr = auth.homeAddress!['address'];
    }
    
    // Detail info: prioritize _pickupNote
    String detailInfo = _pickupNote;
    if (_pickupNote.isEmpty && hasHomeAddress && _pickupAddress == 'Jl. Kebayoran No 12, Jakarta') {
      detailInfo = auth.homeAddress!['detail'] ?? "";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(_locationIcon, size: 18, color: primaryTeal),
                  ),
                  const SizedBox(width: 12),
                  Text(widget.orderType == 'pickup' ? cT['loc_pickup'] : cT['loc_drop'], style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey[600], letterSpacing: 0.5)),
                ],
              ),
              InkWell(
                onTap: () => _showLocationPicker(cT, auth),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(8)),
                  child: Text(cT['change'], style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayAddr, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (detailInfo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(detailInfo, style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showNoteDialog(),
            child: Row(
              children: [
                Icon(LucideIcons.edit3, size: 14, color: primaryTeal),
                const SizedBox(width: 6),
                Text(_pickupNote.isEmpty ? "Tambah Catatan Alamat (No. Rumah/Gang)" : "Ubah Catatan", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTeal)),
              ],
            ),
          ),
          if (_selectedMitra != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.navigation, size: 10, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text("${_selectedMitra!['distance']} km ke Mitra", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMitraRecommendationCard(Map<String, dynamic> cT) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(LucideIcons.star, size: 18, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Text("Mitra Laundry Rekomendasi", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey[600], letterSpacing: 0.5)),
                ],
              ),
              IconButton(
                onPressed: () {}, // Searching manual logic
                icon: const Icon(LucideIcons.search, size: 18),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                color: primaryTeal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _mockMitras.length,
              itemBuilder: (context, index) {
                final mitra = _mockMitras[index];
                bool isSelected = _selectedMitra?['id'] == mitra['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMitra = mitra;
                      _itemCounts.clear(); // Reset keranjang jika pindah Mitra
                    });
                  },
                  child: Container(
                    width: 170,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryTeal.withOpacity(0.05) : bgColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? primaryTeal : Colors.transparent, width: 1.5),
                    ),
                    child: Stack(
                      children: [
                        // Background Image with Right-to-Left Gradient Fade
                        Positioned(
                          right: 0, top: 0, bottom: 0,
                          width: 100,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                            child: ShaderMask(
                              shaderCallback: (rect) {
                                return const LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [Colors.black, Colors.transparent],
                                ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                              },
                              blendMode: BlendMode.dstIn,
                              child: Image.network(
                                mitra['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200]),
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100, // Limit width to not overlap image too much
                                child: Text(mitra['name'], style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(LucideIcons.star, size: 12, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text("${mitra['rating']}", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Spacer(),
                              Text(mitra['address'], style: GoogleFonts.montserrat(fontSize: 9, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(LucideIcons.navigation, size: 10, color: primaryTeal),
                                  const SizedBox(width: 4),
                                  Text("${mitra['distance']} km", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: primaryTeal)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog() {
    final TextEditingController noteCtrl = TextEditingController(text: _pickupNote);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Keterangan Tambahan", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(
            hintText: "Contoh: No 12, Gang Mawar, Samping Alfamart",
            hintStyle: TextStyle(fontSize: 12),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            onPressed: () {
              setState(() => _pickupNote = noteCtrl.text);
              Navigator.pop(context);
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker(Map<String, dynamic> cT, AuthProvider auth) {
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
              _locOption(cT['opt_home'], auth.homeAddress != null ? "${auth.homeAddress!['detail']} ${auth.homeAddress!['address']}" : "Belum Set Alamat Rumah", LucideIcons.home, () {
                if (auth.homeAddress != null) {
                  setState(() {
                    _pickupAddress = auth.homeAddress!['address'];
                    _pickupNote = auth.homeAddress!['detail'] ?? "";
                    _locationIcon = LucideIcons.home;
                  });
                }
                Navigator.pop(context);
              }),
              
              // Option 2 & 3: Use the new NyutjiLocationPicker
              _locOption(cT['opt_gps'], cT['opt_gps_desc'], LucideIcons.crosshair, () async {
                Navigator.pop(context); // Close selection sheet
                _launchMapPicker(LucideIcons.crosshair);
              }),
              
              _locOption(cT['opt_map'], cT['opt_map_desc'], LucideIcons.map, () async {
                Navigator.pop(context); // Close selection sheet
                _launchMapPicker(LucideIcons.map);
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _launchMapPicker(IconData targetIcon) async {
    final NyutjiLocationResult? result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NyutjiLocationPicker(),
    );

    if (result != null) {
      setState(() {
        _pickupAddress = result.address;
        _selectedLat = result.lat;
        _selectedLng = result.lng;
        _locationIcon = targetIcon;
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
    if (_selectedMitra == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.store, size: 40, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text("Silakan Pilih Mitra Laundry Terlebih Dahulu", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final allItems = _selectedMitra!['items'] as List<dynamic>;
    final filteredItems = allItems.where((item) => 
      item['name'].toString().toLowerCase().contains(_itemSearchQuery.toLowerCase())
    ).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(cT['items_title'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black87)),
              if (allItems.length > 5)
                SizedBox(
                  width: 150,
                  height: 35,
                  child: TextField(
                    onChanged: (val) => setState(() => _itemSearchQuery = val),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "Cari item...",
                      prefixIcon: const Icon(LucideIcons.search, size: 14),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
          if (filteredItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text("Item tidak ditemukan", style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey))),
            ),
          ...filteredItems.map((item) => _itemRow(item)).toList(),
        ],
      ),
    );
  }

  Widget _itemRow(Map<String, dynamic> item) {
    int count = _itemCounts[item['id']] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item['name'], style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                    if (item['is_promo'])
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                        child: Text("PROMO", style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                  ],
                ),
                Text("${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item['price'])}/${item['unit']}", style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
            child: Row(
              children: [
                _ctrBtn(LucideIcons.minus, () => _updateItemCount(item['id'], -1)),
                SizedBox(width: 30, child: Center(child: Text("$count", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: primaryTeal)))),
                _ctrBtn(LucideIcons.plus, () => _updateItemCount(item['id'], 1)),
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

  Widget _buildCompactFooter(Map<String, dynamic> cT, AuthProvider auth) {
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
              onPressed: (_totalItems > 0 && _selectedMitra != null) ? () {
                // Save to History
                if (_pickupAddress.isNotEmpty) {
                  auth.addToAddressHistory({
                    'address': _pickupAddress,
                    'detail': _pickupNote,
                    'lat': _selectedLat,
                    'lng': _selectedLng,
                  });
                }
                Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerPaymentScreen(
                  totalPrice: _totalPrice, 
                  totalItems: _totalItems, 
                  address: _pickupAddress, 
                  isPickup: widget.orderType == 'pickup',
                  mitraId: _selectedMitra!['id'],
                )));
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
