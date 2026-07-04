import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/lg_washer_service.dart';
import '../../../models/lg_washer_model.dart';
import '../../../core/widgets/nyutji_notif.dart';
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

  int _activeTab = 0; // 0: Daftar Mesin, 1: Panduan IoT & API

  @override
  void initState() {
    super.initState();
    _fetchDevices();
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

  void _showRegisterDeviceSheet(BuildContext context) async {
    final auth = ref.read(authProvider);
    final userId = auth.user?['identifier'] ?? '';
    if (userId.isEmpty) return;

    final TextEditingController idController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController modelController = TextEditingController();

    bool isSubmitting = false;
    List<Map<String, dynamic>> availableDevs = [];
    bool isFetchingAvail = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isFetchingAvail) {
              isFetchingAvail = false;
              _lgWasherService.getAvailableDevices().then((devs) {
                setModalState(() {
                  availableDevs = devs;
                });
              }).catchError((e) {
                debugPrint("Error fetching available devices: $e");
              });
            }

            return Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).padding.bottom + 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 24),
                    Text(
                      "Daftarkan Mesin Baru",
                      style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: darkText),
                    ),
                    const SizedBox(height: 16),
                    
                    if (availableDevs.isNotEmpty) ...[
                      Text(
                        "Perangkat Terdeteksi di Jaringan:",
                        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: textGrey),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 54,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: availableDevs.length,
                          itemBuilder: (context, index) {
                            final dev = availableDevs[index];
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  idController.text = dev['deviceId'] ?? '';
                                  nameController.text = dev['alias'] ?? '';
                                  modelController.text = dev['modelName'] ?? '';
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryTeal.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: primaryTeal.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(dev['alias'] ?? 'LG Device', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal)),
                                    Text(dev['deviceId']?.toString().substring(0, 10) ?? '', style: GoogleFonts.montserrat(fontSize: 9, color: textGrey)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      "Detail Perangkat:",
                      style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold, color: textGrey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: idController,
                      style: GoogleFonts.montserrat(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Device ID / MAC Address / Chip ID",
                        labelStyle: GoogleFonts.montserrat(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.montserrat(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Nama Mesin",
                        labelStyle: GoogleFonts.montserrat(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: modelController,
                      style: GoogleFonts.montserrat(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Model / Tipe",
                        labelStyle: GoogleFonts.montserrat(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: isSubmitting ? null : () async {
                          final id = idController.text.trim();
                          final name = nameController.text.trim();
                          final modelVal = modelController.text.trim();

                          if (id.isEmpty || name.isEmpty) {
                            NyutjiNotif.showError(this.context, "Device ID dan Nama Mesin wajib diisi");
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          try {
                            final success = await _lgWasherService.registerDevice(userId, id, name, modelVal);
                            if (success) {
                              if (mounted) {
                                NyutjiNotif.showSuccess(this.context, "Mesin berhasil didaftarkan");
                              }
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              if (mounted) {
                                _fetchDevices();
                              }
                            } else {
                              if (mounted) NyutjiNotif.showError(this.context, "Gagal mendaftarkan mesin");
                            }
                          } catch (e) {
                            if (mounted) NyutjiNotif.showError(this.context, e.toString().replaceAll("Exception:", ""));
                          } finally {
                            if (mounted) setModalState(() => isSubmitting = false);
                          }
                        },
                        child: isSubmitting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text("Daftarkan", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
      body: Column(
        children: [
          _buildCustomTabBar(),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: primaryTeal))
                : _activeTab == 0 
                    ? _buildContent()
                    : _buildIoTGuideContent(),
          ),
        ],
      ),
      floatingActionButton: _activeTab == 0 && !_isLoading
          ? FloatingActionButton(
              backgroundColor: primaryTeal,
              onPressed: () => _showRegisterDeviceSheet(context),
              child: const Icon(LucideIcons.plus, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = 0),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: Text(
                      "Daftar Mesin",
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.w600,
                        color: _activeTab == 0 ? primaryTeal : textGrey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = 1),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: Text(
                      "Panduan IoT & API",
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.w600,
                        color: _activeTab == 1 ? primaryTeal : textGrey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 3,
            child: Stack(
              children: [
                Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 1, color: Colors.grey[200])),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: _activeTab == 0 
                      ? (MediaQuery.of(context).size.width / 4) - 30 
                      : (3 * MediaQuery.of(context).size.width / 4) - 30,
                  child: Container(
                    height: 3.0,
                    width: 60.0,
                    decoration: BoxDecoration(
                      color: primaryTeal,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(3.0),
                        bottomRight: Radius.circular(3.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryTeal.withValues(alpha: 0.5),
                          blurRadius: 4.0,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final List<Map<String, dynamic>> displayDevices = _devices.isEmpty 
        ? [
            {
              'device_id': 'ESP32_WASHER_001',
              'name_machine': 'Mesin Cuci Depan #1 (Dummy)',
              'model': 'F2515RTGV (Front Load)',
            },
            {
              'device_id': 'ESP32_DRYER_001',
              'name_machine': 'Mesin Pengering Gas #1 (Dummy)',
              'model': 'LG Giant C Max (Dryer)',
            },
            {
              'device_id': 'ESP32_WASHER_002',
              'name_machine': 'Mesin Cuci Top Load #2 (Dummy)',
              'model': 'T2109VSAB (Top Load)',
            },
          ]
        : _devices;

    return RefreshIndicator(
      color: primaryTeal,
      onRefresh: () async {
        await _fetchDevices();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: displayDevices.length,
        itemBuilder: (context, index) {
          final device = displayDevices[index];
          final deviceId = device['device_id'];
          
          LgWasherModel? status = _deviceStatuses[deviceId];
          if (status == null && _devices.isEmpty) {
            if (deviceId == 'ESP32_WASHER_001') {
              status = LgWasherModel(
                deviceId: deviceId,
                name: device['name_machine'],
                model: device['model'],
                isOn: true,
                status: 'MENCUCI',
                remainTime: '0h 32m',
                maintenance: 'Kondisi Mesin Prima',
              );
            } else if (deviceId == 'ESP32_DRYER_001') {
              status = LgWasherModel(
                deviceId: deviceId,
                name: device['name_machine'],
                model: device['model'],
                isOn: true,
                status: 'MENGERINGKAN',
                remainTime: '0h 15m',
                maintenance: 'Siklus pembersihan filter udara disarankan',
              );
            } else {
              status = LgWasherModel(
                deviceId: deviceId,
                name: device['name_machine'],
                model: device['model'],
                isOn: false,
                status: 'STANDBY',
                remainTime: '-',
                maintenance: 'Kondisi Mesin Prima',
              );
            }
          }

          return _buildMachineCard(device, status);
        },
      ),
    );
  }

  Widget _buildMachineCard(Map<String, dynamic> device, LgWasherModel? status) {
    final bool isOn = status?.isOn ?? false;
    final String statusText = status?.status ?? 'STANDBY';
    final String remainTime = status?.remainTime ?? '-';
    final String maintenance = status?.maintenance ?? 'Kondisi Mesin Prima';
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
                        "MAC / Device ID: ${device['device_id'] ?? 'N/A'}",
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                fontSize: 13,
                color: darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIoTGuideContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildGuideHeaderCard(),
        const SizedBox(height: 16),
        _buildMQTTDocsCard(),
        const SizedBox(height: 16),
        _buildArduinoCodeCard(),
      ],
    );
  }

  Widget _buildGuideHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryTeal, Color(0xFF2E7B79)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.cpu, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                "Arsitektur IoT Nyutji",
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Hubungkan mesin laundry konvensional ke platform Nyutji menggunakan modul ESP32/ESP8266. Pemicuan dilakukan melalui sinyal Relay digital pada sirkuit tombol start.",
            style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white.withValues(alpha: 0.9), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMQTTDocsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Spesifikasi MQTT & REST API", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
          const Divider(height: 24),
          _buildDocRow("Broker Server", "mqtt://broker.nyutji.com (Port 1883)"),
          _buildDocRow("Topic Perintah", "laundry/machine/{deviceId}/control"),
          _buildDocRow("Payload Perintah", '{\n  "action": "START",\n  "pulseDurationMs": 500\n}'),
          _buildDocRow("Topic Status", "laundry/machine/{deviceId}/status"),
          _buildDocRow("REST Register", "POST /api/lg/washer/register"),
        ],
      ),
    );
  }

  Widget _buildDocRow(String label, String value) {
    final bool isJson = value.startsWith('{');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: textGrey)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isJson ? const Color(0xFF1E1E1E) : bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: isJson ? const Color(0xFF9CDCFE) : darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArduinoCodeCard() {
    const String arduinoCode = """#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

const char* ssid = "WIFI_AP_MITRA";
const char* password = "WIFI_PASSWORD";
const char* mqtt_server = "broker.nyutji.com";
const char* device_id = "ESP32_WASHER_001";

const int RELAY_PIN = 5; // Terhubung ke optocoupler / relay button

WiFiClient espClient;
PubSubClient client(espClient);

void setup() {
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  WiFi.begin(ssid, password);
  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
}

void callback(char* topic, byte* payload, unsigned int length) {
  StaticJsonDocument<200> doc;
  deserializeJson(doc, payload, length);
  
  const char* action = doc["action"];
  int pulse = doc["pulseDurationMs"];
  
  if (strcmp(action, "START") == 0) {
    digitalWrite(RELAY_PIN, HIGH);
    delay(pulse > 0 ? pulse : 500);
    digitalWrite(RELAY_PIN, LOW);
    publishStatus("RUNNING");
  }
}

void publishStatus(const char* status) {
  StaticJsonDocument<128> doc;
  doc["deviceId"] = device_id;
  doc["isOn"] = true;
  doc["status"] = status;
  
  char buffer[128];
  serializeJson(doc, buffer);
  client.publish("laundry/machine/ESP32_WASHER_001/status", buffer);
}

void loop() {
  if (!client.connected()) reconnect();
  client.loop();
}""";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Kode C++ ESP32 (Arduino)", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: darkText)),
              const Icon(LucideIcons.copy, size: 16, color: primaryTeal),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              child: Text(
                arduinoCode,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Color(0xFFD4D4D4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

