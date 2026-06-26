import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/lg_washer_service.dart';
import '../../../models/lg_washer_model.dart';
import 'dart:async';

class MitraMesinScreen extends ConsumerStatefulWidget {
  const MitraMesinScreen({super.key});

  @override ConsumerState<MitraMesinScreen> createState() => _MitraMesinScreenState();
}

class _MitraMesinScreenState extends ConsumerState<MitraMesinScreen> {
  static const primaryTeal = Color(0xFF1E5655);
  static const bgColor = Color(0xFFF3F4F6);
  static const darkText = Color(0xFF111827);
  static const textGrey = Color(0xFF6B7280);

  final LgWasherService _lgWasherService = LgWasherService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _devices = [];
  final Map<String, LgWasherModel> _deviceStatuses = {};
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    
    // Auto-reload dihapus sesuai Aturan Pelarangan Polling Agresif (Rule 4)
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDevices() async {
    try {
      final auth = ref.read(authProvider);
      final userId = auth.user?['identifier'] ?? '';
      
      if (userId.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final devices = await _lgWasherService.getDevicesByUser(userId);
      if (mounted) {
        setState(() {
          _devices = devices;
          _isLoading = false;
        });
        _fetchAllStatuses();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching LG devices: $e");
    }
  }

  Future<void> _fetchAllStatuses() async {
    for (var device in _devices) {
      final deviceId = device['device_id'];
      try {
        final status = await _lgWasherService.getWasherStatus(deviceId);
        if (mounted) {
          setState(() {
            _deviceStatuses[deviceId] = status;
          });
        }
      } catch (e) {
        debugPrint("Error fetching status for $deviceId: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Dashboard Mesin",
          style: GoogleFonts.montserrat(
            color: darkText,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryTeal))
        : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.serverCrash, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Belum ada mesin yang terdaftar",
              style: GoogleFonts.montserrat(
                color: textGrey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryTeal,
      onRefresh: () async {
        await _fetchDevices();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          final deviceId = device['device_id'];
          final status = _deviceStatuses[deviceId];

          return _buildMachineCard(device, status);
        },
      ),
    );
  }

  Widget _buildMachineCard(Map<String, dynamic> device, LgWasherModel? status) {
    final bool isOn = status?.isOn ?? false;
    final String statusText = status?.status ?? 'UNKNOWN';
    final String remainTime = status?.remainTime ?? '-';
    final String maintenance = status?.maintenance ?? 'Loading...';
    final Color stateColor = isOn ? Colors.blueAccent : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isOn ? primaryTeal.withValues(alpha: 0.05) : Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOn ? primaryTeal : Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.waves, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device['name_machine'] ?? 'LG Washer',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                        ),
                      ),
                      Text(
                        "Model: ${device['model'] ?? 'N/A'}",
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOn ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: isOn ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOn ? "ON" : "OFF",
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isOn ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Body Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusItem(LucideIcons.activity, "Status", statusText, stateColor),
                    _buildStatusItem(LucideIcons.clock, "Sisa Waktu", remainTime, isOn ? Colors.orange : Colors.grey),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 16, color: primaryTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Maintenance: $maintenance",
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: textGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
