import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math';

class AdminAiOpinionScreen extends StatefulWidget {
  const AdminAiOpinionScreen({super.key});

  @override
  State<AdminAiOpinionScreen> createState() => _AdminAiOpinionScreenState();
}

class _AdminAiOpinionScreenState extends State<AdminAiOpinionScreen> {
  final Color primaryTeal = const Color(0xFF1E5655);
  final Color darkBg = const Color(0xFF0F172A); // Deep Midnight Blue
  final Color cardColor = Colors.white;
  
  final List<Map<String, dynamic>> _opinions = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  // Mock Data untuk Simulasi AI Nyutji
  final List<Map<String, dynamic>> _sourcePool = [
    {
      "source": "Twitter (X)",
      "type": "text",
      "title": "Keluhan Harga Sabun Literan",
      "summary": "Para pengusaha laundry di Jabodetabek mulai mengeluhkan kenaikan harga deterjen cair curah hingga 15% dalam sebulan terakhir. Hal ini dipicu oleh kelangkaan bahan baku impor.",
      "sentiment": "Negatif",
      "user": "@LaundryKeren",
      "icon": LucideIcons.twitter
    },
    {
      "source": "Instagram",
      "type": "image",
      "imageUrl": "https://images.unsplash.com/photo-1545173153-5dd9a739a155?q=80&w=500",
      "title": "Tren Self-Service Laundry Meningkat",
      "summary": "Postingan viral menunjukkan antrean panjang di laundry koin Jakarta Selatan. Konsumen lebih memilih laundry koin karena faktor kecepatan dan privasi pakaian dalam.",
      "sentiment": "Positif",
      "user": "JakartaInfo",
      "icon": LucideIcons.instagram
    },
    {
      "source": "Youtube",
      "type": "video",
      "imageUrl": "https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?q=80&w=500",
      "title": "Review Mesin Pengering Inverter 2024",
      "summary": "YouTuber teknologi merilis review mesin pengering terbaru yang hemat listrik hingga 40%. Menjadi topik hangat di kalangan pengusaha laundry franchise.",
      "sentiment": "Positif",
      "user": "TechReviewID",
      "icon": LucideIcons.youtube
    },
    {
      "source": "Berita Online",
      "type": "text",
      "title": "Aturan Baru Limbah Cair Laundry",
      "summary": "Pemerintah daerah mulai memperketat aturan pembuangan limbah cair laundry. Pengusaha diwajibkan memiliki sistem IPAL sederhana atau terkena sanksi administratif.",
      "sentiment": "Netral",
      "user": "DetikFinance",
      "icon": LucideIcons.globe
    },
    {
      "source": "Facebook",
      "type": "text",
      "title": "Diskusi Franchise Laundry vs Mandiri",
      "summary": "Grup 'Komunitas Laundry Indonesia' sedang ramai membahas perbandingan profit margin antara ikut franchise besar atau membangun brand mandiri di tahun 2024.",
      "sentiment": "Netral",
      "user": "Budi Santoso",
      "icon": LucideIcons.facebook
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadMoreData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMoreData();
      }
    });
  }

  Future<void> _loadMoreData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(seconds: 1));
    
    final random = Random();
    List<Map<String, dynamic>> newItems = List.generate(5, (index) {
      final base = _sourcePool[random.nextInt(_sourcePool.length)];
      return {
        ...base,
        "id": DateTime.now().millisecondsSinceEpoch + random.nextInt(10000),
      };
    });

    if (mounted) {
      setState(() {
        _opinions.addAll(newItems);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _opinions.clear();
    });
    await _loadMoreData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: primaryTeal,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildPremiumAppbar(),
            _buildSentimentStats(),
            _buildOpinionList(),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumAppbar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: darkBg,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text("Nyutji AI Opini", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [darkBg, const Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -20,
                child: Icon(LucideIcons.brainCircuit, size: 150, color: Colors.white.withOpacity(0.05)),
              )
            ],
          ),
        ),
      ),
      actions: [
        IconButton(icon: const Icon(LucideIcons.bell, color: Colors.white), onPressed: () {}),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSentimentStats() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Analisis Sentimen (3 Bulan Terakhir)", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey[800])),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  _statItem("Positif", 65, Colors.teal),
                  _statDivider(),
                  _statItem("Netral", 20, Colors.amber),
                  _statDivider(),
                  _statItem("Negatif", 15, Colors.redAccent),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text("$value%", style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          const SizedBox(height: 12),
          Container(
            height: 4, width: 30,
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 30 * (value/100), height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
            ),
          )
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[100]);
  }

  Widget _buildOpinionList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _opinions[index];
          return _buildOpinionCard(item);
        },
        childCount: _opinions.length,
      ),
    );
  }

  Widget _buildOpinionCard(Map<String, dynamic> item) {
    Color sentimentColor = item['sentiment'] == 'Positif' ? Colors.teal : (item['sentiment'] == 'Negatif' ? Colors.redAccent : Colors.amber);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        onTap: () {
          // Simulasi buka browser
          debugPrint("Membuka sumber: ${item['source']}");
        },
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Header (If Image/Video)
            if (item['type'] != 'text')
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  children: [
                    Image.network(item['imageUrl'], height: 180, width: double.infinity, fit: BoxFit.cover),
                    if (item['type'] == 'video')
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(child: Icon(LucideIcons.playCircle, color: Colors.white, size: 50)),
                        ),
                      ),
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Icon(item['icon'], size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(item['source'], style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item['type'] == 'text')
                    Row(
                      children: [
                        Icon(item['icon'], size: 14, color: primaryTeal),
                        const SizedBox(width: 8),
                        Text(item['source'], style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTeal)),
                        const Spacer(),
                        _sentimentTag(item['sentiment'], sentimentColor),
                      ],
                    )
                  else
                    _sentimentTag(item['sentiment'], sentimentColor),
                  
                  const SizedBox(height: 12),
                  Text(item['title'], style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w900, color: darkBg)),
                  const SizedBox(height: 8),
                  Text(
                    item['summary'],
                    style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600], height: 1.6),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), shape: BoxShape.circle),
                        child: Center(child: Text(item['user'][1].toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTeal))),
                      ),
                      const SizedBox(width: 8),
                      Text(item['user'], style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                      const Spacer(),
                      Text("3 bulan lalu", style: GoogleFonts.montserrat(fontSize: 9, color: Colors.grey[400])),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sentimentTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
