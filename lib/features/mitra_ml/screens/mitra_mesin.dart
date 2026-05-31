import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/lg_washer_service.dart';
import '../../../models/lg_washer_model.dart';
import 'dart:async';

class MitraMesinScreen extends StatefulWidget {
  const MitraMesinScreen({super.key});

  @override
  State<MitraMesinScreen> createState() => _MitraMesinScreenState();
}

class _MitraMesinScreenState extends State<MitraMesinScreen> {
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
    
    // Poll status every 10 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && _devices.isNotEmpty) {
        _fetchAllStatuses();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDevices() async {
    try {
      final auth = context.read<AuthProvider>();
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryTeal,
        onPressed: _showAddMachineBottomSheet,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          "Tambah Mesin",
          style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showAddMachineBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const AddMachineBottomSheet();
      },
    ).then((_) {
      setState(() => _isLoading = true);
      _fetchDevices();
    });
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

class AddMachineBottomSheet extends StatefulWidget {
  const AddMachineBottomSheet({super.key});

  @override
  State<AddMachineBottomSheet> createState() => _AddMachineBottomSheetState();
}

class _AddMachineBottomSheetState extends State<AddMachineBottomSheet> {
  final LgWasherService _lgWasherService = LgWasherService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _availableDevices = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableDevices();
  }

  Future<void> _fetchAvailableDevices() async {
    try {
      final devices = await _lgWasherService.getAvailableDevices();
      if (mounted) {
        setState(() {
          _availableDevices = devices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching available devices: $e");
    }
  }

  Future<void> _claimDevice(Map<String, dynamic> device) async {
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.user?['identifier'] ?? '';
      
      final success = await _lgWasherService.registerDevice(
        userId, 
        device['deviceId'], 
        device['alias'] ?? 'Mesin LG', 
        device['modelName'] ?? 'Unknown'
      );

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error claiming device: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pilih Mesin",
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF1E5655)))
          else if (_availableDevices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  "Tidak ada mesin LG yang tersedia.",
                  style: GoogleFonts.montserrat(color: const Color(0xFF6B7280)),
                ),
              ),
            )
          else
            ..._availableDevices.map((device) => _buildAvailableCard(device)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAvailableCard(Map<String, dynamic> device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E5655),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.waves, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device['alias'] ?? 'LG Washer',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                Text(
                  "Model: ${device['modelName'] ?? 'N/A'}",
                  style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5655),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => _claimDevice(device),
            child: Text("Klaim", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
          )
        ],
      ),
    );
  }
}
