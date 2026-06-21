import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/widgets/nyutji_notif.dart';

class AdminQRCodeGenerateSheet extends StatefulWidget {
  final Function(String)? onScanSuccess;

  const AdminQRCodeGenerateSheet({super.key, this.onScanSuccess});

  @override
  State<AdminQRCodeGenerateSheet> createState() => _AdminQRCodeGenerateSheetState();
}

class _AdminQRCodeGenerateSheetState extends State<AdminQRCodeGenerateSheet> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  double _progress = 0.0;
  String? _scannedData;

  static const Color primaryTeal = Color(0xFF1E5655);
  static const Color darkGray = Color(0xFF111827);
  static const Color lightGray = Color(0xFFF3F4F6);

  // Menggunakan Google ML Kit Barcode Scanner untuk ketahanan tinggi (Blur, Low-light, dll)
  final BarcodeScanner _barcodeScanner = BarcodeScanner(
    formats: [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _barcodeScanner.close();
    super.dispose();
  }

  // Simulasi progress bar demi UX yang smooth saat pemrosesan gambar
  void _simulateProgress(VoidCallback onComplete) async {
    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _scannedData = null;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 70));
      if (!mounted) return;
      setState(() {
        _progress = i * 0.1;
      });
    }

    onComplete();
  }

  // Fungsi utama mengambil & memproses gambar
  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100, // Mempertahankan kualitas maksimal agar AI bekerja optimal
      );

      if (pickedFile == null) return;

      _simulateProgress(() async {
        try {
          final inputImage = InputImage.fromFilePath(pickedFile.path);
          final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

          if (!mounted) return;

          setState(() {
            _isProcessing = false;
          });

          if (barcodes.isNotEmpty) {
            final String? rawValue = barcodes.first.rawValue;
            if (rawValue != null && rawValue.isNotEmpty) {
              setState(() {
                _scannedData = rawValue;
              });
              NyutjiNotif.showSuccess(context, "QR Code berhasil dibaca!");
              if (widget.onScanSuccess != null) {
                widget.onScanSuccess!(rawValue);
              }
            } else {
              NyutjiNotif.showError(context, "Gagal membaca data dari QR Code.");
            }
          } else {
            NyutjiNotif.showError(context, "QR Code tidak terdeteksi. Pastikan gambar memuat QR dengan jelas.");
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            NyutjiNotif.showError(context, "Gagal memproses gambar: $e");
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        NyutjiNotif.showError(context, "Terjadi kesalahan sistem: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Bottom Padding untuk notch layar / area aman handphone
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: bottomPadding + 24,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag Handle BottomSheet
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            // Header Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.qrCode, color: Colors.orange, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "QR Code Generator",
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: darkGray,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Pindai & Regenerasi QR Code secara instan",
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 16),

            // Input Buttons (Camera/Gallery)
            if (!_isProcessing && _scannedData == null) ...[
              Text(
                "Pilih Sumber Gambar QR Code:",
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: LucideIcons.camera,
                      label: "Kamera",
                      onTap: () => _processImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: LucideIcons.image,
                      label: "Galeri",
                      onTap: () => _processImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],

            // Progress Processing Bar
            if (_isProcessing) ...[
              const SizedBox(height: 12),
              Text(
                "Memproses Gambar... ${(_progress * 100).toInt()}%",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: darkGray,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryTeal),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Regenerated QR View
            if (_scannedData != null && !_isProcessing) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      "QR Code Berhasil Diregenerasi",
                      style: GoogleFonts.montserrat(
                        color: primaryTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Canvas Container QR
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: QrImageView(
                        data: _scannedData!,
                        version: QrVersions.auto,
                        size: 200.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: darkGray,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: darkGray,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scanned Text Detail
                    Text(
                      "Data Hasil Pindai:",
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      _scannedData!,
                      style: GoogleFonts.montserrat(
                        color: darkGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Button for Scan Another Image
              TextButton(
                onPressed: () => setState(() => _scannedData = null),
                child: Text(
                  "Scan Gambar Lain",
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: primaryTeal),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
