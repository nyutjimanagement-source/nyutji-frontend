import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_service.dart';
import '../../../core/widgets/nyutji_notif.dart';

const Color primaryColor = Color(0xFF00B4D8);

class AiCameraScreen extends ConsumerStatefulWidget {
  const AiCameraScreen({super.key});

  @override
  ConsumerState<AiCameraScreen> createState() => _AiCameraScreenState();
}

class _AiCameraScreenState extends ConsumerState<AiCameraScreen> {
  File? _imageFile;
  bool _isProcessing = false;
  Map<String, dynamic>? _aiResult;

  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // Kompresi agar ringan
    );

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
        _aiResult = null; // Reset hasil sebelumnya
      });
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final dio = ref.read(apiServiceProvider);
      
      // Bungkus file menggunakan MultipartFile
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_imageFile!.path, filename: 'laundry_scan.jpg'),
      });

      // Menggunakan Base URL FastAPI yang sementara kita mock di localhost port 8001
      // Idealnya ini ditaruh di api_constants, tapi karena tahap awal kita hardcode sementara
      const String aiEndpoint = "http://10.0.2.2:8001/api/ai/detect";

      final response = await dio.post(
        aiEndpoint, 
        data: formData,
        options: Options(
          extra: {
            'is_multipart': true,
            'file_path': _imageFile!.path,
            'file_field': 'file'
          }
        ),
      );

      if (!mounted) return;

      // Check jika request masuk offline queue (intercepted)
      if (response.data is Map && response.data['queued'] == true) {
        NyutjiNotif.showSuccess(context, "Anda Offline. Foto diantrekan untuk diproses nanti.");
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        setState(() {
          _aiResult = response.data['data'];
        });
        NyutjiNotif.showSuccess(context, "Analisis AI Selesai!");
      } else {
        NyutjiNotif.showError(context, "Gagal menganalisis gambar.");
      }

    } catch (e) {
      NyutjiNotif.showError(context, "Terjadi kesalahan jaringan: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Kamera AI (YOLOv8)",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_imageFile != null)
                        Image.file(_imageFile!, fit: BoxFit.cover)
                      else
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.scan, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              "Arahkan kamera ke\ntumpukan cucian pelanggan",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      
                      // Overlay Processing
                      if (_isProcessing)
                        Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 0.95),
                            duration: const Duration(seconds: 4),
                            builder: (context, value, _) {
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 40),
                                    child: LinearProgressIndicator(
                                      value: value,
                                      color: primaryColor,
                                      backgroundColor: Colors.white30,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "AI Sedang Menganalisis... ${(value * 100).toInt()}%",
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Result Card
            if (_aiResult != null && !_isProcessing)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultItem("Total Item", "${_aiResult!['total_items']} Pcs"),
                    Container(height: 40, width: 1, color: Colors.white30),
                    _buildResultItem("Estimasi Berat", "${_aiResult!['estimated_weight_kg']} Kg"),
                  ],
                ),
              ),

            // Capture Button
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _takePhoto,
                  icon: const Icon(LucideIcons.camera, color: Colors.white),
                  label: Text(
                    _imageFile == null ? "Ambil Foto Nyutjian" : "Pindai Ulang",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
