// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../providers/issue_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/nyutji_theme.dart';

class AdminIssuesScreen extends ConsumerStatefulWidget {
  const AdminIssuesScreen({super.key});

  @override ConsumerState<AdminIssuesScreen> createState() => _AdminIssuesScreenState();
}

class _AdminIssuesScreenState extends ConsumerState<AdminIssuesScreen> with TickerProviderStateMixin {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _blinkController;
  
  // Center: area Pamulang sesuai data ML yang ada
  static const LatLng _defaultCenter = LatLng(-6.348, 106.744);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Fetch data mitra real dari backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider).fetchAllUsers(); // untuk fitur admin lain
      ref.read(authProvider).fetchMitras();   // untuk koordinat peta
    });
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _handleSearch() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return;

    final mitras = ref.read(authProvider).mitras;
    try {
      final target = mitras.firstWhere(
        (ml) => (ml['name'] ?? ml['shop_name'] ?? '').toString().toLowerCase().contains(query),
      );
      final lat = double.tryParse(target['lat']?.toString() ?? '') ?? 0;
      final lng = double.tryParse(target['lng']?.toString() ?? '') ?? 0;
      if (lat != 0 && lng != 0) {
        _animatedMapMove(LatLng(lat, lng), 15.0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mitra ditemukan tapi lokasi belum diset"), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mitra tidak ditemukan"), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(issueProvider);
    final auth = ref.watch(authProvider);
    // Gunakan auth.mitras dari /public/mitras yang menyertakan lat/lng
    final mitras = auth.mitras.where((u) {
      final lat = double.tryParse(u['lat']?.toString() ?? '') ?? 0;
      final lng = double.tryParse(u['lng']?.toString() ?? '') ?? 0;
      return lat != 0 && lng != 0;
    }).toList();
    if (mitras.isNotEmpty) {
      debugPrint('[MAP] mitras with coords: ${mitras.length}');
      
      // LOGIKA JENIUS: Auto-fit peta agar SEMUA Mitra (termasuk Bandung) terlihat
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mitras.length > 1) {
          final bounds = LatLngBounds.fromPoints(
            mitras.map((m) => LatLng(
              double.parse(m['lat'].toString()), 
              double.parse(m['lng'].toString())
            )).toList()
          );
          // Tambahkan padding agar tidak mepet ke pinggir layar (Mewah)
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
        }
      });
    }

    return Container(
      color: NyutjiTheme.background,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildDenseHeader(),
            _buildInteractiveMapSection(mitras),
            const SizedBox(height: 24),
            _buildLiveIssuesSection(provider),
            const SizedBox(height: 24),
            _buildOperationalReferences(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDenseHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: NyutjiTheme.adPrimary,
        gradient: LinearGradient(
          colors: [NyutjiTheme.adPrimary, Color(0xFF2C1E18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20, top: -20,
            child: Icon(LucideIcons.alertCircle, size: 140, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "OPERATIONAL ISSUES",
                style: NyutjiTheme.h1(Colors.white).copyWith(fontSize: 14, letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                "Manajemen Kendala Teknis dari Mitra (ML)",
                style: NyutjiTheme.detail(Colors.grey[400]!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMapSection(List<dynamic> mitras) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: NyutjiTheme.adPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        child: Stack(
          children: [
            // FLUTTER MAP (OSM)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 10.0,
                backgroundColor: const Color(0xFFa8d5e8), // OSM water color, tidak abu-abu
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.nyutji.app',
                ),
                MarkerLayer(
                  markers: mitras.where((ml) {
                    final lat = double.tryParse(ml['lat']?.toString() ?? '') ?? 0;
                    final lng = double.tryParse(ml['lng']?.toString() ?? '') ?? 0;
                    return lat != 0 && lng != 0;
                  }).map((ml) {
                    final lat = double.parse(ml['lat'].toString());
                    final lng = double.parse(ml['lng'].toString());
                    final name = (ml['name'] ?? ml['shop_name'] ?? '-').toString();
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 80, height: 52,
                      child: _buildBlinkingMarker(name),
                    );
                  }).toList(),
                ),
              ],
            ),

            // OVERLAY: Rounded Container untuk Title + Search
            Positioned(
              top: 16, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Sebaran Mitra (ML)",
                            style: NyutjiTheme.h3(NyutjiTheme.adPrimary).copyWith(fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildSearchBox(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Peta interaktif sebaran operasional",
                      style: NyutjiTheme.detail(NyutjiTheme.textGrey),
                    ),
                  ],
                ),
              ),
            ),

            // ZOOM CONTROLS
            Positioned(
              right: 16,
              bottom: 24,
              child: Column(
                children: [
                  _buildMapControl(LucideIcons.plus, () {
                    final newZoom = _mapController.camera.zoom + 1;
                    _animatedMapMove(_mapController.camera.center, newZoom);
                  }),
                  const SizedBox(height: 8),
                  _buildMapControl(LucideIcons.minus, () {
                    final newZoom = _mapController.camera.zoom - 1;
                    _animatedMapMove(_mapController.camera.center, newZoom);
                  }),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Flexible(
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: NyutjiTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.search, color: NyutjiTheme.adPrimary, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _handleSearch(),
                style: NyutjiTheme.detail(NyutjiTheme.darkText),
                decoration: const InputDecoration(
                  hintText: "Cari ML...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 10),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlinkingMarker(String name) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // DOT — sama persis dengan system status di admin_main_screen.dart
        FadeTransition(
          opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_blinkController),
          child: Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E), // Hijau mewah
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.8), blurRadius: 8, spreadRadius: 2)
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),
        // NAMA ML
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            name,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: NyutjiTheme.adPrimary, size: 20),
      ),
    );
  }

  Widget _buildLiveIssuesSection(IssueProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Kendala & Gangguan ML",
                style: NyutjiTheme.h3(NyutjiTheme.darkText),
              ),
              Text(
                "Lihat Semua",
                style: NyutjiTheme.actionLabel(const Color(0xFFC3312E)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeaturedIssueCard(
            "Mesin Cuci Rusak (Area Depok)",
            "Berdampak pada 45 order reguler telat",
            LucideIcons.alertOctagon,
            const Color(0xFFC3312E),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedIssueCard(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: NyutjiTheme.h3(const Color(0xFF991B1B)).copyWith(fontSize: 13),
                ),
                Text(
                  desc,
                  style: NyutjiTheme.detail(const Color(0xFFB91C1C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalReferences() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Referensi Operasional (ML/KL)",
            style: NyutjiTheme.h3(NyutjiTheme.darkText),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildRefCard("SOP Kendala KL", LucideIcons.truck, Colors.blue),
              _buildRefCard("Panduan ML", LucideIcons.store, NyutjiTheme.mlPrimary),
              _buildRefCard("Kontak Darurat", LucideIcons.phoneCall, Colors.orange),
              _buildRefCard("Log Bantuan", LucideIcons.clipboardList, Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefCard(String title, IconData icon, Color color) {
    return Container(
      decoration: NyutjiTheme.cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: NyutjiTheme.body(NyutjiTheme.darkText).copyWith(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
