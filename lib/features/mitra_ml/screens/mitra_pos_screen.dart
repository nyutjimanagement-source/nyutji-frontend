import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../providers/auth_provider.dart';
import '../../../data/services/api_service.dart';

const Color primaryTeal = Color(0xFF1E5655);

class MitraPosScreen extends StatefulWidget {
  const MitraPosScreen({super.key});

  @override
  State<MitraPosScreen> createState() => _MitraPosScreenState();
}

class _MitraPosScreenState extends State<MitraPosScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, List<dynamic>> _groupedItems = {};

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final mitraId = auth.user?['identifier'];
      if (mitraId == null) throw Exception("Mitra ID tidak ditemukan");

      final items = await _api.getMitraItems(mitraId);
      
      Map<String, List<dynamic>> grouped = {};
      for (var item in items) {
        final cat = item['category'] ?? 'Lainnya';
        if (!grouped.containsKey(cat)) grouped[cat] = [];
        grouped[cat]!.add(item);
      }

      setState(() {
        _groupedItems = grouped;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _getImageForService(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('karpet')) {
      return 'https://images.unsplash.com/photo-1595428774223-ef52624120d2?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80'; // Carpet
    } else if (lowerName.contains('jas') || lowerName.contains('formal')) {
      return 'https://images.unsplash.com/photo-1594938298596-70f56f031e4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80'; // Suit
    } else if (lowerName.contains('sepatu')) {
      return 'https://images.unsplash.com/photo-1549298916-b41d501d3772?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80'; // Shoes
    } else if (lowerName.contains('selimut') || lowerName.contains('bedcover')) {
      return 'https://images.unsplash.com/photo-1581451551609-cb29a43586b6?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80'; // Bed
    } else if (lowerName.contains('setrika')) {
      return 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80'; // Iron
    } else if (lowerName.contains('boneka')) {
      return 'https://images.unsplash.com/photo-1558237951-e37130df1b8b?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80'; // Doll
    } else if (lowerName.contains('helm')) {
      return 'https://images.unsplash.com/photo-1557973711-2098d7fa2bb8?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80'; // Helmet
    } else {
      return 'https://images.unsplash.com/photo-1582735689146-8772a80f0896?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80'; // Folded clothes (default laundry)
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return "Rp 0";
    final num = int.tryParse(amount.toString()) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(num);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Point of Sales", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryTeal))
        : _groupedItems.isEmpty
          ? Center(child: Text("Belum ada layanan.", style: GoogleFonts.montserrat(color: Colors.grey)))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: _groupedItems.entries.map((entry) {
                final category = entry.key;
                final items = entry.value;

                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          category,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75, // Proporsi mirip card marketplace
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            final imageUrl = _getImageForService(item['name'] ?? '');
                            final unit = item['unit'] ?? 'Kg';
                            final priceReg = _formatCurrency(item['price_regular'] ?? item['reg'] ?? 0);
                            final priceFast = _formatCurrency(item['price_fast'] ?? item['fast'] ?? 0);

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Gambar bagian atas
                                  Expanded(
                                    flex: 3,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Center(child: CircularProgressIndicator(color: primaryTeal, strokeWidth: 2)),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[200], 
                                              child: const Icon(Icons.broken_image, color: Colors.grey)
                                            ),
                                          ),
                                          // Overlay gelap untuk menonjolkan teks harga
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.black.withValues(alpha: 0.2),
                                                  Colors.black.withValues(alpha: 0.6),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Harga di tengah gambar
                                          Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: primaryTeal.withValues(alpha: 0.95),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: Colors.white24, width: 1),
                                                  ),
                                                  child: Text(
                                                    "$priceReg / $unit",
                                                    style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                ),
                                                if ((item['price_fast'] ?? 0) > 0) ...[
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange.withValues(alpha: 0.95),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: Colors.white24, width: 1),
                                                    ),
                                                    child: Text(
                                                      "Ekspres: $priceFast / $unit",
                                                      style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                                    ),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Nama Layanan di bagian bawah
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Center(
                                        child: Text(
                                          item['name'] ?? 'Layanan',
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: items.length,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }
}
